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

  test "index lists plan items through their categories" do
    sign_in_as(@user)

    get budget_allocations_path(@budget)

    assert_response :success
    assert_select "[data-testid='allocation-card']", count: 1, text: /Housing/
    assert_select "[role='progressbar'][data-testid='allocation-progress'][aria-valuenow='125.0'][aria-valuemax='300.0']" do
      assert_select "span[data-filled='true']", count: 8
      assert_select "span[data-filled='false']", count: 12
    end
    assert_select "form[action='#{finish_allocation_path(@allocation)}']"
    assert_select "a[href='#{new_budget_allocation_path(@budget)}']"
  end

  test "index excludes deleted plans and keeps finished plans available" do
    sign_in_as(@user)
    @allocation.update!(finished_at: Time.current)

    get budget_allocations_path(@budget)
    assert_select "[data-testid='allocation-card'][data-finished-allocation]", count: 1
    assert_select "form[action='#{reopen_allocation_path(@allocation)}']"

    @allocation.update!(deleted_at: Time.current)
    get budget_allocations_path(@budget)
    assert_select "[data-testid='allocation-card']", count: 0
  end

  test "new asks for a category name without offering a category picker" do
    sign_in_as(@user)

    get new_budget_allocation_path(@budget)

    assert_response :success
    assert_select "select[name='allocation[category_id]']", count: 0
    assert_select "select[name='allocation[currency_code]'] option[value='USD'][selected]"
    assert_select "input[name='allocation[category_name_to_create]'][required]"
    assert_select "input[type='radio'][name='allocation[category_icon]']", count: Iconable::CATALOG.size
    assert_select "input[type='radio'][name='allocation[category_colour]']", count: Colourable::CATALOG.size
    assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
  end

  test "creates a category together with its plan item" do
    sign_in_as(@user)

    assert_difference([ "Category.count", "Allocation.count" ], 1) do
      post budget_allocations_path(@budget), params: {
        allocation: {
          category_name_to_create: "Coffee", category_icon: "gift", category_colour: "pink",
          amount: "25.5", currency_code: "USD", rate: "1"
        }
      }
    end

    allocation = @budget.allocations.order(:created_at, :id).last
    assert_redirected_to budget_lenses_path(@budget)
    assert_equal "Coffee", allocation.category.name
    assert_equal "gift", allocation.category.icon
    assert_equal "pink", allocation.category.colour
  end

  test "does not leave a new category behind when its plan item is invalid" do
    sign_in_as(@user)

    assert_no_difference([ "Category.count", "Allocation.count" ]) do
      post budget_allocations_path(@budget), params: {
        allocation: {
          category_name_to_create: "Coffee", amount: "bad", currency_code: "USD", rate: "1"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='allocation[category_name_to_create]'][value='Coffee']"
  end

  test "creates a plan item for a selected category" do
    sign_in_as(@user)
    category = @budget.categories.create!(name: "Emergency savings", icon: "pig-money", colour: "red")

    assert_difference("Allocation.count", 1) do
      post budget_allocations_path(@budget), params: {
        allocation: { category_id: category.id, amount: "100.2500", currency_code: "USD", rate: "1" }
      }
    end

    allocation = @budget.allocations.order(:created_at, :id).last
    assert_redirected_to budget_lenses_path(@budget)
    assert_equal category, allocation.category
    assert_equal BigDecimal("100.2500"), allocation.amount
  end

  test "allows overallocation and returns a warning" do
    sign_in_as(@user)
    category = @budget.categories.create!(name: "Ambitious plan")

    assert_difference("Allocation.count", 1) do
      post budget_allocations_path(@budget), params: {
        allocation: { category_id: category.id, amount: "1500.2501", currency_code: "USD", rate: "1" }
      }
    end

    assert_redirected_to budget_lenses_path(@budget)
    assert_match(/exceed available sources/, flash[:notice])
  end

  test "rejects an unsupported currency and a category from another budget" do
    sign_in_as(@user)

    assert_no_difference("Allocation.count") do
      post budget_allocations_path(@budget), params: {
        allocation: { category_id: categories(:other).id, amount: "1", currency_code: "XXX", rate: "1" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Currency code is not included in the list/
  end

  test "show presents category progress and connected expenses" do
    sign_in_as(@user)

    get allocation_path(@allocation)

    assert_response :success
    assert_select "h1", text: @allocation.category.name
    assert_select "section[data-allocation-summary]", text: /300 USD.*125 USD.*175 USD/m
    assert_select "[data-testid='expense-card']", count: 1
    assert_select "form[action='#{finish_allocation_path(@allocation)}']"
  end

  test "finishes and reopens a plan while category expenses remain attached" do
    sign_in_as(@user)
    expense = expenses(:active)

    assert_no_difference([ "Allocation.count", "Expense.count" ]) do
      patch finish_allocation_path(@allocation)
    end
    assert_predicate @allocation.reload, :finished?
    assert_equal @allocation.category, expense.reload.category

    patch reopen_allocation_path(@allocation)
    assert_predicate @allocation.reload, :active?
  end

  test "soft removes a plan without removing its category or history" do
    sign_in_as(@user)
    category = @allocation.category
    expense = expenses(:active)

    assert_no_difference([ "Allocation.count", "Category.count", "Expense.count" ]) do
      delete allocation_path(@allocation)
    end

    assert_redirected_to budget_lenses_path(@budget)
    assert_predicate @allocation.reload, :deleted?
    assert_equal category, expense.reload.category
  end

  test "cannot access another user's budget or plan" do
    sign_in_as(@user)

    get budget_allocations_path(budgets(:other))
    assert_response :not_found
    get allocation_path(allocations(:other))
    assert_response :not_found
  end
end
