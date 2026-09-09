require "test_helper"

class LensFacadeTest < ActiveSupport::TestCase
  setup do
    @budget = budgets(:active)
    @budget.ensure_builtin_lenses!
    @facade = LensFacade.new(@budget)
  end

  test "reports active capabilities and lab availability" do
    assert_not @facade.active?(:rollover)
    assert @facade.available?(:rollover)

    @budget.lenses.create!(lensable: Rollover.new(
      limit_source: :manual,
      amount: 300,
      currency_code: "USD",
      rate: 1,
      starts_on: @budget.period_from,
      ends_on: @budget.period_to
    ))
    facade = LensFacade.new(@budget)

    assert facade.active?(:rollover)
    assert facade.enabled?(:rollover)
    assert_not facade.available?(:rollover)
    assert_not_includes facade.available_entries.map(&:name), "rollover"
  end

  test "exposes lenses in persisted order" do
    upcoming = @budget.lenses.create!(lensable: UpcomingRecurrences.new)
    upcoming.move!("up")

    assert_equal @budget.lenses.positioned.pluck(:id), LensFacade.new(@budget).ordered.pluck(:id)
  end

end
