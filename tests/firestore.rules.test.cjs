const assert = require('node:assert/strict');
const { test, before, after } = require('node:test');
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp } =
  require('firebase/firestore');
const fs = require('node:fs');

let env;
const projectId = 'mad4360-hw02-messageboard';

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync('firestore.rules', 'utf8'),
    },
  });

  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'users/alice'), {
      uid: 'alice',
      firstName: 'Alice',
      lastName: 'Test',
      role: 'Student',
      registrationDateTime: new Date(),
    });

    await setDoc(doc(db, 'users/bob'), {
      uid: 'bob',
      firstName: 'Bob',
      lastName: 'Test',
      role: 'Student',
      registrationDateTime: new Date(),
    });

    await setDoc(doc(db, 'messages/existing'), {
      text: 'Original message',
      authorUid: 'alice',
      authorName: 'Alice Test',
      createdAt: new Date(),
      editedAt: null,
      schemaVersion: 2,
    });
  });
});

after(async () => {
  if (env) await env.cleanup();
});

test('Signed-out user cannot read messages', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'messages/existing')));
});

test('Another user cannot edit Alice message', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(updateDoc(doc(db, 'messages/existing'), {
    text: 'Unauthorized edit',
    editedAt: serverTimestamp(),
  }));
});

test('Forged authorUid is rejected', async () => {
  const db = env.authenticatedContext('bob').firestore();
  await assertFails(setDoc(doc(db, 'messages/forged'), {
    text: 'Forged message',
    authorUid: 'alice',
    authorName: 'Alice Test',
    createdAt: serverTimestamp(),
    editedAt: null,
    schemaVersion: 2,
  }));
});

test('Correct author can create, read, edit, and delete', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'messages/authorized');

  await assertSucceeds(setDoc(ref, {
    text: 'Authorized message',
    authorUid: 'alice',
    authorName: 'Alice Test',
    createdAt: serverTimestamp(),
    editedAt: null,
    schemaVersion: 2,
  }));

  await assertSucceeds(getDoc(ref));

  await assertSucceeds(updateDoc(ref, {
    text: 'Edited by Alice',
    editedAt: serverTimestamp(),
  }));

  await assertSucceeds(deleteDoc(ref));
});

test('Same operation ID cannot create duplicate messages', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'messages/spice4-fixed-operation');

  const message = {
    text: 'Spice 4 duplicate protection test',
    authorUid: 'alice',
    authorName: 'Alice Test',
    createdAt: serverTimestamp(),
    editedAt: null,
    schemaVersion: 2,
  };

  await assertSucceeds(setDoc(ref, message));

  // A retry uses the same document ID.
  // Current rules reject overwriting the existing message.
  await assertFails(setDoc(ref, message));

  const result = await getDoc(ref);
  assert.equal(result.exists(), true);
  assert.equal(result.data().text, message.text);
});
