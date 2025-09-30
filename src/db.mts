import weaviate, {
  type WeaviateClient,
  type Collection,
  vectors,
} from "weaviate-client";
import type { Collections } from "./schemas.mjs";
import { REGISTRY } from "./schemas.mjs";

export async function connect(): Promise<WeaviateClient> {
  return weaviate.connectToLocal();
}

export async function ensureCollection<K extends keyof Collections>(
  client: WeaviateClient,
  name: K
): Promise<void> {
  const exists = await client.collections.exists(name as string);
  if (exists) return;

  const cfg = REGISTRY[name];
  if (!cfg) throw new Error(`No registry entry for collection: ${String(name)}`);

  const vectorizers =
    cfg.vectorizer === "openai"
      ? vectors.text2VecOpenAI()   // requires text2vec-openai module + OPENAI_APIKEY in Weaviate
      : vectors.selfProvided();     // you will pass vectors on insert

  await client.collections.create({
    name: name as string,
    vectorizers,
  });
}

/** Typed handle getter that also ensures the collection exists */
export async function getCollection<K extends keyof Collections>(
  client: WeaviateClient,
  name: K
): Promise<Collection<Collections[K]>> {
  await ensureCollection(client, name);
  // Return a strongly-typed handle where properties are Collections[K]
  return client.collections.get<Collections[K]>(name as string);
}
