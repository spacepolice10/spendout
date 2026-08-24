require "test_helper"

class CurrencyReferenceRatesTest < ActiveSupport::TestCase
  setup do
    Rails.cache.delete(CurrencyReferenceRates::CACHE_KEY)
  end

  teardown do
    Rails.cache.delete(CurrencyReferenceRates::CACHE_KEY)
  end

  test "derives direct inverse and cross rates in selected units per base unit" do
    CurrencyReferenceRates.write(payload(
      "EUR" => "1", "USD" => "1.2", "VND" => "30000", "GBP" => "0.8"
    ))

    eur = CurrencyReferenceRates.for("EUR", today: Date.new(2026, 8, 24))
    assert_equal "1.2", eur.rates.fetch("USD")

    usd = CurrencyReferenceRates.for("USD", today: Date.new(2026, 8, 24))
    assert_equal "0.833333333333", usd.rates.fetch("EUR")
    assert_equal "25000", usd.rates.fetch("VND")
    assert_equal "0.666666666667", usd.rates.fetch("GBP")
    assert_equal Date.new(2026, 8, 24), usd.reference_date
    assert_equal "Frankfurter", usd.provider
  end

  test "returns no suggestions for missing bases or stale future and malformed data" do
    CurrencyReferenceRates.write(payload("EUR" => "1", "USD" => "1.2"))
    assert_not CurrencyReferenceRates.for("VND", today: Date.new(2026, 8, 24)).available?
    assert CurrencyReferenceRates.for("USD", today: Date.new(2026, 8, 31)).available?
    assert_not CurrencyReferenceRates.for("USD", today: Date.new(2026, 9, 1)).available?
    assert_not CurrencyReferenceRates.for("USD", today: Date.new(2026, 8, 23)).available?

    Rails.cache.write(CurrencyReferenceRates::CACHE_KEY, { "rates" => { "EUR" => "nope" } })
    assert_not CurrencyReferenceRates.for("EUR").available?
  end

  private
    def payload(rates)
      {
        "provider" => "Frankfurter",
        "reference_date" => "2026-08-24",
        "fetched_at" => "2026-08-24T18:00:00Z",
        "rates" => rates
      }
    end
end
