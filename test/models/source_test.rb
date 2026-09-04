require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "uses a numbered design enum" do
    assert_equal({
      "americat_express" => 0,
      "mastercat" => 1,
      "meowisa" => 2,
      "unipaw" => 3,
      "cash" => 4,
      "bank" => 5,
      "savings" => 6,
      "digital_wallet" => 7
    }, Source.designs)
  end

  test "uses the cat-free card as the default design" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD")

    assert source.americat_express?
    assert_equal "No cat", source.design_name
    assert_nil source.design_face
    assert_equal "cat-face-friendly-v2.png", Source::DESIGNS.fetch("mastercat").fetch(:face)
  end

  test "offers every source design as a labelled form option" do
    assert_equal [
      [ "No cat", "americat_express" ],
      [ "Friendly", "mastercat" ],
      [ "Sleepy", "meowisa" ],
      [ "Curious", "unipaw" ],
      [ "Grumpy", "cash" ]
    ], Source.design_options
  end

  test "rejects an unsupported design" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD", design: :unknown)

    assert_not source.valid?
    assert source.errors.added?(:design, :inclusion, value: :unknown)
  end

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
    assert_includes Source.colour_options, [ "Cyan", "cyan" ]
    assert_includes Source.colour_options, [ "Coral", "coral" ]
  end

  test "uses fixed icon and colour defaults" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD")

    assert_equal "wallet", source.icon
    assert_equal "green", source.colour
  end

  test "accepts every supported icon and colour" do
    Source.icon_catalog.each_key do |icon|
      assert budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD", icon: icon).valid?
    end

    Source.colour_catalog.each_key do |colour|
      assert budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD", colour: colour).valid?
    end
  end

  test "rejects unsupported or blank icons and colours" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD", icon: "unknown", colour: "unknown")

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
    source = budgets(:active).sources.build(name: "Test source", amount: "0.1234", currency_code: "USD")

    assert source.valid?
    assert_equal BigDecimal("0.1234"), source.amount
    assert_equal "Test source", source.name
    assert_equal "wallet", source.icon
    assert_equal "green", source.colour
  end

  test "rejects negative amounts" do
    source = budgets(:active).sources.build(name: "Test source", amount: -0.0001, currency_code: "USD")

    assert_not source.valid?
    assert source.errors.added?(:amount, :greater_than_or_equal_to, value: BigDecimal("-0.0001"), count: 0)
  end

  test "reports deletion without hiding the record" do
    source = create_secondary_source
    source.update!(deleted_at: Time.current)

    assert source.deleted?
    assert_equal source, Source.find(source.id)
  end

  test "cannot be destroyed directly" do
    source = sources(:active)

    assert_not source.destroy
    assert source.errors.added?(:base, "source cannot be destroyed directly")
    assert source.persisted?
  end

  test "source can be marked as deleted" do
    source = sources(:active)

    assert source.update(deleted_at: Time.current)
    assert source.deleted?
  end

  test "resolves currency horizontally within its budget" do
    assert_equal "$", sources(:active).currency_symbol
    assert_equal "US Dollar", sources(:active).currency_name
  end

  test "converts its amount using selected-currency units per base-currency unit" do
    source = budgets(:active).sources.build(name: "Test source", amount: "26600", currency_code: "VND", rate: "26600")

    assert_equal BigDecimal("1"), source.amount_in_base_currency
  end

  test "forces the base currency rate to one" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "USD", rate: "26600")

    assert source.valid?
    assert_equal BigDecimal("1"), source.rate
  end

  test "requires a positive conversion rate" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "EUR", rate: 0)

    assert_not source.valid?
    assert source.errors.added?(:rate, :greater_than, value: BigDecimal("0"), count: 0)
  end

  test "rejects an unsupported currency" do
    source = budgets(:active).sources.build(name: "Test source", amount: 1, currency_code: "XXX")

    assert_not source.valid?
    assert source.errors.added?(:currency_code, :inclusion, value: "XXX")
  end

  test "currency is immutable while amount remains changeable" do
    source = sources(:active)

    assert source.update(amount: source.amount + 1)
    assert_not source.update(currency_code: "EUR")
    assert source.errors.added?(:currency_code, "cannot be changed")
  end

  test "rate is immutable" do
    source = budgets(:active).sources.create!(name: "Euros", amount: 100, currency_code: "EUR", rate: "0.8")

    assert_not source.update(rate: "0.9")
    assert source.errors.added?(:rate, "cannot be changed")
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
