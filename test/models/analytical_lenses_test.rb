require "test_helper"

class AnalyticalLensesTest < ActiveSupport::TestCase
  setup do
    @budget = budgets(:active)
  end

  test "cybercat returns a three-message budget check-in" do
    snapshot = Cybercat.new.snapshot(budget: @budget)

    assert_equal 3, snapshot.messages.size
    assert_includes %i[morning afternoon evening], snapshot.time_of_day
    assert_includes %i[remaining_today over_pace available], snapshot.messages.second.key
    assert_includes %i[spent_today quiet_today], snapshot.messages.third.key
  end

  test "cybercat features budget pace in the morning and today's activity later" do
    travel_to Time.zone.local(2026, 9, 8, 9) do
      snapshot = Cybercat.new.snapshot(budget: @budget)

      assert_includes %i[remaining_today over_pace available], snapshot.featured_message.key
    end

    travel_to Time.zone.local(2026, 9, 8, 15) do
      snapshot = Cybercat.new.snapshot(budget: @budget)

      assert_includes %i[spent_today quiet_today], snapshot.featured_message.key
    end
  end

  test "cybercat guides a new budget to add its first source" do
    budget = @budget.user.budgets.build(
      starts_date: Date.current,
      ends_date: Date.current + 1.month,
      base_currency_code: "USD"
    )

    snapshot = Cybercat.new.snapshot(budget: budget)

    assert_equal :add_first_source, snapshot.messages.second.key
    assert_empty snapshot.messages.second.options
  end

  test "cybercat guides a funded budget to add its first plan item" do
    @budget.allocations.delete_all

    snapshot = Cybercat.new.snapshot(budget: @budget)

    assert_equal :add_first_allocation, snapshot.messages.second.key
    assert_empty snapshot.messages.second.options
  end

  test "rate info converts EUR reference rates into the budget base quote" do
    CurrencyReference.preserve(
      "reference_date" => "2026-08-20",
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    )

    snapshot = RateInfo.new(currency_codes: [ "VND" ]).snapshot(
      budget: @budget, on: Date.new(2026, 8, 20)
    )

    assert snapshot.available
    assert_equal Date.new(2026, 8, 20), snapshot.reference_date
    assert_equal BigDecimal("25000"), snapshot.rates.first.rate
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "rate info is unavailable when the shared reference is stale" do
    CurrencyReference.preserve(
      "reference_date" => "2026-08-20",
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" }
    )

    snapshot = RateInfo.new(currency_codes: [ "VND" ]).snapshot(
      budget: @budget, on: Date.new(2026, 8, 28)
    )

    assert_not snapshot.available
    assert_empty snapshot.rates
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "rate info is unavailable when none of its configured currencies has a current quote" do
    CurrencyReference.preserve(
      "reference_date" => "2026-08-28",
      "rates" => { "EUR" => "1", "USD" => "1.2", "VND" => "30000" },
      "reference_dates" => { "EUR" => "2026-08-28", "USD" => "2026-08-28", "VND" => "2026-08-20" }
    )

    snapshot = RateInfo.new(currency_codes: [ "VND" ]).snapshot(
      budget: @budget, on: Date.new(2026, 8, 28)
    )

    assert_not snapshot.available
    assert_empty snapshot.rates
  ensure
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end
end
