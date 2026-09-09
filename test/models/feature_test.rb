require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  test "budgets create their menu features" do
    budget = Budget.create!(
      user: users(:two),
      base_currency_code: "USD",
      period_from: Date.current,
      period_to: 1.month.from_now.to_date
    )

    assert_equal Feature::TYPES, budget.features.in_menu_order.pluck(:feature_type)
  end

  test "only expense and income can be favorites" do
    feature = features(:active_laboratory)

    assert_not feature.update(favorite: true)
    assert feature.errors.of_kind?(:favorite, :unsupported)
  end
end
