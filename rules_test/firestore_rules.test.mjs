import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'changa-rules-b14',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();

    await adminDb.doc('users/amara').set({
      fullName: 'Amara Okoye',
      email: 'amara@alu.edu',
      phone: '0780000001',
      householdId: 'house-1',
    });
    await adminDb.doc('users/kevin').set({
      fullName: 'Kevin Mugisha',
      email: 'kevin@alu.edu',
      phone: '0780000002',
      householdId: 'house-1',
    });
    await adminDb.doc('users/grace').set({
      fullName: 'Grace Uwimana',
      email: 'grace@alu.edu',
      phone: '0780000003',
      householdId: 'house-1',
    });
    await adminDb.doc('users/stranger').set({
      fullName: 'Removed User',
      email: 'stranger@alu.edu',
      phone: '0780000009',
      householdId: 'house-1',
    });

    await adminDb.doc('households/house-1').set({
      name: 'Kigali Nest',
      type: 'apartment',
      expectedMembers: 4,
      pin: '482916',
      adminUid: 'amara',
      createdAt: new Date(),
    });
    await adminDb.doc('households/house-private').set({
      name: 'Private House',
      type: 'house',
      expectedMembers: 3,
      pin: '999999',
      adminUid: 'otherAdmin',
      createdAt: new Date(),
    });

    await adminDb.doc('householdPins/482916').set({
      householdId: 'house-1',
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/members/amara').set({
      role: 'admin',
      credits: 40,
      joinedAt: new Date(),
    });
    await adminDb.doc('households/house-1/members/kevin').set({
      role: 'member',
      credits: 20,
      joinedAt: new Date(),
    });
    await adminDb.doc('households/house-1/members/grace').set({
      role: 'member',
      credits: 10,
      joinedAt: new Date(),
    });

    await adminDb.doc('households/house-1/expenses/exp-amara').set({
      title: 'Electricity',
      totalAmount: 30000,
      paidByUid: 'amara',
      splitType: 'equal',
      category: 'utilities',
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/debts/debt-1').set({
      expenseId: 'exp-amara',
      debtorUid: 'kevin',
      creditorUid: 'amara',
      amount: 10000,
      creditsApplied: 0,
      status: 'pending',
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/chores/chore-1').set({
      title: 'Clean kitchen',
      difficulty: 'medium',
      assignedToUid: 'kevin',
      dueDate: new Date(),
      status: 'pending',
      createdByUid: 'amara',
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/swapRequests/swap-1').set({
      choreId: 'chore-1',
      fromUid: 'amara',
      toUid: 'kevin',
      status: 'pending',
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/activities/act-1').set({
      type: 'expenseAdded',
      actorUid: 'amara',
      amount: 30000,
      createdAt: new Date(),
    });

    await adminDb.doc('households/house-1/notifications/notif-1').set({
      recipientUid: 'kevin',
      actorUid: 'amara',
      type: 'nudge',
      title: 'Payment Reminder',
      body: 'Amara sent a friendly reminder',
      read: false,
      createdAt: new Date(),
    });
  });
});

test('Case 1: Stranger reading a household without PIN is DENIED', async () => {
  const db = testEnv.authenticatedContext('stranger').firestore();
  await assertFails(db.doc('households/house-private').get());
});

test('Case 2: Member reading their household is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(db.doc('households/house-1').get());
});

test('Case 3: Non-admin self-promoting adminUid on existing household is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    db.doc('households/house-1').update({ adminUid: 'kevin' }),
  );
});

test('Case 4: Removed member spoofing users/{uid}.householdId to read housemate profile is DENIED', async () => {
  const db = testEnv.authenticatedContext('stranger').firestore();
  await assertFails(db.doc('users/amara').get());
});

test('Case 5: Verified housemate reading another member profile is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(db.doc('users/amara').get());
});

test('Case 6: Listing householdPins is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(db.collection('householdPins').get());
});

test('Case 7: Getting a single householdPin by ID is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('stranger').firestore();
  await assertSucceeds(db.doc('householdPins/482916').get());
});

test('Case 8: Joining member creating member doc with non-zero credits is DENIED', async () => {
  const db = testEnv.authenticatedContext('newJoiner').firestore();
  await assertFails(
    db.doc('households/house-1/members/newJoiner').set({
      role: 'member',
      credits: 100,
      joinedAt: new Date(),
    }),
  );
});

test('Case 9: Member editing another member role is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    db.doc('households/house-1/members/grace').update({ role: 'admin' }),
  );
});

