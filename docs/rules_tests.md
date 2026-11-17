<!-- Owner: B - Person B (Database Design, Security Rules, Household, Activity Feed) -->
<!-- Description: Security rules test cases and execution log (Task B14) -->

# Cloud Firestore Security Rules Test Suite (`B14`)

This document records **18 security rules verification cases** (Allowed & Denied) executed against `firestore.rules` using the **Firebase Local Emulator Suite** (`@firebase/rules-unit-testing`) and **Firebase Rules Playground**.

---

## Test Fixture Summary

| Entity | Path | Seeded Data |
| :--- | :--- | :--- |
| **Admin User** | `/users/amara` | `{ fullName: "Amara Okoye", email: "amara@alu.edu", phone: "0780000001", householdId: "house-1" }` |
| **Member User** | `/users/kevin` | `{ fullName: "Kevin Mugisha", email: "kevin@alu.edu", phone: "0780000002", householdId: "house-1" }` |
| **Third Member** | `/users/grace` | `{ fullName: "Grace Uwimana", email: "grace@alu.edu", phone: "0780000003", householdId: "house-1" }` |
| **Stranger / Removed** | `/users/stranger` | `{ fullName: "Removed User", email: "stranger@alu.edu", phone: "0780000009", householdId: "house-1" }` *(no `/members/stranger` doc)* |
| **Household** | `/households/house-1` | `{ name: "Kigali Nest", type: "apartment", expectedMembers: 4, pin: "482916", adminUid: "amara" }` |
| **Admin Member Doc** | `/households/house-1/members/amara` | `{ role: "admin", credits: 40, joinedAt: Timestamp }` |
| **Regular Member Doc** | `/households/house-1/members/kevin` | `{ role: "member", credits: 20, joinedAt: Timestamp }` |
| **Household PIN** | `/householdPins/482916` | `{ householdId: "house-1", createdAt: Timestamp }` |

---

## Summary Table of 18 Test Cases

| # | Collection | Operation | Caller (`auth.uid`) | Scenario | Expected | Actual |
| :-: | :--- | :--- | :--- | :--- | :---: | :---: |
| **1** | `households` | `get` | `stranger` | Stranger reading a household without membership or active PIN lookup | **DENIED** | PASS (Denied) |
| **2** | `households` | `get` | `kevin` | Verified household member reading their household document | **ALLOWED** | PASS (Allowed) |
| **3** | `households` | `update` | `kevin` | Non-admin attempting to self-promote `adminUid` on an existing household | **DENIED** | PASS (Denied) |
| **4** | `users` | `get` | `stranger` | Removed user spoofing `users/stranger.householdId = "house-1"` to read a housemate profile | **DENIED** | PASS (Denied) |
| **5** | `users` | `get` | `kevin` | Verified housemate reading another member's `/users/amara` profile | **ALLOWED** | PASS (Allowed) |
| **6** | `householdPins` | `list` | `kevin` | Signed-in user attempting to list/enumerate `/householdPins` | **DENIED** | PASS (Denied) |
| **7** | `householdPins` | `get` | `stranger` | Signed-in user reading a single `/householdPins/482916` document by PIN | **ALLOWED** | PASS (Allowed) |
| **8** | `members` | `create` | `newJoiner` | Joining member attempting to create their member doc with `credits: 100` (non-zero starting credits) | **DENIED** | PASS (Denied) |
| **9** | `members` | `update` | `kevin` | Regular member attempting to edit another member's `role` to `"admin"` | **DENIED** | PASS (Denied) |
| **10** | `members` | `update` | `amara` | Household admin updating a member's `role` during admin transfer | **ALLOWED** | PASS (Allowed) |
| **11** | `members` | `update` | `kevin` | Member updating only the `credits` field with a non-negative value (`credits: 30`) | **ALLOWED** | PASS (Allowed) |
| **12** | `members` | `update` | `kevin` | Member attempting to update `credits` to a negative value (`credits: -10`) | **DENIED** | PASS (Denied) |
| **13** | `expenses` | `create` | `kevin` | Member creating an expense where `paidByUid` matches `request.auth.uid` and `totalAmount > 0` | **ALLOWED** | PASS (Allowed) |
| **14** | `expenses` | `update` | `kevin` | Non-creator attempting to edit an expense paid by `amara` | **DENIED** | PASS (Denied) |
| **15** | `debts` | `update` | `kevin` | Debtor settling a debt by updating `status`, `settlementMethod`, and `settledAt` | **ALLOWED** | PASS (Allowed) |
| **16** | `swapRequests` | `read` | `grace` | Uninvolved household member (`grace`) reading a swap request between `amara` and `kevin` | **DENIED** | PASS (Denied) |
| **17** | `activities` | `delete` | `amara` | Admin attempting to delete or mutate an immutable activity feed entry | **DENIED** | PASS (Denied) |
| **18** | `notifications` | `get` | `amara` | Non-recipient (`amara`) attempting to read a notification addressed to `kevin` | **DENIED** | PASS (Denied) |

