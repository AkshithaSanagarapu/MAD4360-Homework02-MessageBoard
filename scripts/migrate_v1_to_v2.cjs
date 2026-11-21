const assert = require('node:assert/strict');
const fs = require('node:fs');
const {
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  Timestamp,
} = require('firebase/firestore');

const projectId = 'mad4360-hw02-messageboard';
const host = '127.0.0.1';
const port = 8080;

async function main() {
  if (process.env.FIRESTORE_EMULATOR_HOST !== `${host}:${port}`) {
    throw new Error(
      'Safety check failed: set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080'
    );
  }

  const env = await initializeTestEnvironment({
    projectId,
    firestore: { host, port },
  });

  try {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      const samples = [
        ['legacy-alice', 'Alice Test', 'alice', 'My first message'],
        ['legacy-bob', 'Bob Test', 'bob', 'Hello from the old schema'],
        ['legacy-third', 'Alice Test', 'alice', 'Preserve this record'],
      ];

      const before = [];
      const after = [];

      for (const [id, name, uid, text] of samples) {
        const ref = doc(db, 'messages', id);
        const existing = await getDoc(ref);

        // Only seed missing records; never overwrite existing data.
        if (!existing.exists()) {
          await setDoc(ref, {
            text,
            authorUid: uid,
            authorName: name,
            createdAt: Timestamp.fromDate(
              new Date('2026-10-01T12:00:00Z')
            ),
            legacySource: 'v1-seed',
            schemaVersion: 1,
          });
        }

        const original = (await getDoc(ref)).data();

        if (![1, 2].includes(original.schemaVersion)) {
          throw new Error(`Unexpected schema version in ${id}`);
        }

        before.push({
          id,
          ...original,
        });

        if (original.schemaVersion === 1) {
          await updateDoc(ref, {
            editedAt: null,
            schemaVersion: 2,
          });
        }

        const migrated = (await getDoc(ref)).data();

        assert.equal(migrated.schemaVersion, 2);
        assert.equal(migrated.editedAt ?? null, null);

        for (const [key, value] of Object.entries(original)) {
          if (key === 'schemaVersion') continue;

          assert.deepEqual(
            migrated[key],
            value,
            `Original field ${key} changed in ${id}`
          );
        }

        after.push({
          id,
          ...migrated,
        });
      }

      const serialize = (records) =>
        JSON.stringify(
          records,
          (_, value) =>
            value instanceof Timestamp
              ? value.toDate().toISOString()
              : value,
          2
        );

      fs.writeFileSync(
        'evidence/migration_before.json',
        serialize(before) + '\n'
      );
      fs.writeFileSync(
        'evidence/migration_after.json',
        serialize(after) + '\n'
      );

      console.log('Migration completed successfully!');
      console.log('Verified 3 documents.');
      console.log('Original fields preserved.');
      console.log('Schema version updated to v2.');
    });
  } finally {
    await env.cleanup();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
