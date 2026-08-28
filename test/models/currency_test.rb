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

  test "places priority currencies first without duplicating them" do
    codes = Currency.options_prioritizing(%w[VND USD VND]).map(&:last)

    assert_equal %w[VND USD], codes.first(2)
    assert_equal Currency.options.size, codes.size
  end

  test "rejects an unknown code" do
    assert_nil Currency.find("XXX")
    assert_raises(ArgumentError) { Currency.find!("XXX") }
  end

  test "finds currencies from countries" do
    assert_equal "VND", Currency.of_country("VN")
    assert_equal "EUR", Currency.of_country("DE")
    assert_equal "EUR", Currency.of_country("BG")
    assert_equal "GBP", Currency.of_country("GB")
    assert_equal "USD", Currency.of_country("US")
    assert_nil Currency.of_country("ZZ")
  end

  test "finds currencies from IANA timezones" do
    assert_equal "VND", Currency.of_timezone("Asia/Ho_Chi_Minh")
    assert_equal "VND", Currency.of_timezone("Asia/Saigon")
    assert_equal "JPY", Currency.of_timezone("Asia/Tokyo")
    assert_equal "EUR", Currency.of_timezone("Europe/Berlin")
    assert_equal "UAH", Currency.of_timezone("Europe/Kiev")
    assert_equal "GBP", Currency.of_timezone("Europe/London")
    assert_equal "USD", Currency.of_timezone("America/New_York")
    assert_nil Currency.of_timezone("Etc/UTC")
    assert_nil Currency.of_timezone("Not/A_Timezone")
  end
end
