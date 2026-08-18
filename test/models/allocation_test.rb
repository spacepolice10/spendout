require "test_helper"

class AllocationTest < ActiveSupport::TestCase
  test "inherits appearance defaults and source currency" do
    allocation = budgets(:active).allocations.build(
      source: sources(:active),
      name: "Savings",
      amount: 1
    )

    assert allocation.valid?
    assert_equal "USD", allocation.currency_code
    assert_equal currencies(:active_usd), allocation.currency
    assert_equal "wallet", allocation.icon
    assert_equal "green", allocation.colour
    assert_includes Allocation.icon_options, [ "Wallet", "wallet" ]
    assert_includes Allocation.colour_options, [ "Green", "green" ]
  end

  test "allows active allocations exactly up to source capacity" do
    source = sources(:active)
    allocation = source.budget.allocations.build(
      source: source,
      name: "Remaining balance",
      amount: BigDecimal("1200.2500")
    )

    assert allocation.save_with_source_capacity
    assert_equal BigDecimal("1500.2500"), source.allocated_amount
    assert_equal BigDecimal("0"), source.available_amount
  end

  test "rejects aggregate allocations over source capacity" do
    source = sources(:active)
    allocation = source.budget.allocations.build(
      source: source,
      name: "Too much",
      amount: BigDecimal("1200.2501")
    )

    assert_not allocation.save_with_source_capacity
    assert allocation.errors.added?(:amount, "must be less than or equal to 1200.25")
    assert_not allocation.persisted?
  end

  test "checks source capacity in native currency regardless of its conversion rate" do
    budget = budgets(:active)
    budget.currencies.create!(alphabetic_code: "EUR", rate: "100")
    source = budget.sources.create!(
      name: "Euros",
      amount: 10,
      currency_code: "EUR",
      icon: "wallet",
      colour: "green"
    )

    allocation = budget.allocations.build(source: source, name: "Native amount", amount: "10.0001")

    assert_not allocation.save_with_source_capacity
    assert allocation.errors.added?(:amount, "must be less than or equal to 10.0")
  end

  test "deleted allocations release source capacity" do
    source = sources(:active)
    allocations(:active).update!(deleted_at: Time.current)

    assert_equal BigDecimal("0"), source.allocated_amount
    assert_equal BigDecimal("1500.2500"), source.available_amount
  end

  test "requires an active source from the same budget" do
    allocation = budgets(:active).allocations.build(
      source: sources(:other),
      name: "Wrong budget",
      amount: 1
    )

    assert_not allocation.valid?
    assert allocation.errors.added?(:source, "must belong to this budget")

    source = budgets(:active).sources.create!(
      name: "Inactive source",
      amount: 10,
      currency_code: "USD",
      icon: "wallet",
      colour: "green"
    )
    source.update!(deleted_at: Time.current)
    allocation.source = source

    assert_not allocation.valid?
    assert allocation.errors.added?(:source, "must be active")
  end

  test "reports deletion without hiding the record" do
    allocation = allocations(:active)
    allocation.update!(deleted_at: Time.current)

    assert allocation.deleted?
    assert_equal allocation, Allocation.find(allocation.id)
  end
end
