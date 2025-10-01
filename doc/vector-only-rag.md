# **AWS Bedrock + Weaviate RAG Agent (Single Tool)**

Awesome—let’s make a **tool-calling agent** where the *only* tool is “Weaviate ANN search,” powered by a Bedrock model (Claude/Haiku is perfect). Below is a clean, end-to-end TypeScript setup you can drop into your project today.

---

## **What you’ll have when you’re done**

* A **single-tool agent**: the LLM can *only* call **weaviate\_search**.
* Uses **Bedrock Converse** (Claude 3.5 Haiku by default).
* Talks to your **self-hosted Weaviate** on EC2 (vector ANN; optional hybrid BM25+vector).
* Easy to extend later (e.g., add a **knowledge-graph** tool—Neptune/Neptune Analytics—without changing the agent pattern).

---

## **1) Minimal infra prerequisites (quick checklist)**

* **EC2 role** (or workstation creds) with:
  * bedrock:InvokeModel**, **bedrock:Converse**, **bedrock:ConverseStream** on the model you choose.**
* **Network**: EC2 can reach Bedrock endpoints (VPC/NAT) and your Weaviate port (**8080** by default).
* **Weaviate**: one class (e.g., **Document**) with a text field and **vectorization configured** (or vectors ingested out-of-band).
  * If you enabled modules, you can do **nearText** or **hybrid**; if you pre-embedded, use **nearVector**.

---

## **2) Install deps**

```
npm i weaviate-ts-client @aws-sdk/client-bedrock-runtime zod dotenv
```

---

## **3) Environment**

```
# .env
AWS_REGION=us-east-1
BEDROCK_MODEL_ID=anthropic.claude-3-5-haiku-20241022-v1:0   # or set to your chosen Bedrock model ID
WEAVIATE_HOST=localhost:8080                                # or <private-ip>:8080
WEAVIATE_SCHEME=http                                        # or https if you terminated TLS
WEAVIATE_API_KEY=                                           # if you enabled API key auth
WEAVIATE_CLASS=Document
WEAVIATE_TEXT_FIELD=text                                    # main content field
```

> Tip: keep the model ID in env so you can swap Sonnet/Haiku later without code changes.

---

## **4) The agent (Bedrock Converse + single tool)**

**Key idea:** define a **weaviate\_search** tool (JSON Schema), let Claude decide when to call it, then execute the call and return the results via **toolResult**. The LLM then composes the final answer.

```
// agent.ts (ESM)
import 'dotenv/config';
import weaviate, { ApiKey } from 'weaviate-ts-client';
import { BedrockRuntime } from '@aws-sdk/client-bedrock-runtime';

type Hit = {
  id: string;
  score?: number;
  fields: Record<string, unknown>;
};

const bedrock = new BedrockRuntime({ region: process.env.AWS_REGION });
const modelId = process.env.BEDROCK_MODEL_ID!;

const wv = weaviate.client({
  scheme: process.env.WEAVIATE_SCHEME as 'http'|'https',
  host: process.env.WEAVIATE_HOST!,
  apiKey: process.env.WEAVIATE_API_KEY ? new ApiKey(process.env.WEAVIATE_API_KEY) : undefined,
});

const WEAVIATE_CLASS = process.env.WEAVIATE_CLASS || 'Document';
const TEXT_FIELD    = process.env.WEAVIATE_TEXT_FIELD || 'text';

// ---- Tool schema (Converse "tools") ----
const tools = [
  {
    name: 'weaviate_search',
    description:
      'ANN search over the document corpus. Use for retrieving passages relevant to the user query. Returns top-K hits with text and metadata.',
    inputSchema: {
      json: {
        type: 'object',
        properties: {
          query: { type: 'string', description: 'Natural language query.' },
          topK: { type: 'integer', minimum: 1, maximum: 50, default: 5 },
          hybrid: {
            type: 'boolean',
            description: 'If true, use hybrid lexical+vector search; otherwise pure vector.',
            default: true,
          },
        },
        required: ['query'],
      },
    },
  },
];

// ---- Weaviate executor (the only tool the LLM can call) ----
async function weaviateSearchTool(args: { query: string; topK?: number; hybrid?: boolean }): Promise<{ hits: Hit[] }> {
  const topK = Math.min(Math.max(args.topK ?? 5, 1), 50);
  const fields = `${TEXT_FIELD} title url _additional { id score distance }`;

  // Prefer HYBRID when you have BM25 enabled; fall back to vector-only nearText
  if (args.hybrid !== false) {
    const res = await wv.graphql
      .get()
      .withClassName(WEAVIATE_CLASS)
      .withHybrid({ query: args.query, alpha: 0.5 }) // tweak alpha to balance BM25 vs vector
      .withFields(fields)
      .withLimit(topK)
      .do();

    const data = res.data.Get?.[WEAVIATE_CLASS] ?? [];
    const hits: Hit[] = data.map((n: any) => ({
      id: n._additional?.id,
      score: n._additional?.score ?? (1 - (n._additional?.distance ?? 0)),
      fields: n,
    }));
    return { hits };
  }

  // Vector-only via nearText (requires text2vec module). If you pre-embedded, swap to nearVector.
  const res = await wv.graphql
    .get()
    .withClassName(WEAVIATE_CLASS)
    .withNearText({ concepts: [args.query] })
    .withFields(fields)
    .withLimit(topK)
    .do();

  const data = res.data.Get?.[WEAVIATE_CLASS] ?? [];
  const hits: Hit[] = data.map((n: any) => ({
    id: n._additional?.id,
    score: n._additional?.score ?? (1 - (n._additional?.distance ?? 0)),
    fields: n,
  }));
  return { hits };
}

// ---- Agent loop: user -> LLM -> (tool?) -> LLM -> answer ----
type Message = {
  role: 'user' | 'assistant' | 'system';
  content: Array<
    | { text: string }
    | { toolUse: { toolUseId: string; name: string; input: any } }
    | { toolResult: { toolUseId: string; content: Array<{ json?: any; text?: string }>; status: 'success' | 'error' } }
  >;
};

export async function runAgent(userInput: string) {
  const messages: Message[] = [
    {
      role: 'system',
      content: [
        {
          text:
            'You are a focused RAG assistant. Use ONLY the provided tools. ' +
            'When you retrieve passages, cite succinctly using titles/urls if available.',
        },
      ],
    },
    { role: 'user', content: [{ text: userInput }] },
  ];

  // First turn: allow the model to decide to call weaviate_search
  let resp = await bedrock.converse({
    modelId,
    messages,
    toolConfig: { tools },
  });

  // If the model called the tool, execute it and feed results back
  const content = resp.output?.message?.content ?? [];
  const toolUse = content.find((c: any) => 'toolUse' in c) as
    | { toolUse: { toolUseId: string; name: string; input: any } }
    | undefined;

  if (toolUse && toolUse.toolUse.name === 'weaviate_search') {
    const result = await weaviateSearchTool(toolUse.toolUse.input);

    messages.push({
      role: 'assistant',
      content, // echo the model's toolUse content back into the transcript
    });
    messages.push({
      role: 'user',
      content: [
        {
          toolResult: {
            toolUseId: toolUse.toolUse.toolUseId,
            status: 'success',
            content: [{ json: result }],
          },
        },
      ],
    });

    // Final turn: model composes answer using toolResult
    resp = await bedrock.converse({
      modelId,
      messages,
    });
  }

  const final = resp.output?.message?.content?.map((c: any) => c.text).filter(Boolean).join('\n\n') ?? '';
  return final;
}

// Quick CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const q = process.argv.slice(2).join(' ') || 'What does the corpus say about hypertension monitoring?';
  runAgent(q).then((out) => {
    console.log('\n--- ANSWER ---\n');
    console.log(out);
  });
}
```

