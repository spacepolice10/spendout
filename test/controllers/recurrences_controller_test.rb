require "test_helper"

class RecurrencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    @category = categories(:active)
    sign_in_as(@user)
  end

  test "creates edits and finishes a recurring expense definition" do
    assert_difference("Recurrence.count", 1) do
      post budget_recurrences_path(@budget), params: {
        recurrence: {
          name: "Internet", category_id: @category.id, amount: 30,
          currency_code: "USD", occurs_on: "2026-08-20", occurrence_period_in_days: 30
        }
      }
    end
    item = @budget.recurrences.order(:created_at, :id).last
    assert_redirected_to budget_lenses_path(@budget)

    patch recurrence_path(item), params: { recurrence: { name: "Fiber", category_id: @category.id } }
    assert_equal "Fiber", item.reload.name

    patch finish_recurrence_path(item)
    assert_not_predicate item.reload, :active?
  end

  test "new can create its first category" do
    @budget.categories.update_all(deleted_at: Time.current)

    get new_budget_recurrence_path(@budget)

    assert_response :success
    assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
    assert_select "form[data-recurrence-form]"
    assert_select "[data-amount-currency-fields]"
    assert_select "select[name='recurrence[currency_code]']"
    assert_select "[data-recurrence-options]"
    assert_select "input[name='recurrence[category_name_to_create]']"
    assert_select "input[type='radio'][name='recurrence[category_icon]']", count: Iconable::CATALOG.size
    assert_select "input[type='radio'][name='recurrence[category_colour]']", count: Colourable::CATALOG.size
    assert_select "dialog#recurrence-category-picker-dialog[closedby='any']"
    assert_select "select[name='recurrence[category_id]']", count: 0
  end

  test "creates a category together with its recurrence" do
    assert_difference([ "Category.count", "Recurrence.count" ], 1) do
      post budget_recurrences_path(@budget), params: {
        recurrence: {
          name: "Coffee beans", category_name_to_create: "Coffee", category_icon: "gift",
          category_colour: "pink", amount: 20,
          currency_code: "USD", occurs_on: "2026-08-20", occurrence_period_in_days: 14
        }
      }
    end

    item = @budget.recurrences.order(:created_at, :id).last
    assert_equal "Coffee", item.category.name
    assert_equal "gift", item.category.icon
    assert_equal "pink", item.category.colour
  end

  test "does not leave a new category behind when its recurrence is invalid" do
    assert_no_difference([ "Category.count", "Recurrence.count" ]) do
      post budget_recurrences_path(@budget), params: {
        recurrence: {
          name: "Coffee beans", category_name_to_create: "Coffee", amount: "bad",
          currency_code: "USD", occurs_on: "2026-08-20", occurrence_period_in_days: 14
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='recurrence[category_name_to_create]'][value='Coffee']"
  end

  test "show presents the recurring payment and a quick expense action" do
    item = @budget.recurrences.create!(
      name: "Internet",
      category: @category,
      amount: 30,
      currency_code: "USD",
      occurs_on: Date.new(2026, 9, 12),
      occurrence_period_in_days: 30
    )

    get recurrence_path(item)

    assert_response :success
    assert_select "h1", text: "Internet"
    assert_select "main", text: /Housing.*\$30.*September 12, 2026/m
    assert_select "a[href='#{new_budget_expense_path(@budget, recurrence_id: item.id)}']", text: "Record expense"
  end
end
