require "test_helper"

class RateInfosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @budget = budgets(:active)
    sign_in_as(@user)
  end

  test "new form offers four currency slots and excludes the budget base" do
    get new_budget_rate_info_path(@budget)

    assert_response :success
    assert_select "body > main[data-anchor='footer']"
    assert_select "h1", text: "Exchange rates"
    assert_select "form[action='#{budget_rate_info_path(@budget)}']" do
      assert_select "[data-form-panel]", count: 0
      assert_select ".currency-picker", count: 4
      assert_select "select[name='rate_info[currency_codes][]']", count: 4
      assert_select "select[name='rate_info[currency_codes][]'] option[value='EUR'][selected]"
      assert_select "select[name='rate_info[currency_codes][]'] option[value='GBP'][selected]"
      assert_select "select[name='rate_info[currency_codes][]'] option[value='USD']", count: 0
    end
    assert_select "a[href='#{budget_lenses_path(@budget)}'][data-action*='history#back']", text: /Cancel/
  end

  test "creates a rate info lens with up to four currencies" do
    assert_difference([ "Lens.count", "RateInfo.count" ], 1) do
      post budget_rate_info_path(@budget), params: {
        rate_info: { currency_codes: [ "EUR", "GBP", "", "JPY" ] }
      }
    end

    assert_redirected_to budget_lenses_path(@budget)
    assert_equal %w[ EUR GBP JPY ], @budget.lenses.find_by!(lensable_type: "RateInfo").lensable.currency_codes
  end

  test "rejects a board with no currencies" do
    assert_no_difference([ "Lens.count", "RateInfo.count" ]) do
      post budget_rate_info_path(@budget), params: { rate_info: { currency_codes: [ "", "", "", "" ] } }
    end

    assert_response :unprocessable_entity
    assert_select "[data-form-errors]", text: /choose at least one currency/
  end

  test "new redirects to edit when the board already exists" do
    @budget.lenses.create!(lensable: RateInfo.new(currency_codes: [ "EUR" ]))

    get new_budget_rate_info_path(@budget)

    assert_redirected_to edit_budget_rate_info_path(@budget)
  end

  test "edit updates the watched currencies" do
    @budget.lenses.create!(lensable: RateInfo.new(currency_codes: [ "EUR" ]))

    get edit_budget_rate_info_path(@budget)
    assert_response :success
    assert_select "body > main[data-anchor='footer']"
    assert_select ".currency-picker", count: 4
    assert_select "select#rate-info-currency-0-select option[value='EUR'][selected]"

    patch budget_rate_info_path(@budget), params: {
      rate_info: { currency_codes: [ "CAD", "JPY", "", "" ] }
    }

    assert_redirected_to budget_lenses_path(@budget)
    assert_equal %w[ CAD JPY ], @budget.lenses.find_by!(lensable_type: "RateInfo").lensable.reload.currency_codes
  end

  test "does not expose another user's rate info" do
    get new_budget_rate_info_path(budgets(:other))
    assert_response :not_found
  end
end
