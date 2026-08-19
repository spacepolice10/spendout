require "test_helper"

class AllocationTest < ActiveSupport::TestCase
  test "inherits appearance defaults and uses an independent budget currency" do
    allocation = budgets(:active).allocations.build(name: "Savings", amount: 1, currency_code: "USD")

    assert allocation.valid?
    assert_equal currencies(:active_usd), allocation.currency
    assert_equal "wallet", allocation.icon
    assert_equal "green", allocation.colour
    assert_includes Allocation.icon_options, [ "Wallet", "wallet" ]
    assert_includes Allocation.colour_options, [ "Green", "green" ]
    assert_includes Allocation.colour_options, [ "Pink", "pink" ]
  end

  test "rejects a currency that is not available in its budget" do
    allocation = budgets(:active).allocations.build(name: "European trip", amount: 1, currency_code: "EUR")

    assert_not allocation.valid?
    assert allocation.errors.added?(:currency_code, "must be available in this budget")
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
end
