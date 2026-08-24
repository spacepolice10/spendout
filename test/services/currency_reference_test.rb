require "test_helper"

class CurrencyReferenceTest < ActiveSupport::TestCase
  setup do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  teardown do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "returns direct inverse and cross rates in requested units per source unit" do
    CurrencyReference.preserve(payload(
      "EUR" => "1", "USD" => "1.2", "VND" => "30000", "GBP" => "0.8"
    ))

    assert_equal "1.2", CurrencyReference.request_rate("EUR", "USD", today: Date.new(2026, 8, 24))
    assert_equal "0.833333333333", CurrencyReference.request_rate("USD", "EUR", today: Date.new(2026, 8, 24))
    assert_equal "25000", CurrencyReference.request_rate("USD", "VND", today: Date.new(2026, 8, 24))
    assert_equal "0.666666666667", CurrencyReference.request_rate("USD", "GBP", today: Date.new(2026, 8, 24))
    assert_equal "1", CurrencyReference.request_rate("USD", "USD", today: Date.new(2026, 8, 24))
  end

  test "returns the complete table normalized against the requested currency" do
    CurrencyReference.preserve(payload(
      "EUR" => "1", "USD" => "1.2", "VND" => "30000", "GBP" => "0.8"
    ))

    assert_equal({
      "USD" => "1",
      "EUR" => "0.833333333333",
      "VND" => "25000",
      "GBP" => "0.666666666667"
    }, CurrencyReference.rates_against("USD", today: Date.new(2026, 8, 24)))
  end

  test "returns nil for missing currencies or stale future and malformed metadata" do
    CurrencyReference.preserve(payload("EUR" => "1", "USD" => "1.2"))
    assert_nil CurrencyReference.request_rate("VND", "USD", today: Date.new(2026, 8, 24))
    assert_equal "0.833333333333", CurrencyReference.request_rate("USD", "EUR", today: Date.new(2026, 8, 31))
    assert_nil CurrencyReference.request_rate("USD", "EUR", today: Date.new(2026, 9, 1))
    assert_nil CurrencyReference.request_rate("USD", "EUR", today: Date.new(2026, 8, 23))
    assert_empty CurrencyReference.rates_against("USD", today: Date.new(2026, 8, 23))

    Rails.cache.write(CurrencyReference::CACHE_KEY, { "rates" => { "EUR" => "nope" } })
    assert_nil CurrencyReference.request_rate("EUR", "USD")
  end

  private
    def payload(rates)
      {
        "reference_date" => "2026-08-24",
        "rates" => rates
      }
    end
end
