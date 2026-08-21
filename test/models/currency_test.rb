require "test_helper"

class CurrencyTest < ActiveSupport::TestCase
  test "finds canonical metadata without persistence" do
    currency = Currency.find!("usd")

    assert_equal "US Dollar", currency[:name]
    assert_equal "840", currency[:numeric_code]
    assert_equal "$", currency[:symbol]
  end

  test "provides the catalog as form options" do
    assert_includes Currency.options, [ "🇺🇸 US Dollar (USD)", "USD" ]
  end

  test "rejects an unknown code" do
    assert_nil Currency.find("XXX")
    assert_raises(ArgumentError) { Currency.find!("XXX") }
  end
end
