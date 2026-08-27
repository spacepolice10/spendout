require "test_helper"

class AllocationTest < ActiveSupport::TestCase
  test "used amount is expressed in the allocation currency" do
    allocation = allocations(:active)

    assert_equal BigDecimal("125"), allocation.used_amount

    allocation.update!(currency_code: "EUR", rate: "0.8")
    assert_equal BigDecimal("100"), allocation.used_amount
  end

  test "defaults to a planned allocation" do
    allocation = budgets(:active).allocations.new(
      name: "Groceries",
      amount: 100,
      currency_code: "USD"
    )

    assert allocation.planned?
  end

  test "inherits appearance defaults and uses an independent budget currency" do
    allocation = budgets(:active).allocations.build(name: "Savings", amount: 1, currency_code: "USD")

    assert allocation.valid?
    assert_equal "$", allocation.currency_symbol
    assert_equal "US Dollar", allocation.currency_name
    assert_equal "wallet", allocation.icon
    assert_equal "green", allocation.colour
    assert_includes Allocation.icon_options, [ "Wallet", "wallet" ]
    assert_includes Allocation.icon_options, [ "Food", "burger" ]
    assert_includes Allocation.icon_options, [ "Flowers", "flower" ]
    assert_includes Allocation.icon_options, [ "Jewellery", "diamond" ]
    assert_includes Allocation.icon_options, [ "Pets", "paw" ]
    assert_includes Allocation.icon_options, [ "Subscriptions", "repeat" ]
    assert_includes Allocation.icon_options, [ "Household supplies", "spray" ]
    assert_includes Allocation.colour_options, [ "Green", "green" ]
    assert_includes Allocation.colour_options, [ "Pink", "pink" ]
    assert_includes Allocation.colour_options, [ "Orange", "orange" ]
    assert_includes Allocation.colour_options, [ "Teal", "teal" ]
    assert_includes Allocation.colour_options, [ "Indigo", "indigo" ]
  end

  test "rejects an unsupported currency" do
    allocation = budgets(:active).allocations.build(name: "European trip", amount: 1, currency_code: "XXX")

    assert_not allocation.valid?
    assert allocation.errors.added?(:currency_code, :inclusion, value: "XXX")
  end

  test "allows allocations to exceed total sources" do
    budget = budgets(:active)
    allocation = budget.allocations.build(name: "Ambitious plan", amount: "1500.2501", currency_code: "USD")

    assert allocation.save
    assert budget.overallocated?
    assert_equal BigDecimal("300.0001"), budget.overallocated_by
  end

  test "deleted allocations no longer contribute to totals" do
    budget = budgets(:active)
    allocation = allocations(:active)
    allocation.update!(deleted_at: Time.current)

    assert allocation.deleted?
    assert_equal BigDecimal("0"), budget.allocations_amount_in_base
    assert_not budget.overallocated?
    assert_equal allocation, Allocation.find(allocation.id)
  end

  test "remaining amount never falls below zero" do
    allocation = allocations(:active)

    assert_equal BigDecimal("175"), allocation.remaining_amount

    allocation.update!(amount: 100)
    assert_equal BigDecimal("0"), allocation.remaining_amount
  end

  test "finished allocations are inactive but preserve their facts" do
    allocation = allocations(:active)

    allocation.update!(finished_at: Time.current)

    assert_predicate allocation, :finished?
    assert_not_predicate allocation, :active?
    assert_equal BigDecimal("300"), allocation.amount
    assert_equal BigDecimal("125"), allocation.used_amount
    assert_equal allocation, Allocation.find(allocation.id)
  end
end
