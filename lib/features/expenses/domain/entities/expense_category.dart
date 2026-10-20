// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: ExpenseCategory enum and category classification

enum ExpenseCategory {
  rent,
  utilities,
  internet,
  water,
  cashpower,
  gas,
  groceries,
  other;

  bool get isResource => this == cashpower || this == gas || this == groceries;
}