test('Case 10: Admin updating a member role is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertSucceeds(
    db.doc('households/house-1/members/kevin').update({ role: 'admin' }),
  );
});

test('Case 11: Member changing only credits (>= 0) is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    db.doc('households/house-1/members/kevin').update({ credits: 30 }),
  );
});

test('Case 12: Member setting negative credits is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    db.doc('households/house-1/members/kevin').update({ credits: -10 }),
  );
});

test('Case 13: Member creating expense with paidByUid == auth.uid is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    db.doc('households/house-1/expenses/exp-new').set({
      title: 'Groceries',
      totalAmount: 24000,
      paidByUid: 'kevin',
      splitType: 'equal',
      category: 'food',
      createdAt: new Date(),
    }),
  );
});

test('Case 14: Non-creator updating someone else expense is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    db.doc('households/house-1/expenses/exp-amara').update({
      title: 'Tampered Title',
    }),
  );
});

test('Case 15: Debtor settling a debt is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    db.doc('households/house-1/debts/debt-1').update({
      status: 'settled',
      settlementMethod: 'momo',
      settledAt: new Date(),
    }),
  );
});

test('Case 16: Uninvolved member reading swapRequest is DENIED', async () => {
  const db = testEnv.authenticatedContext('grace').firestore();
  await assertFails(
    db.doc('households/house-1/swapRequests/swap-1').get(),
  );
});

test('Case 17: Deleting an activity document is DENIED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertFails(
    db.doc('households/house-1/activities/act-1').delete(),
  );
});

test('Case 18: Non-recipient reading a notification is DENIED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertFails(
    db.doc('households/house-1/notifications/notif-1').get(),
  );
});

test('Case 19: Member creating a chore and assignee completing assigned chore is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();

  // Member creates a valid chore with createdByUid == request.auth.uid
  await assertSucceeds(
    db.doc('households/house-1/chores/chore-new').set({
      title: 'Take out trash',
      difficulty: 'easy',
      assignedToUid: 'grace',
      dueDate: new Date(),
      status: 'pending',
      createdByUid: 'kevin',
      createdAt: new Date(),
    }),
  );

  // Assignee (kevin) marks their assigned chore-1 as done with creditsAwarded
  await assertSucceeds(
    db.doc('households/house-1/chores/chore-1').update({
      status: 'done',
      completedAt: new Date(),
      creditsAwarded: 20,
    }),
  );
});

test('Case 20: Non-assignee/non-creator/non-admin updating or deleting a chore is DENIED', async () => {
  const db = testEnv.authenticatedContext('grace').firestore();

  // Grace is neither admin (amara), creator (amara), nor assignee (kevin)
  await assertFails(
    db.doc('households/house-1/chores/chore-1').update({
      status: 'done',
      completedAt: new Date(),
      creditsAwarded: 20,
    }),
  );

  await assertFails(
    db.doc('households/house-1/chores/chore-1').delete(),
  );
});

test('Case 21: Atomic household creation batch (household + pin + admin member with 0 credits) is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('newAdmin').firestore();
  const batch = db.batch();

  batch.set(db.doc('households/house-new'), {
    name: 'ALU Loft',
    type: 'apartment',
    expectedMembers: 4,
    pin: '123456',
    adminUid: 'newAdmin',
    createdAt: new Date(),
  });

  batch.set(db.doc('householdPins/123456'), {
    householdId: 'house-new',
    createdAt: new Date(),
  });

  batch.set(db.doc('households/house-new/members/newAdmin'), {
    role: 'admin',
    credits: 0,
    joinedAt: new Date(),
  });

  batch.set(
    db.doc('users/newAdmin'),
    {
      fullName: 'New Admin',
      email: 'newadmin@alu.edu',
      householdId: 'house-new',
    },
    { merge: true },
  );

  await assertSucceeds(batch.commit());
});

test('Case 22: Joining an existing household with a valid PIN and 0 starting credits is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('newJoiner').firestore();
  const batch = db.batch();

  batch.set(db.doc('households/house-1/members/newJoiner'), {
    role: 'member',
    credits: 0,
    joinedAt: new Date(),
  });

  batch.set(db.doc('households/house-1/activities/act-join'), {
    type: 'memberJoined',
    actorUid: 'newJoiner',
    createdAt: new Date(),
  });

  batch.set(
    db.doc('users/newJoiner'),
    {
      fullName: 'New Joiner',
      email: 'joiner@alu.edu',
      householdId: 'house-1',
    },
    { merge: true },
  );

  await assertSucceeds(batch.commit());
});
