require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  test "finds canonical metadata without persistence" do
    currency = Currency.find!("usd")

    assert_equal "US Dollar", currency[:name]
    assert_equal "840", currency[:numeric_code]
    assert_equal "$", currency[:symbol]
  end

  test "provides the catalog as form options" do
    assert_includes Currency.options, [ "USD US Dollar, 🇺🇸", "USD" ]
  end

  test "exposes popular currencies" do
    assert_equal %w[USD EUR GBP], Currency::POPULAR_CURRENCIES
  end

  test "provides popular currencies as form options" do
    assert_equal [
      [ "USD US Dollar, 🇺🇸", "USD" ],
      [ "EUR Euro, 🇪🇺", "EUR" ],
      [ "GBP Pound Sterling, 🇬🇧", "GBP" ]
    ], Currency.popular_options
  end

  test "rejects an unknown code" do
    assert_nil Currency.find("XXX")
    assert_raises(ArgumentError) { Currency.find!("XXX") }
  end

  test "finds currencies from countries" do
    assert_equal "VND", Currency.currency_code_for_country("VN")
    assert_equal "EUR", Currency.currency_code_for_country("DE")
    assert_equal "EUR", Currency.currency_code_for_country("BG")
    assert_equal "GBP", Currency.currency_code_for_country("GB")
    assert_equal "USD", Currency.currency_code_for_country("US")
    assert_nil Currency.currency_code_for_country("ZZ")
  end

  test "finds currencies from IANA timezones" do
    assert_equal "VND", Currency.currency_code_for_timezone("Asia/Ho_Chi_Minh")
    assert_equal "VND", Currency.currency_code_for_timezone("Asia/Saigon")
    assert_equal "JPY", Currency.currency_code_for_timezone("Asia/Tokyo")
    assert_equal "EUR", Currency.currency_code_for_timezone("Europe/Berlin")
    assert_equal "UAH", Currency.currency_code_for_timezone("Europe/Kiev")
    assert_equal "GBP", Currency.currency_code_for_timezone("Europe/London")
    assert_equal "USD", Currency.currency_code_for_timezone("America/New_York")
    assert_nil Currency.currency_code_for_timezone("Etc/UTC")
    assert_nil Currency.currency_code_for_timezone("Not/A_Timezone")
  end
end