---

## Detailed Test Cases & Evidence

### Case 1: Stranger reading a household is DENIED
- **Operation:** `get` on `/households/house-private` (where no public PIN lookup matches)
- **Caller Auth:** `uid = "stranger"`
- **Rule Checked:** `allow get: if isMember(hid) || ...`
- **Result:** `DENIED`

### Case 2: Household member reading their household is ALLOWED
- **Operation:** `get` on `/households/house-1`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `isMember("house-1")` (`exists(/households/house-1/members/kevin)`)
- **Result:** `ALLOWED`

### Case 3: Non-admin self-promoting `adminUid` on existing household is DENIED
- **Operation:** `update` on `/households/house-1` with `{ "adminUid": "kevin" }`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `isAdmin("house-1")` evaluates pre-write state (`get(householdDocPath(hid)).data.adminUid == request.auth.uid`); `getAfter` is restricted to `isCreatingHouseholdAsAdmin`.
- **Result:** `DENIED`

### Case 4: Removed member spoofing `users/{uid}.householdId` to read housemate profile is DENIED
- **Operation:** `get` on `/users/amara`
- **Caller Auth:** `uid = "stranger"` (has `users/stranger.householdId == "house-1"`, but no `/households/house-1/members/stranger` doc)
- **Rule Checked:** `isHousemate(resource.data)` requires `exists(/households/house-1/members/stranger)`.
- **Result:** `DENIED`

### Case 5: Verified housemate reading another member's profile is ALLOWED
- **Operation:** `get` on `/users/amara`
- **Caller Auth:** `uid = "kevin"` (verified member in `/households/house-1/members/kevin`)
- **Rule Checked:** `isHousemate(resource.data)`
- **Result:** `ALLOWED`

### Case 6: Listing `householdPins` collection is DENIED
- **Operation:** `list` on `/householdPins`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `allow list: if false;` on `/householdPins/{pin}`
- **Result:** `DENIED`

### Case 7: Getting a single `householdPins/{pin}` document by PIN is ALLOWED
- **Operation:** `get` on `/householdPins/482916`
- **Caller Auth:** `uid = "stranger"`
- **Rule Checked:** `allow get: if isSignedIn();` on `/householdPins/{pin}`
- **Result:** `ALLOWED`

### Case 8: Creating a member document with non-zero starting credits is DENIED
- **Operation:** `create` on `/households/house-1/members/newJoiner` with `{ role: "member", credits: 100, joinedAt: Timestamp }`
- **Caller Auth:** `uid = "newJoiner"`
- **Rule Checked:** `request.resource.data.credits == 0`
- **Result:** `DENIED`