**What this does**

* Sends your prompt to Bedrock with a single tool exposed.
* If the model emits a **toolUse** for **weaviate\_search**, we run it against Weaviate (hybrid by default).
* We send a **toolResult** back; the model produces a grounded answer.

---

## **5) Optional: simple ingest schema (if you need it)**

```
// create-class.ts
import 'dotenv/config';
import weaviate, { ApiKey } from 'weaviate-ts-client';

const wv = weaviate.client({
  scheme: process.env.WEAVIATE_SCHEME as 'http'|'https',
  host: process.env.WEAVIATE_HOST!,
  apiKey: process.env.WEAVIATE_API_KEY ? new ApiKey(process.env.WEAVIATE_API_KEY) : undefined,
});

await wv.schema.classCreator().withClass({
  class: process.env.WEAVIATE_CLASS || 'Document',
  vectorizer: 'text2vec-openai' /* or your chosen module / "none" if you push vectors */,
  properties: [
    { name: 'title', dataType: ['text'] },
    { name: 'text',  dataType: ['text'] },
    { name: 'url',   dataType: ['text'] },
  ],
}).do();

console.log('Class created.');
```

> If you’re pre-embedding, set **vectorizer: "none"** and supply vectors on import; your search path should then use **nearVector** or **hybrid** (with an external BM25 index enabled).

---

## **6) IAM & security quick notes**

* **EC2 instance profile****:**
  * bedrock:Converse**, **bedrock:InvokeModel** for the specific **modelId**.**
  * Least privilege on the exact model (e.g., **anthropic.claude-3-5-haiku...**).
* **Security groups**: Open Weaviate **8080** only to your app/box (not the world). Use an ALB or private NLB if needed.
* **Secrets**: keep model IDs and Weaviate creds in **.env** or an AWS Parameter Store/Secrets Manager reference (prefer the latter in prod).

---

## **7) Next step: add a Knowledge Graph tool (when ready)**

Later, you can add a second tool—e.g., **kg\_cypher\_query** backed by **Amazon Neptune** (SPARQL/Gremlin) or **Neptune Analytics** for graph algorithms. The agent scaffolding above doesn’t change: just append another **tools[]** entry and a small executor function that runs the graph query and returns structured results.

---

**✅ You now have a ****single-tool agent** pattern working with **AWS Bedrock + Weaviate ANN search****.**

---

Do you want me to also generate a **.md file** for direct download (ready to drop into your project), or is this copy-paste format enough?
