require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @source = sources(:active)
    @allocation = allocations(:active)
    @expense = expenses(:active)
  end

  test "requires authentication" do
    get new_budget_expense_path(@budget)

    assert_redirected_to new_session_path
  end

  test "index renders the expense history without currency management" do
    sign_in_as(@user)

    get budget_expenses_path(@budget)

    assert_response :success
    assert_select "meta[name='view-transition'][content='same-origin']", count: 1
    assert_select "body > main[data-anchor='footer']"
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "article[data-elevation='2'][data-gauge-plate] > h2", count: 0
    assert_select "[data-cybercat-answer]" do
      assert_select "img[alt='Cybercat'][width='40'][height='40']", count: 1
      expected_answer = ApplicationController.helpers.cybercat_spending_answer(@budget.todays_remainder_percentage)
      assert_select "p", text: expected_answer, count: 1
    end
    assert_select "article[data-elevation='2'] > header", count: 0
    assert_select "article[data-elevation='2'] [data-gauge-bolts][aria-hidden='true'] span", count: 4
    assert_select "[role='progressbar'][aria-label='Safe spending available today']", count: 1
    assert_select "[data-daily-gauge][data-controller='daily-gauge'] [data-remainder-gauge] svg [data-remainder-gauge-needle]", count: 1
    assert_select "a[href='#{new_budget_expense_path(@budget)}']"
    assert_select "a", text: "Currencies", count: 0
  end

  test "index paginates expense history" do
    sign_in_as(@user)
    15.times do |index|
      @budget.expenses.create!(
        source: @source,
        amount: 1,
        occurred_on: @budget.period_from + index.days,
        note: "Expense #{index}"
      )
    end

    get budget_expenses_path(@budget)

    assert_select "[data-testid='expense-card']", count: 15
    assert_select "nav[aria-label='Pagination for expenses']", text: /Page 1 of 2/
    assert_select "nav[aria-label='Pagination for expenses'] a", text: "Previous", count: 0
    assert_select "nav[aria-label='Pagination for expenses'] a", text: "Next" do |links|
      get links.first["href"]
    end

    assert_response :success
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "nav[aria-label='Pagination for expenses']", text: /Page 2 of 2/
    assert_select "nav[aria-label='Pagination for expenses'] a", text: "Previous"
    assert_select "nav[aria-label='Pagination for expenses'] a", text: "Next", count: 0
  end

  test "index shows Cybercat's no-spending answer when the budget has no expenses" do
    @budget.expenses.delete_all
    sign_in_as(@user)

    get budget_expenses_path(@budget)

    assert_select "[data-cybercat-answer] p", text: "Nothing spent yet—nice.", count: 1
  end

  test "index redirects an archived budget to creation when no budget is active" do
    sign_in_as(@user)
    @budget.update_columns(period_to: Date.yesterday)

    get budget_expenses_path(@budget)

    assert_redirected_to new_budget_path
  end

  test "new defaults source allocation and occurrence and renders controls" do
    sign_in_as(@user)

    travel_to Date.new(2026, 8, 20) do
      get new_budget_expense_path(@budget)
    end

    assert_response :success
    assert_select "fieldset[data-expense-sources] > div > label", count: 1
    assert_select "input[type='radio'][name='expense[source_id]'][value='#{@source.id}'][checked][required]"
    assert_select "fieldset[data-expense-allocations] > div:not([data-create-category]) > label",
      count: @budget.allocations.where(deleted_at: nil).count
    assert_select "fieldset[data-expense-allocations] > div:not([data-create-category]) label .icon-wrap",
      count: @budget.allocations.where(deleted_at: nil).count
    assert_select "input[name='expense[allocation_id]'][value='#{@allocation.id}'][checked]"
    assert_select "fieldset[data-expense-allocations] > div input[name='expense[allocation_id]'][value='']", count: 0
    assert_select "[data-expense-form-target='allocation']", count: 0
    assert_select "[data-expense-options]"
    assert_select "details[data-optional-item]", count: 4
    assert_select "select[name='expense[currency_code]'][data-expense-fields-target='currency'] option[value='USD'][selected]"
    assert_select "input[name='expense[conversion_rate]'][data-expense-fields-target='rate']"
    assert_select "details[data-controller='details']", count: 0
    assert_select "details[data-action]", count: 0
    assert_select "details[data-optional-item] > summary > span", count: 4
    assert_select "[data-optional-item] > input[type='checkbox']", count: 0
    assert_select "details[data-optional-item] > summary" do |summaries|
      assert_equal [ "From: #{@source.name}", "Category: #{@allocation.name}", "Date: August 20, 2026", "Note: Added" ],
        summaries.map { |summary| summary.text.squish }
    end
    assert_select "details[data-optional-item]:not([open]) > summary > span", text: "Date:"
    assert_select "details[data-optional-item]:not([open]) > summary > small", text: /August 20, 2026/
    assert_select "details[data-optional-item] > summary > small", text: "Added"
    assert_select "[data-optional-item-control] label[for='expense_occurred_on']"
    assert_select "[data-optional-item-control] label[for='expense_note']"
    assert_select "input[name='expense[occurred_on]'][value='2026-08-20'][min='2026-08-18'][max='2026-09-16']"
    assert_select "textarea[name='expense[note]'][maxlength='200']"
    assert_select "textarea[name='expense[note]'][rows]", count: 0
    assert_select "input[type='text'][name]#expense_category_filter", count: 0
    assert_select "details[data-controller~='category-fields'] fieldset[data-expense-allocations]"
    assert_select "input[type='text']#expense_category_filter[placeholder='Find or add category'][aria-label='Find or add category'][data-category-fields-target='filter'][data-action='input->category-fields#filter']"
    assert_select "input[type='hidden'][name='expense[category_name_to_create]'][data-category-fields-target='pendingNameTextform']"
    assert_select "fieldset[data-expense-allocations] label[data-category-fields-target='option'][data-filter-value='#{@allocation.name}']"
    assert_select "small[hidden][data-category-fields-target='creationTip']", text: /Category named.*will be created/
    assert_select "[data-category-fields-target='creationTipName']"
    assert_select "fieldset[data-expense-allocations] button", count: 0
    assert_select "input[name='expense[amount]'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='amount-fields']"
    assert_select "input[name='expense[amount]'][value]", count: 0
    assert_select "input[type='radio'][name='expense-currency-picker'][value='USD'][checked]"
  end

  test "shows the source disclosure when more than one active source is available" do
    sign_in_as(@user)
    @budget.sources.create!(name: "Cash", amount: 100, currency_code: "USD")

    get new_budget_expense_path(@budget)

    assert_select "details.utilities--sr-only", count: 0
    assert_select "input[type='radio'][name='expense[source_id]']", count: 2
  end

  test "prioritizes the last expense currency then the budget and source currencies" do
    sign_in_as(@user)
    @source.update!(deleted_at: Time.current)
    euro_source = @budget.sources.create!(name: "Euros", amount: 100, currency_code: "EUR", rate: "0.8")
    @budget.expenses.create!(source: euro_source, amount: 32, currency_code: "THB", conversion_rate: 1)

    get new_budget_expense_path(@budget)

    assert_select "[data-currency-picker-option]:nth-child(1) input[value='EUR']"
    assert_select "[data-currency-picker-option]:nth-child(2) input[value='THB']"
    assert_select "[data-currency-picker-option]:nth-child(3) input[value='USD']"
    assert_select "select[name='expense[currency_code]'] option[value='EUR'][selected]"
  end

  test "shows an empty category filter when no active allocations are available" do
    sign_in_as(@user)
    @budget.allocations.update_all(deleted_at: Time.current)

    get new_budget_expense_path(@budget)

    assert_select "fieldset[data-expense-allocations] label[data-category-fields-target='option']", count: 0
    assert_select "input#expense_category_filter"
    assert_select "[data-category-fields-target='creationTip'][hidden]"
    assert_select "fieldset[data-expense-allocations] button", count: 0
  end

  test "new expense excludes finished allocations" do
    sign_in_as(@user)
    @allocation.update!(finished_at: Time.current)

    get new_budget_expense_path(@budget)

    assert_response :success
    assert_select "input[name='expense[allocation_id]'][value='#{@allocation.id}']", count: 0
  end

  test "creates an allocated expense in a currency independent from its source" do
    sign_in_as(@user)

    assert_difference("Expense.count", 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          allocation_id: @allocation.id,
          amount: "25.2500",
          occurred_on: "2026-08-20",
          note: "Dinner",
          currency_code: "EUR",
          conversion_rate: "0.5"
        }
      }
    end

    expense = @budget.expenses.order(:created_at, :id).last
    assert_redirected_to budget_expenses_path(@budget)
    assert_equal @source, expense.source
    assert_equal @allocation, expense.allocation
    assert_equal BigDecimal("25.2500"), expense.amount
    assert_equal Date.new(2026, 8, 20), expense.occurred_on
    assert_equal "Dinner", expense.note
    assert_equal "EUR", expense.currency_code
    assert_equal BigDecimal("50.5"), expense.source_amount
    assert_equal "USD", expense.source.currency_code
  end

  test "creates an expense without an allocation" do
    sign_in_as(@user)

    assert_difference("Expense.count", 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          allocation_id: "",
          amount: "10",
          occurred_on: "2026-08-20"
        }
      }
    end

    assert_nil @budget.expenses.order(:created_at, :id).last.allocation
  end

  test "creates an unplanned category with an expense" do
    sign_in_as(@user)

    assert_difference([ "Expense.count", "Allocation.count" ], 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          allocation_id: @allocation.id,
          category_name_to_create: "Coffee",
          amount: "5.25",
          occurred_on: "2026-08-20"
        }
      }
    end

    expense = @budget.expenses.order(:created_at, :id).last
    category = expense.allocation

    assert_redirected_to budget_expenses_path(@budget)
    assert_equal "Coffee", category.name
    assert_not category.planned?
    assert_equal BigDecimal("0"), category.amount
    assert_equal @source.currency_code, category.currency_code
    assert_equal "coffee", category.icon
    assert_equal "coral", category.colour
  end

  test "does not leave a category behind when its expense is invalid" do
    sign_in_as(@user)

    assert_no_difference([ "Expense.count", "Allocation.count" ]) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          category_name_to_create: "Coffee",
          amount: "2000",
          occurred_on: "2026-08-20"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "details[data-optional-item][open]" do
      assert_select "summary", text: /Category: Coffee/
    end
    assert_select "input[name='expense[category_name_to_create]'][value='Coffee']"
  end

  test "rejects overspending and tampered associations" do
    sign_in_as(@user)

    assert_no_difference("Expense.count") do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          amount: "1375.2501",
          occurred_on: "2026-08-20"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Amount must be less than or equal to 1375.25/
    assert_select "summary [data-form-target='summaryContent']", text: "1.375,2501"

    assert_no_difference("Expense.count") do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: sources(:other).id,
          allocation_id: allocations(:other).id,
          amount: "1",
          occurred_on: "2026-08-20"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Source must belong to this budget/
    assert_select "[role='alert']", text: /Allocation must belong to this budget/
  end

  test "deletes an owned expense permanently" do
    sign_in_as(@user)

    assert_difference("Expense.count", -1) do
      delete expense_path(@expense)
    end

    assert_redirected_to budget_expenses_path(@budget)
    assert_equal "Expense was deleted.", flash[:notice]
    assert_equal @source.amount, @source.reload.spendable_amount
  end

  test "show displays details and owns the delete action" do
    sign_in_as(@user)

    get expense_path(@expense)

    assert_response :success
    assert_select "h1", text: "Expense"
    assert_select "article[data-expense-receipt]"
    assert_select "[data-expense-total]", text: /\$125.*USD/
    assert_select "[data-expense-source]", text: /#{Regexp.escape(@source.name)}.*\$125.*USD/
    assert_select "[data-expense-breakdown] dt", text: "Budget value"
    assert_select "[data-expense-receipt-note] strong", text: @expense.note
    assert_select "time[datetime='2026-08-19']"
    assert_select "dd", text: /\$125 USD/
    assert_select "dt", text: "Budget value"
    assert_select "a[href='#{source_path(@source)}']", text: @source.name
    assert_select "a[href='#{allocation_path(@allocation)}']", text: @allocation.name
    assert_select "a[aria-label='Back to expenses']", count: 0
    assert_select "form[action='#{expense_path(@expense)}'] button[data-turbo-confirm='Delete this expense permanently?']", text: "Delete expense"
  end

  test "cannot create or delete through another user's budget" do
    sign_in_as(@user)

    post budget_expenses_path(budgets(:other)), params: {
      expense: { source_id: sources(:other).id, amount: 1, occurred_on: "2026-08-10" }
    }
    assert_response :not_found

    delete expense_path(expenses(:other))
    assert_response :not_found
    assert Expense.exists?(expenses(:other).id)

    get expense_path(expenses(:other))
    assert_response :not_found
  end
end
