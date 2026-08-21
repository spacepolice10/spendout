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
    assert_includes Source.colour_options, [ "Pink", "pink" ]
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
    source = create_secondary_source
    source.update!(deleted_at: Time.current)

    assert source.deleted?
    assert_equal source, Source.find(source.id)
  end

  test "base source cannot be deleted or directly destroyed" do
    source = sources(:active)
    source.deleted_at = Time.current

    assert_not source.save
    assert source.errors.added?(:deleted_at, "cannot delete the base source")

    source.reload

    assert_not source.destroy
    assert source.errors.added?(:base, "source cannot be destroyed")
    assert source.persisted?
  end

  test "resolves currency horizontally within its budget" do
    assert_equal "$", sources(:active).currency_symbol
    assert_equal "US Dollar", sources(:active).currency_name
  end

  test "converts its amount to the budget base currency using a decimal rate" do
    source = budgets(:active).sources.build(amount: "10.25", currency_code: "EUR", rate: "1.2")

    assert_equal BigDecimal("12.3"), source.amount_in_base
  end

  test "requires a positive conversion rate" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "EUR", rate: 0)

    assert_not source.valid?
    assert source.errors.added?(:rate, :greater_than, value: BigDecimal("0"), count: 0)
  end

  test "rejects an unsupported currency" do
    source = budgets(:active).sources.build(amount: 1, currency_code: "XXX")

    assert_not source.valid?
    assert source.errors.added?(:currency_code, :inclusion, value: "XXX")
  end

  test "is not constrained by allocation amounts" do
    source = sources(:active)
    source.amount = BigDecimal("299.9999")

    assert source.valid?
  end

  private
    def create_secondary_source
      budgets(:active).sources.create!(
        name: "Secondary source",
        amount: 100,
        currency_code: "USD",
        icon: "wallet",
        colour: "green"
      )
    end
end
