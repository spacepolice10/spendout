require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "icon and colour catalogs are frozen" do
    assert Source.icon_catalog.frozen?
    assert Source.icon_catalog.keys.all?(&:frozen?)
    assert Source.icon_catalog.values.all?(&:frozen?)
    assert Source.colour_catalog.frozen?
    assert Source.colour_catalog.keys.all?(&:frozen?)
    assert Source.colour_catalog.values.all?(&:frozen?)
  end

  test "icon and colour options use public label and value shapes" do
    assert_includes Source.icon_options, [ "Credit card", "credit-card" ]
    assert_includes Source.colour_options, [ "Green", "green" ]
  end

  test "uses fixed icon and colour defaults" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "USD")

    assert_equal "wallet", source.icon
    assert_equal "green", source.colour
  end

  test "accepts every supported icon and colour" do
    Source.icon_catalog.each_key do |icon|
      assert budgets(:active).sources.build(amount: 1, currency_code: "USD", icon: icon).valid?
    end

    Source.colour_catalog.each_key do |colour|
      assert budgets(:active).sources.build(amount: 1, currency_code: "USD", colour: colour).valid?
    end
  end

  test "rejects unsupported or blank icons and colours" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "USD", icon: "unknown", colour: "unknown")

    assert_not source.valid?
    assert source.errors.added?(:icon, :inclusion, value: "unknown")
    assert source.errors.added?(:colour, :inclusion, value: "unknown")

    source.icon = ""
    source.colour = ""

    assert_not source.valid?
    assert source.errors.added?(:icon, :inclusion, value: "")
    assert source.errors.added?(:colour, :inclusion, value: "")
  end

  test "allows zero and preserves four decimal places" do
    source = budgets(:active).sources.build(amount: "0.1234", currency_code: "USD")

    assert source.valid?
    assert_equal BigDecimal("0.1234"), source.amount
    assert_equal "Main source", source.name
    assert_equal "wallet", source.icon
    assert_equal "green", source.colour
  end

  test "rejects negative amounts" do
    source = budgets(:active).sources.build(amount: -0.0001, currency_code: "USD")

    assert_not source.valid?
    assert source.errors.added?(:amount, :greater_than_or_equal_to, value: BigDecimal("-0.0001"), count: 0)
  end

  test "reports deletion without hiding the record" do
    source = sources(:active)
    source.update!(deleted_at: Time.current)

    assert source.deleted?
    assert_equal source, Source.find(source.id)
  end

  test "resolves currency horizontally within its budget" do
    assert_equal currencies(:active_usd), sources(:active).currency
  end

  test "rejects a currency that is not available in its budget" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "EUR")

    assert_not source.valid?
    assert source.errors.added?(:currency_code, "must be available in this budget")
  end
end
