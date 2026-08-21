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
    assert_select "fieldset[data-expense-allocations] > div:not([data-create-category]) .icon-wrap",
      count: @budget.allocations.where(deleted_at: nil).count
    assert_select "input[name='expense[allocation_id]'][value='#{@allocation.id}'][checked]"
    assert_select "fieldset[data-expense-allocations] > div input[name='expense[allocation_id]'][value='']", count: 0
    assert_select "[data-expense-form-target='allocation']", count: 0
    assert_select "[data-expense-options]"
    assert_select "details[data-optional-item]", count: 4
    assert_select "details[data-controller='details']", count: 0
    assert_select "details[data-action]", count: 0
    assert_select "details[data-optional-item] > summary > span > .icon-wrap", count: 4
    assert_select "details.utilities--sr-only" do
      assert_select "fieldset[data-expense-sources]"
    end
    assert_select "[data-optional-item] > input[type='checkbox']", count: 0
    assert_select "details[data-optional-item] > summary" do |summaries|
      assert_equal [ "From #{@source.name}", "Spend on #{@allocation.name}", "Date August 20, 2026", "Note Added" ],
        summaries.map { |summary| summary.text.squish }
    end
    assert_select "details[data-optional-item]:not([open]) > summary > span", text: "Date"
    assert_select "details[data-optional-item] > summary > small", text: /August 20, 2026/
    assert_select "details[data-optional-item]:not([open]) > summary > span", text: "Note"
    assert_select "details[data-optional-item]:not([open]) > summary > small[hidden]", text: "Added"
    assert_select "[data-optional-item-control] label[for='expense_occurred_on']"
    assert_select "[data-optional-item-control] label[for='expense_note']"
    assert_select "input[name='expense[occurred_on]'][value='2026-08-20'][min='2026-08-18'][max='2026-09-16']"
    assert_select "input[name='expense[note]'][maxlength='200']"
    assert_select "input[name='expense[note]'][size]", count: 0
    assert_select "input[type='text'][name]#expense_category_filter", count: 0
    assert_select "details[data-controller='category-filter'] fieldset[data-expense-allocations]"
    assert_select "input[type='text']#expense_category_filter[placeholder='Find or add category'][aria-label='Find or add category'][data-category-filter-target='filter'][data-action='input->category-filter#filter']"
    assert_select "input[type='hidden'][name='expense[category_name_to_create]'][data-category-filter-target='pendingNameTextform']"
    assert_select "fieldset[data-expense-allocations] label[data-category-filter-target='option'][data-filter-value='#{@allocation.name}']"
    assert_select "button[type='button'][hidden][data-size='lg'][data-category-filter-target='addButton'][data-action='category-filter#createPendingCategory']", text: "Add new"
    assert_select "button[type='button'][hidden][data-size='lg'][data-category-filter-target='cleanupButton'][data-action='category-filter#cleanup']", text: "Cleanup"
    assert_select "template[data-category-filter-target='template'] [data-category-filter-target='pendingCategory'][data-pending-category] > label"
    assert_select "template input[type='radio'][name='expense[allocation_id]'][value=''][checked]"
    assert_select "template [data-category-filter-target='pendingCategoryName']"
    assert_select "template button[type='button'][aria-label='Delete new category'][data-action='category-filter#removePendingCategory']", text: "Delete"
    assert_select "label[for='expense_amount'] > legend", text: "How much?"
    assert_select "input[name='expense[amount]'][aria-label='Amount'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='money-input']"
    assert_select "input[name='expense[amount]'][value]", count: 0
    assert_select "input[name='expense[currency_code]']", count: 0
  end

  test "shows the source disclosure when more than one active source is available" do
    sign_in_as(@user)
    @budget.sources.create!(name: "Cash", amount: 100, currency_code: "USD")

    get new_budget_expense_path(@budget)

    assert_select "details.utilities--sr-only", count: 0
    assert_select "input[type='radio'][name='expense[source_id]']", count: 2
  end

  test "creates an allocated expense and inherits source currency" do
    sign_in_as(@user)

    assert_difference("Expense.count", 1) do
      post budget_expenses_path(@budget), params: {
        expense: {
          source_id: @source.id,
          allocation_id: @allocation.id,
          amount: "25.2500",
          occurred_on: "2026-08-20",
          note: "Dinner",
          currency_code: "EUR"
        }
      }
    end

    expense = @budget.expenses.order(:created_at, :id).last
    assert_redirected_to budget_path(@budget)
    assert_equal @source, expense.source
    assert_equal @allocation, expense.allocation
    assert_equal BigDecimal("25.2500"), expense.amount
    assert_equal Date.new(2026, 8, 20), expense.occurred_on
    assert_equal "Dinner", expense.note
    assert_equal "USD", expense.currency_code
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

    assert_redirected_to budget_path(@budget)
    assert_equal "Coffee", category.name
    assert_not category.planned?
    assert_equal BigDecimal("0"), category.amount
    assert_equal @source.currency_code, category.currency_code
    assert_equal Iconable::DEFAULT_ICON, category.icon
    assert_equal Colourable::DEFAULT_COLOUR, category.colour
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
      assert_select "summary", text: /Spend on Coffee/
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

    assert_redirected_to budget_path(@budget)
    assert_equal "Expense was deleted.", flash[:notice]
    assert_equal @source.amount, @source.reload.spendable_amount
  end

  test "show displays details and owns the delete action" do
    sign_in_as(@user)

    get expense_path(@expense)

    assert_response :success
    assert_select "h1", text: "Expense"
    assert_select "time[datetime='2026-08-19']"
    assert_select "dd", text: /\$125 USD/
    assert_select "a[href='#{source_path(@source)}']", text: @source.name
    assert_select "a[href='#{allocation_path(@allocation)}']", text: @allocation.name
    assert_select "dd", text: @expense.note
    assert_select "a[aria-label='Back to budget'][href='#{budget_path(@budget)}']"
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
