import { getCollection } from './db.mjs';
import weaviate from 'weaviate-client';

async function main() {
  const client = await weaviate.connectToLocal();
  const notes = await getCollection(client, 'Notes');

  await notes.data.insertMany([
    {
      properties: {
        title: 'BP monitoring',
        body: 'Home cuff readings 2x daily; check trends over 2 weeks.',
      },
    },
    {
      properties: {
        title: 'Wearables',
        body: 'Stream Dexcom and Apple Health metrics into FHIR Observations.',
      },
    },
    {
      properties: {
        title: 'RAG plan',
        body: 'Start with vector demo, then compare against knowledge-graph RAG.',
      },
    },
  ]);

  const res = await notes.query.nearText('RAG', { limit: 1 });

  console.log(res.objects[0].properties.title);

  await client.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
