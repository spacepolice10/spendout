require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires authentication" do
    get budgets_path

    assert_redirected_to new_session_path
  end

  test "index lists active budgets before faded archived budgets" do
    sign_in_as(@user)

    travel_to Date.new(2026, 8, 18) do
      get budgets_path
    end

    assert_response :success
    assert_select "[data-testid='budget-card']", count: 2
    assert_select "[data-testid='budget-link']:first-of-type [data-archived='false']"
    assert_select "[data-testid='budget-card'][data-archived='true']", text: /Archived/
    assert_select "a[aria-label='New budget'][href='#{new_budget_path}']"
  end

  test "new builds only code and amount form fields" do
    sign_in_as(@user)

    get new_budget_path

    assert_response :success
    assert_select "select[name='budget[currency_code]'][aria-label='Choose your salary currency']"
    assert_select "select[name='budget[currency_code]'] option[value='USD']"
    assert_select "fieldset.salary legend", text: "What's your salary?"
    assert_select "input[name='budget[source_amount]'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='money-input'][aria-label='Enter your salary amount']"
    assert_select "input[name='budget[source_amount]'][value]", count: 0
    assert_select "input[name='budget[source_amount]'][data-money-input-start-value]", count: 0
    assert_select "input[data-controller='money-input'][data-action]", count: 0
    assert_select "input[name*='[name]']", count: 0
    assert_select "input[name*='[numeric_code]']", count: 0
    assert_select "input[type='radio'][value='14_days']"
    assert_select "input[type='radio'][value='30_days'][checked]"
    assert_select "fieldset legend", text: "How often do you get paid?"
    assert_select "details:not([open]) summary", text: "Change start date"
    assert_select "a[aria-label='Back to budgets'][href='#{budgets_path}']"
  end

  test "show has accessible back navigation" do
    sign_in_as(@user)

    get budget_path(budgets(:active))

    assert_response :success
    assert_select "a[aria-label='Back to budgets'][href='#{budgets_path}']"
    assert_select "a[href='#{budget_sources_path(budgets(:active))}']", text: "Sources"
    assert_select "a[href='#{budget_allocations_path(budgets(:active))}']", text: "Allocations"
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "[data-testid='expense-day'] > header" do
      assert_select "time[datetime='2026-08-19']"
      assert_select "[data-testid='expense-day-total']", text: /\$125 USD/
    end
    assert_select "[data-testid='expense-card'] > main" do
      assert_select ".icon-wrap[style*='--color-palette-yellow']"
      assert_select "[data-expense-name]", text: allocations(:active).name
      assert_select "[data-testid='expense-note'][aria-label='Has note']", text: "Note"
      assert_select "[data-expense-source]", count: 0
      assert_select "[data-expense-amount]", text: /\$125 USD/
    end
    assert_select "a[data-expense-link][aria-label='View expense'][href='#{expense_path(expenses(:active))}'] > [data-testid='expense-card']"
    assert_select "a[role='button'][aria-label='New expense'][href='#{new_budget_expense_path(budgets(:active))}']" do
      assert_select ".icon-wrap .icon"
    end
    assert_select "button", text: "Delete expense", count: 0
  end

  test "show displays only today's remainder for an active budget" do
    sign_in_as(@user)

    travel_to Date.new(2026, 8, 19) do
      get budget_path(budgets(:active))

      assert_select "dt", text: "Today's remainder"
      assert_select "dd", text: /41.39 USD/
      assert_select "[role='progressbar'][data-remainder-progress][aria-label='Daily budget health'][aria-valuenow='100.0']"
      assert_select "[data-remainder-progress-fill]"
      assert_select "[data-remainder-progress-marker]"
      assert_select "dt", count: 1
      assert_select "[data-testid='overallocation-warning']", count: 0

      get budget_path(budgets(:archived))

      assert_select "dt", text: "Today's remainder", count: 0
      assert_select "[data-remainder-progress]", count: 0
    end
  end

  test "show remains available when allocations exceed sources" do
    sign_in_as(@user)
    budget = budgets(:active)
    budget.allocations.create!(
      name: "Ambitious plan",
      amount: "1500.2501",
      currency_code: "USD",
      icon: "wallet",
      colour: "green"
    )

    get budget_path(budget)

    assert_response :success
    assert_select "[data-testid='overallocation-warning']", count: 0
  end

  test "show orders expenses newest occurrence first" do
    sign_in_as(@user)
    budget = budgets(:active)
    source = sources(:active)
    older = budget.expenses.create!(source: source, amount: 1, occurred_on: Date.new(2026, 8, 18), note: "Older")
    newer = budget.expenses.create!(source: source, amount: 1, occurred_on: Date.new(2026, 8, 20), note: "Newer")

    get budget_path(budget)

    expense_paths = css_select("a[data-expense-link]").map { |link| link["href"] }
    assert_equal [ expense_path(newer), expense_path(expenses(:active)), expense_path(older) ], expense_paths
    assert_select "[data-testid='expense-note']", count: 3, text: "Note"
    assert_select "[data-testid='expense-list']", text: /Newer|Groceries|Older/, count: 0
  end

  test "show groups expenses by occurrence date and totals each day in base currency" do
    sign_in_as(@user)
    budget = budgets(:active)
    eur = budget.currencies.create!(alphabetic_code: "EUR", rate: 1.25)
    source = budget.sources.create!(name: "Euros", amount: 100, currency_code: eur.alphabetic_code)
    budget.expenses.create!(source: source, amount: 8, occurred_on: Date.new(2026, 8, 19), note: "Coffee")
    budget.expenses.create!(source: sources(:active), amount: 5, occurred_on: Date.new(2026, 8, 18), note: "Snack")

    get budget_path(budget)

    days = css_select("[data-testid='expense-day']")
    assert_equal [ "2026-08-19", "2026-08-18" ], days.map { |day| day.at_css("time")["datetime"] }
    assert_match(/\$135 USD/, days.first.at_css("[data-testid='expense-day-total']").text.squish)
    assert_match(/\$5 USD/, days[1].at_css("[data-testid='expense-day-total']").text.squish)
  end

  test "show has an expense empty state" do
    sign_in_as(@user)
    budget = budgets(:active)
    budget.expenses.destroy_all

    get budget_path(budget)

    assert_select "[data-testid='expense-card']", count: 0
    assert_select "[data-testid='expense-list']", text: /No expenses yet/
    assert_select "a[role='button'][aria-label='New expense'][href='#{new_budget_expense_path(budget)}']"
  end

  test "show labels deleted allocations without revealing expense source or note" do
    sign_in_as(@user)
    budget = budgets(:active)
    source = budget.sources.create!(
      name: "Cash",
      amount: 100,
      currency_code: "USD",
      icon: "cash-banknote",
      colour: "green"
    )
    allocation = budget.allocations.create!(
      name: "Pocket money",
      amount: 50,
      currency_code: "USD",
      icon: "wallet",
      colour: "green"
    )
    expense = budget.expenses.create!(source: source, allocation: allocation, amount: 10, note: "Historical")
    allocation.update!(deleted_at: Time.current)
    source.update!(deleted_at: Time.current)

    get budget_path(budget)

    card = css_select("a[data-expense-link][href='#{expense_path(expense)}'] [data-testid='expense-card']").first
    assert_not_includes card.text.squish, "Cash"
    assert_not_includes card.text.squish, "Historical"
    assert_includes card.text.squish, "Pocket money (Deleted)"
  end

  test "creates the complete aggregate from canonical currency data" do
    sign_in_as(@user)

    assert_difference([ "Budget.count", "Currency.count", "Source.count" ], 1) do
      post budgets_path, params: budget_params(
        start: "2026-12-20",
        duration: "30_days",
        code: "all",
        amount: "123.4567",
        injected_name: "Hacked currency"
      )
    end

    budget = @user.budgets.order(:created_at).last
    assert_redirected_to budget_path(budget)
    assert_equal Date.new(2027, 1, 18), budget.period_to
    assert_equal "Lek", budget.base_currency.name
    assert_equal "008", budget.base_currency.numeric_code
    assert_equal BigDecimal("1"), budget.base_currency.rate
    assert_equal BigDecimal("123.4567"), budget.base_source.amount
    assert_equal "ALL", budget.base_source.currency_code
  end

  test "invalid source creates no records and rerenders errors" do
    sign_in_as(@user)

    assert_no_difference([ "Budget.count", "Currency.count", "Source.count" ]) do
      post budgets_path, params: budget_params(amount: "-1")
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /must be greater than or equal to 0/
  end

  test "cannot show another user's budget" do
    sign_in_as(@user)

    get budget_path(budgets(:other))

    assert_response :not_found
  end

  test "destroys the entire budget aggregate" do
    sign_in_as(@user)
    budget = budgets(:active)

    assert_difference("Budget.count", -1) do
      assert_difference("Currency.count", -1) do
        assert_difference("Source.count", -1) do
          assert_difference("Allocation.count", -1) do
            assert_difference("Expense.count", -1) do
              delete budget_path(budget)
            end
          end
        end
      end
    end

    assert_redirected_to budgets_path
  end

  private
    def budget_params(start: "2026-08-18", duration: "14_days", code: "USD", amount: "100", injected_name: nil)
      {
        budget: {
          period_from: start,
          duration: duration,
          currency_code: code,
          source_amount: amount,
          name: injected_name
        }
      }
    end
end