### Case 9: Member editing another member's `role` is DENIED
- **Operation:** `update` on `/households/house-1/members/grace` with `{ "role": "admin" }`
- **Caller Auth:** `uid = "kevin"` (regular member)
- **Rule Checked:** `isAdmin("house-1")` required to modify `role`
- **Result:** `DENIED`

### Case 10: Admin updating a member's `role` is ALLOWED
- **Operation:** `update` on `/households/house-1/members/kevin` with `{ "role": "admin" }`
- **Caller Auth:** `uid = "amara"` (admin)
- **Rule Checked:** `isAdmin("house-1") && affectedKeys().hasOnly(['role'])`
- **Result:** `ALLOWED`

### Case 11: Member changing only `credits` (non-negative) is ALLOWED
- **Operation:** `update` on `/households/house-1/members/kevin` with `{ "credits": 30 }`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `isMember("house-1") && affectedKeys().hasOnly(['credits']) && request.resource.data.credits >= 0`
- **Result:** `ALLOWED`

### Case 12: Member setting `credits` below zero is DENIED
- **Operation:** `update` on `/households/house-1/members/kevin` with `{ "credits": -10 }`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `request.resource.data.credits >= 0`
- **Result:** `DENIED`

### Case 13: Member creating a valid expense where `paidByUid == auth.uid` is ALLOWED
- **Operation:** `create` on `/households/house-1/expenses/exp-1` with `{ title: "Groceries", totalAmount: 24000, paidByUid: "kevin", splitType: "equal", category: "food" }`
- **Caller Auth:** `uid = "kevin"`
- **Rule Checked:** `isMember("house-1") && request.resource.data.paidByUid == request.auth.uid && request.resource.data.totalAmount >= 0`
- **Result:** `ALLOWED`

### Case 14: Non-creator updating someone else's expense is DENIED
- **Operation:** `update` on `/households/house-1/expenses/exp-amara` with `{ "title": "Edited by Kevin" }`
- **Caller Auth:** `uid = "kevin"` (where `resource.data.paidByUid == "amara"`)
- **Rule Checked:** `resource.data.paidByUid == request.auth.uid`
- **Result:** `DENIED`

### Case 15: Debtor updating debt status to `settled` is ALLOWED
- **Operation:** `update` on `/households/house-1/debts/debt-1` with `{ status: "settled", settlementMethod: "momo", settledAt: Timestamp }`
- **Caller Auth:** `uid = "kevin"` (`resource.data.debtorUid == "kevin"`)
- **Rule Checked:** `(resource.data.debtorUid == request.auth.uid || resource.data.creditorUid == request.auth.uid) && affectedKeys().hasOnly(['status', 'settlementMethod', 'settledAt'])`
- **Result:** `ALLOWED`

### Case 16: Uninvolved member reading a swap request between two other members is DENIED
- **Operation:** `get` on `/households/house-1/swapRequests/swap-1` (where `fromUid == "amara"` and `toUid == "kevin"`)
- **Caller Auth:** `uid = "grace"`
- **Rule Checked:** `resource.data.fromUid == request.auth.uid || resource.data.toUid == request.auth.uid`
- **Result:** `DENIED`

### Case 17: Deleting an activity document is DENIED (immutable audit log)
- **Operation:** `delete` on `/households/house-1/activities/act-1`
- **Caller Auth:** `uid = "amara"` (admin)
- **Rule Checked:** `allow update, delete: if false;` on `/activities/{id}`
- **Result:** `DENIED`

### Case 18: Non-recipient reading a notification is DENIED
- **Operation:** `get` on `/households/house-1/notifications/notif-1` (where `recipientUid == "kevin"`)
- **Caller Auth:** `uid = "amara"`
- **Rule Checked:** `isMember(hid) && resource.data.recipientUid == request.auth.uid`
- **Result:** `DENIED`

### Screenshots

![Case 1 Screenshot](evidence/rules_case_1.png)
![Case 1 Screenshot](evidence/rules_case_3.png)
![Case 1 Screenshot](evidence/rules_case_3.png)
