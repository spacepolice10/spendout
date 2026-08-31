class Tour
  FEATURES = {
    "sources" => {
      colour: "blue", icon: "wallet", label: "Sources", chip: "Create a source",
      title: "Create a source for each place money lives.",
      lead: "Open My money and add a source for a wallet, card, cash, or account. Name it, enter the amount, and confirm its currency.",
      detail_title: "One currency per source",
      detail: "A source keeps that currency and its base-relative quote for good. Spend from it, top it up, and add another source whenever money sits somewhere else. The first source uses the budget’s base currency and cannot be deleted on its own.",
      image: "tour-sources.png",
      alt: "Spendout sources screen listing wallet-like money sources with remaining balances"
    },
    "allocations" => {
      colour: "yellow", icon: "category", label: "Allocations", chip: "Plan the spending",
      title: "Plan what matters. Classify everything else.",
      lead: "Open Plan and add a category. Give planned allocations an amount to reserve, or leave an unplanned category at zero to only classify spending.",
      detail_title: "A plan never blocks an expense",
      detail: "Planned allocations reserve from the general remainder and can warn when they exceed available funds. Unplanned categories organize spending from that remainder. Either way, a real expense still goes through.",
      image: "tour-allocations.png",
      alt: "Spendout Plan screen showing planned allocations with spent-versus-planned progress"
    },
    "expenses" => {
      colour: "green", icon: "receipt-dollar", label: "Expenses", chip: "Track an expense",
      title: "Record a purchase in a few focused steps.",
      lead: "Open Expenses, add an expense, enter the amount, choose the source it came from, and optionally a category and date.",
      detail_title: "The snapshot stays as you saved it",
      detail: "Spendout stores the purchase amount and currency, the source debit, the conversion quote, and the occurrence date together. To correct a record, delete it and create it again so history is never silently rewritten.",
      image: "tour-expense-form.png",
      alt: "Spendout new expense form with amount, source, category, date, note, and currency fields"
    },
    "currency-picker" => {
      colour: "orange", icon: "currency-dollar", label: "Currency picker", chip: "Pick a currency",
      title: "Search the catalog. Confirm the currency.",
      lead: "Open Currency on a source, plan, or expense. Search by name or code, then choose the ISO currency that matches the money in front of you.",
      detail_title: "A useful default, never a silent choice",
      detail: "Spendout can bring a likely currency forward from your timezone. The budget base currency stays fixed after creation, and every currency-bearing record makes the selected code visible before you save.",
      image: "tour-currency-open.png",
      alt: "Spendout currency picker dialog with a search field and USD selected"
    },
    "exchanges" => {
      colour: "pink", icon: "arrows-exchange", label: "Exchanges", chip: "Make an exchange",
      title: "Move money from one source to another.",
      lead: "On a source, choose Exchange. Enter how much to send, name the receiving source, and confirm its currency.",
      detail_title: "Both sides are saved together",
      detail: "The debit, the new receiver, both amounts, and the sender-relative quote are stored as one event — even when both sources use the same currency. Open My money later to read the exchange in source history.",
      image: "tour-exchange-amount-open.png",
      alt: "Spendout exchange form with the sender amount field expanded"
    },
    "expense-notes" => {
      colour: "blue", icon: "note", label: "Notes", chip: "Add a note",
      title: "Leave the detail that an amount cannot tell.",
      lead: "On an expense, open Note and type up to 200 characters when a category and amount are not enough.",
      detail_title: "Present when useful, quiet otherwise",
      detail: "The note is optional and stored with the expense snapshot. Skip it on a quick coffee; use it when you need to remember who was paid, what the receipt said, or why the amount looks unusual.",
      image: "tour-expense-note-open.png",
      alt: "Spendout expense form with the Note field expanded and populated"
    },
    "daily-gauge" => {
      colour: "yellow", icon: "gauge", label: "Daily gauge", chip: "Read the daily gauge",
      title: "See what is safe to spend today.",
      lead: "Open Expenses and read the daily gauge. It shows unplanned remainder spread across the days left in the budget.",
      detail_title: "A signal. Never a gate.",
      detail: "Spend less today and tomorrow’s number grows. Spend more and the meter adjusts. Money reserved by planned allocations never touches this reading, and overspending is still allowed — the gauge informs, it does not lock.",
      image: "tour-daily-gauge.png",
      alt: "Spendout expenses screen with the daily fuel gauge showing remaining unplanned money"
    },
    "source-design" => {
      colour: "green", icon: "credit-card", label: "Card design", chip: "Pick a card design",
      title: "Give every source a face you can recognize.",
      lead: "While creating or editing a source, open Design and pick a card face — bank, cash, wallet, or one of the cat-network cards.",
      detail_title: "Easy to spot while you spend",
      detail: "The chosen design appears on the source list, expense source picker, and exchanges, so the right wallet or card stays obvious without reading the name twice.",
      image: "tour-source-design.png",
      alt: "Spendout source form with card design options such as Mastercat and cash"
    },
    "finish-allocations" => {
      colour: "orange", icon: "pig-money", label: "Finish a plan", chip: "Finish a plan",
      title: "Finish a plan to free what you did not spend.",
      lead: "Open a planned allocation and choose Finish. Confirm to release its unspent reservation back to the general remainder.",
      detail_title: "History stays; the hold does not",
      detail: "Finished plans keep their expenses and can be reopened later. Fully spent plans stay active on purpose, so you can still overspend them. Finishing is the explicit way to say this reservation is done.",
      image: "tour-finish-allocation.png",
      alt: "Spendout allocation card with a Finish action that releases unspent reservation"
    },
    "reports" => {
      colour: "pink", icon: "chart-bar", label: "Reports", chip: "Check the reports",
      title: "See where the money went.",
      lead: "Open Reports to read totals, the everyday average, the largest expense, and spending by category and date.",
      detail_title: "The period, in one place",
      detail: "Finished and removed categories stay labeled so history remains readable. Use the calendar intensity and category breakdown when you want the story behind the daily gauge.",
      image: "tour-reports.png",
      alt: "Spendout reports screen showing spending totals, a calendar, and category breakdown"
    },
    "account" => {
      colour: "blue", icon: "logout", label: "Account", chip: "Control account",
      title: "Sign out, or remove the whole budget.",
      lead: "Open User. Sign out to end this session, or remove the budget to delete its sources, allocations, expenses, and exchanges.",
      detail_title: "Removal is permanent",
      detail: "Removing a budget cannot be undone. Archived budgets otherwise remain as history, but this action clears the active budget so you can start again. Sign-in stays passwordless either way.",
      image: "tour-account.png",
      alt: "Spendout user page with Sign out and Remove budget actions"
    },
    "language" => {
      colour: "yellow", icon: "language", label: "Language", chip: "Change the language",
      title: "Pick the language on the same User page.",
      lead: "Open User and choose the interface language. It lives next to sign out and budget removal, so account choices stay in one place.",
      detail_title: "One page for account choices",
      detail: "Switch the language Spendout uses without hunting through a separate settings screen. Sign out and budget removal stay on the same page.",
      image: "tour-account.png",
      alt: "Spendout user page where language choice sits beside sign out"
    },
    "once" => {
      colour: "green", icon: "device-laptop", label: "Deploy with ONCE", chip: "Deploy with ONCE",
      title: "Put Spendout on your own server.",
      lead: "Deploy with ONCE when you want guided self-hosting: first-run administrator setup, managed HTTPS, updates, persistent storage, and backup hooks.",
      detail_title: "Your server, your data",
      detail: "Spendout is a compact Rails app with SQLite and no add-ons. You can also deploy with Kamal today. An ONCE-ready image is meant for a one-command install you keep.",
      image: "tour-once.png",
      alt: "Deployment terminal showing an ONCE command to host Spendout on your server"
    },
    "category-style" => {
      colour: "orange", icon: "sparkles", label: "Auto icons", chip: "Style a category",
      title: "Name a category. Spendout suggests a look.",
      lead: "Type a category name such as Groceries or Rent. Spendout suggests a fitting icon and colour from the name.",
      detail_title: "Automatic, not restrictive",
      detail: "Accept the suggestion to keep setup fast, or open Icon and Colour and pick your own. The look stays with the category on plans, expenses, and reports.",
      image: "tour-category-style-open.png",
      alt: "Spendout category form with an automatic icon and colour suggestion"
    },
    "enter-rate" => {
      colour: "pink", icon: "edit", label: "Enter a rate", chip: "Enter a rate",
      title: "Type the quote yourself when you know it.",
      lead: "When a record uses another currency, open the rate field and enter how many units of that currency equal one unit of the budget base.",
      detail_title: "Suggestions are optional; you confirm",
      detail: "Dated reference rates may appear as editable starting points. Spendout never silently updates a saved quote. Historical amounts stay as you confirmed them.",
      image: "tour-rate-confirm-open.png",
      alt: "Spendout conversion-rate dialog with a manually entered quote"
    }
  }.freeze

  PAGES = [ "welcome", *FEATURES.keys, "finish" ].freeze
end
