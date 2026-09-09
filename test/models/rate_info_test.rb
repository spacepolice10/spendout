require "test_helper"

class RateInfoTest < ActiveSupport::TestCase
  setup { @budget = budgets(:active) }

  test "keeps one to four unique catalog currencies" do
    rate_info = RateInfo.new(currency_codes: [ " eur ", "GBP", "gbp", "" ])

    assert_equal %w[ EUR GBP ], rate_info.currency_codes
    assert rate_info.valid?
  end

  test "requires at least one currency" do
    rate_info = RateInfo.new(currency_codes: [ "", nil ])

    assert_not rate_info.valid?
    assert rate_info.errors.added?(:currency_codes, :blank)
  end

  test "rejects more than four currencies" do
    rate_info = RateInfo.new(currency_codes: %w[ EUR GBP JPY CAD CHF ])

    assert_not rate_info.valid?
    assert rate_info.errors.added?(:currency_codes, :too_many, count: RateInfo::CAPACITY)
  end

  test "rejects currencies outside the catalog" do
    rate_info = RateInfo.new(currency_codes: [ "XXX" ])

    assert_not rate_info.valid?
    assert rate_info.errors.added?(:currency_codes, :inclusion)
  end

  test "rejects the budget base currency" do
    rate_info = RateInfo.new(currency_codes: [ "USD" ], monitored_against: "USD")

    assert_not rate_info.valid?
    assert rate_info.errors.added?(:currency_codes, :exclusion)
  end

  test "currency options exclude the budget base and prefer wallets" do
    @budget.sources.create!(name: "Dong", amount: 100_000, currency_code: "VND", rate: "25000")
    options = RateInfo.currency_options_for(@budget, selected: [ "CAD" ])

    assert_equal "CAD", options.first.last
    assert_includes options.map(&:last), "VND"
    assert_not_includes options.map(&:last), "USD"
  end
end
