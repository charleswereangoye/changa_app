import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
} from 'firebase/firestore';

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
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();

    await setDoc(doc(adminDb, 'users/amara'), {
      fullName: 'Amara Okoye',
      email: 'amara@alu.edu',
      phone: '0780000001',
      householdId: 'house-1',
    });
    await setDoc(doc(adminDb, 'users/kevin'), {
      fullName: 'Kevin Mugisha',
      email: 'kevin@alu.edu',
      phone: '0780000002',
      householdId: 'house-1',
    });
    await setDoc(doc(adminDb, 'users/grace'), {
      fullName: 'Grace Uwimana',
      email: 'grace@alu.edu',
      phone: '0780000003',
      householdId: 'house-1',
    });
    // Removed user spoofing householdId without a member document
    await setDoc(doc(adminDb, 'users/stranger'), {
      fullName: 'Removed User',
      email: 'stranger@alu.edu',
      phone: '0780000009',
      householdId: 'house-1',
    });

    await setDoc(doc(adminDb, 'households/house-1'), {
      name: 'Kigali Nest',
      type: 'apartment',
      expectedMembers: 4,
      pin: '482916',
      adminUid: 'amara',
      createdAt: new Date(),
    });
    await setDoc(doc(adminDb, 'households/house-private'), {
      name: 'Private House',
      type: 'house',
      expectedMembers: 3,
      pin: '999999',
      adminUid: 'otherAdmin',
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'householdPins/482916'), {
      householdId: 'house-1',
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/members/amara'), {
      role: 'admin',
      credits: 40,
      joinedAt: new Date(),
    });
    await setDoc(doc(adminDb, 'households/house-1/members/kevin'), {
      role: 'member',
      credits: 20,
      joinedAt: new Date(),
    });
    await setDoc(doc(adminDb, 'households/house-1/members/grace'), {
      role: 'member',
      credits: 10,
      joinedAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/expenses/exp-amara'), {
      title: 'Electricity',
      totalAmount: 30000,
      paidByUid: 'amara',
      splitType: 'equal',
      category: 'utilities',
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/debts/debt-1'), {
      expenseId: 'exp-amara',
      debtorUid: 'kevin',
      creditorUid: 'amara',
      amount: 10000,
      creditsApplied: 0,
      status: 'pending',
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/swapRequests/swap-1'), {
      choreId: 'chore-1',
      fromUid: 'amara',
      toUid: 'kevin',
      status: 'pending',
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/activities/act-1'), {
      type: 'expenseAdded',
      actorUid: 'amara',
      amount: 30000,
      createdAt: new Date(),
    });

    await setDoc(doc(adminDb, 'households/house-1/notifications/notif-1'), {
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
  await assertFails(getDoc(doc(db, 'households/house-private')));
});

test('Case 2: Member reading their household is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(getDoc(doc(db, 'households/house-1')));
});

test('Case 3: Non-admin self-promoting adminUid on existing household is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    updateDoc(doc(db, 'households/house-1'), { adminUid: 'kevin' }),
  );
});

test('Case 4: Removed member spoofing users/{uid}.householdId to read housemate profile is DENIED', async () => {
  const db = testEnv.authenticatedContext('stranger').firestore();
  await assertFails(getDoc(doc(db, 'users/amara')));
});

test('Case 5: Verified housemate reading another member profile is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(getDoc(doc(db, 'users/amara')));
});

test('Case 6: Listing householdPins is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(getDocs(collection(db, 'householdPins')));
});

test('Case 7: Getting a single householdPin by ID is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('stranger').firestore();
  await assertSucceeds(getDoc(doc(db, 'householdPins/482916')));
});

test('Case 8: Joining member creating member doc with non-zero credits is DENIED', async () => {
  const db = testEnv.authenticatedContext('newJoiner').firestore();
  await assertFails(
    setDoc(doc(db, 'households/house-1/members/newJoiner'), {
      role: 'member',
      credits: 100,
      joinedAt: new Date(),
    }),
  );
});

test('Case 9: Member editing another member role is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    updateDoc(doc(db, 'households/house-1/members/grace'), { role: 'admin' }),
  );
});

test('Case 10: Admin updating a member role is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'households/house-1/members/kevin'), { role: 'admin' }),
  );
});

test('Case 11: Member changing only credits (>= 0) is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'households/house-1/members/kevin'), { credits: 30 }),
  );
});

test('Case 12: Member setting negative credits is DENIED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertFails(
    updateDoc(doc(db, 'households/house-1/members/kevin'), { credits: -10 }),
  );
});

test('Case 13: Member creating expense with paidByUid == auth.uid is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    setDoc(doc(db, 'households/house-1/expenses/exp-new'), {
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
    updateDoc(doc(db, 'households/house-1/expenses/exp-amara'), {
      title: 'Tampered Title',
    }),
  );
});

test('Case 15: Debtor settling a debt is ALLOWED', async () => {
  const db = testEnv.authenticatedContext('kevin').firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'households/house-1/debts/debt-1'), {
      status: 'settled',
      settlementMethod: 'momo',
      settledAt: new Date(),
    }),
  );
});

test('Case 16: Uninvolved member reading swapRequest is DENIED', async () => {
  const db = testEnv.authenticatedContext('grace').firestore();
  await assertFails(
    getDoc(doc(db, 'households/house-1/swapRequests/swap-1')),
  );
});

test('Case 17: Deleting an activity document is DENIED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertFails(
    deleteDoc(doc(db, 'households/house-1/activities/act-1')),
  );
});

test('Case 18: Non-recipient reading a notification is DENIED', async () => {
  const db = testEnv.authenticatedContext('amara').firestore();
  await assertFails(
    getDoc(doc(db, 'households/house-1/notifications/notif-1')),
  );
});