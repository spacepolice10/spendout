require "test_helper"

class FeaturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    budgets(:active).ensure_features!
    @feature = budgets(:active).features.find_by!(feature_type: "new_expense")
  end

  test "favorites a feature" do
    patch favorite_budget_feature_path(budgets(:active), @feature)

    assert_redirected_to root_path
    assert @feature.reload.favorite?
  end

  test "unfavorites a feature" do
    @feature.update!(favorite: true)

    patch favorite_budget_feature_path(budgets(:active), @feature)

    assert_not @feature.reload.favorite?
  end

  test "cannot change another user's feature" do
    budgets(:other).ensure_features!
    other_feature = budgets(:other).features.find_by!(feature_type: "new_expense")

    patch favorite_budget_feature_path(budgets(:other), other_feature)

    assert_response :not_found
  end
end
