require "test_helper"

class AllocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @allocation = allocations(:active)
  end

  test "requires authentication" do
    get budget_allocations_path(@budget)

    assert_redirected_to new_session_path
  end

  test "index lists active allocations and remaining amount" do
    sign_in_as(@user)

    get budget_allocations_path(@budget)

    assert_response :success
    assert_select "body > main[data-anchor='footer']"
    assert_select "[data-testid='allocation-card']", count: 1, text: /Housing/
    assert_select "progress[data-testid='allocation-progress'][value='125.0'][max='300.0']"
    assert_select "progress[aria-label='$125 spent of $300 planned']"
    assert_select "[data-testid='allocation-card'] small", text: /\$125 spent of \$300 planned/
    assert_select "dt", text: "Remaining"
    assert_select "dd", text: /1,200.25 USD/
    assert_select "[data-testid='overallocation-warning']", count: 0
    assert_select "a[href='#{new_budget_allocation_path(@budget)}']", text: /New category/
  end

  test "index excludes deleted allocations" do
    sign_in_as(@user)
    @allocation.update!(deleted_at: Time.current)

    get budget_allocations_path(@budget)

    assert_response :success
    assert_select "[data-testid='allocation-card']", count: 0
  end

  test "index shows when spending exceeds an allocation" do
    sign_in_as(@user)
    @allocation.update!(amount: 100)

    get budget_allocations_path(@budget)

    assert_response :success
    assert_select "progress[data-testid='allocation-progress'][value='100.0'][max='100.0']"
    assert_select "progress[aria-label='$125 spent of $100 planned']"
    assert_select "[data-testid='allocation-card'] small", text: /\$25 over plan/
  end

  test "index subtracts a different-currency plan from the base currency remainder" do
    sign_in_as(@user)
    @budget.allocations.create!(name: "European trip", amount: 50, currency_code: "EUR", rate: "0.8")

    get budget_allocations_path(@budget)

    assert_response :success
    assert_select "dd", text: /1,137.75 USD/
  end

  test "new defaults to base currency and renders shared appearance options" do
    sign_in_as(@user)

    get new_budget_allocation_path(@budget)

    assert_response :success
    assert_select "select[name='allocation[currency_code]'] option[value='USD'][selected]"
    assert_select "select[name='allocation[currency_code]'][data-currency-picker-target='select']"
    assert_select "input[type='search'][placeholder='Search by name or code'][data-currency-picker-target='filter']"
    assert_select "input[type='radio'][value='USD'][data-currency-picker-target='radio'][checked]"
    assert_select "[data-currency-picker-option]:first-child > label input[value='USD'][checked]"
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
    assert_select "[data-currency-picker-target='emptyState'][hidden]"
    assert_select "input[name='allocation[rate]'][type='text'][inputmode='decimal'][required][data-controller='amount-fields'][data-currency-fields-target='rate']"
    assert_select "input[name='allocation[rate]'][data-amount-fields-fraction-digits-value='12']"
    assert_select "output[data-currency-fields-target='converted']", count: 0
    assert_select "[data-currency-fields-target='rateFields'][hidden]"
    assert_select "dialog[data-currency-picker-target='rateDialog'][aria-labelledby]"
    assert_select "button[data-currency-picker-target='rateTrigger'][aria-haspopup='dialog']"
    assert_select "form[data-controller~='form'][data-controller~='currency-fields'][data-currency-fields-base-currency-value='USD']"
    assert_select "form[data-controller~='currency-fields'][data-currency-fields-reference-url-value='#{currency_reference_path}']"
    assert_select "[data-currency-fields-target='rateStatus']", count: 0
    assert_select "dialog[data-currency-picker-target='rateDialog'] button[data-appearance='keycap']", text: "Apply"
    assert_select "input[name='allocation[amount]'][data-currency-fields-target='amount']"
    assert_select "select[name='allocation[source_id]']", count: 0
    assert_select "input[name='allocation[icon]'][type='radio']", count: Allocation.icon_options.size
    assert_select "input[name='allocation[icon]'][value='wallet'][checked][aria-label='Wallet']"
    assert_select "input[name='allocation[colour]'][type='radio']", count: Allocation.colour_options.size
    assert_select "input[name='allocation[colour]'][value='green'][checked]"
    assert_select "input[name='allocation[amount]'][type='text'][inputmode='decimal'][placeholder='0'][data-controller='amount-fields']"
    assert_select "input[name='allocation[amount]'][value]", count: 0
    assert_select "input[name='allocation[amount]'][data-amount-fields-start-value]", count: 0
  end

  test "creates an allocation with its selected currency" do
    sign_in_as(@user)

    assert_difference("Allocation.count", 1) do
      post budget_allocations_path(@budget), params: {
        allocation: {
          name: "Emergency savings",
          amount: "100.2500",
          currency_code: "USD",
          rate: "1",
          source_id: sources(:other).id,
          icon: "pig-money",
          colour: "red"
        }
      }
    end

    allocation = @budget.allocations.order(:created_at, :id).last
    assert_redirected_to budget_allocations_path(@budget)
    assert_equal "Emergency savings", allocation.name
    assert_equal BigDecimal("100.2500"), allocation.amount
    assert_equal "USD", allocation.currency_code
    assert_equal BigDecimal("1"), allocation.rate
    assert_equal "pig-money", allocation.icon
    assert_equal "red", allocation.colour
  end

  test "allows over-allocation and returns a warning" do
    sign_in_as(@user)

    assert_difference("Allocation.count", 1) do
      post budget_allocations_path(@budget), params: {
        allocation: {
          name: "Ambitious plan",
          amount: "1500.2501",
          currency_code: "USD",
          icon: "wallet",
          colour: "green"
        }
      }
    end

    allocation = @budget.allocations.order(:created_at, :id).last
    assert_redirected_to budget_allocations_path(@budget)
    assert_equal "Allocation was created. Planned allocations now exceed available sources.", flash[:notice]

    get budget_allocations_path(@budget)
    assert_select "[data-testid='overallocation-warning']", text: /exceed available sources by \$300 USD/
  end

  test "invalid currency creates no record and rerenders errors" do
    sign_in_as(@user)

    assert_no_difference("Allocation.count") do
      post budget_allocations_path(@budget), params: {
        allocation: {
          name: "Wrong currency",
          amount: "1",
          currency_code: "XXX",
          icon: "wallet",
          colour: "green"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Currency code is not included in the list/
    assert_select "select[name='allocation[currency_code]'] option[value='USD']"
  end

  test "rerendered form shows the chosen non-popular currency first" do
    sign_in_as(@user)

    assert_no_difference("Allocation.count") do
      post budget_allocations_path(@budget), params: {
        allocation: {
          name: "",
          amount: "1",
          currency_code: "VND",
          icon: "wallet",
          colour: "green"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[data-currency-picker-option]:first-child > label input[value='VND'][checked]"
    assert_select "label[data-currency-picker-target='option']:not([hidden])", count: Currency.options.size
  end

  test "show displays allocation amount and budget without a source" do
    sign_in_as(@user)

    get allocation_path(@allocation)

    assert_response :success
    assert_select "h1", text: @allocation.name
    assert_select "dd", text: /300 USD/
    assert_select "dt", text: "Source", count: 0
    assert_select "a[href='#{budget_expenses_path(@budget)}']", text: @budget.name
    assert_select "a[aria-label='Back to allocations'][href='#{budget_allocations_path(@budget)}']"
  end

  test "show labels a deleted allocation" do
    sign_in_as(@user)
    @allocation.update!(deleted_at: Time.current)

    get allocation_path(@allocation)

    assert_response :success
    assert_select "small", text: "Deleted"
  end

  test "removes an allocation without deleting it from historical expenses" do
    sign_in_as(@user)
    expense = expenses(:active)

    assert_no_difference("Allocation.count") do
      delete allocation_path(@allocation)
    end

    assert_redirected_to budget_allocations_path(@budget)
    assert_equal "Allocation was removed.", flash[:notice]
    assert_predicate @allocation.reload, :deleted?
    assert_equal @allocation, expense.reload.allocation
  end

  test "cannot access another user's budget or allocation" do
    sign_in_as(@user)

    get budget_allocations_path(budgets(:other))
    assert_response :not_found

    get allocation_path(allocations(:other))
    assert_response :not_found
  end
end
