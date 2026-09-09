require "test_helper"

class AllocationTest < ActiveSupport::TestCase
  test "belongs to a budget category and delegates its presentation" do
    allocation = allocations(:active)

    assert_equal categories(:active), allocation.category
    assert_equal "Housing", allocation.name
    assert_equal "home", allocation.icon
    assert_equal "yellow", allocation.colour
  end

  test "used amount is expressed in the allocation currency" do
    allocation = allocations(:active)

    assert_equal BigDecimal("125"), allocation.used_amount
    allocation.update!(currency_code: "EUR", rate: "0.8")
    assert_equal BigDecimal("100"), allocation.used_amount
  end

  test "allows at most one plan item for a category" do
    duplicate = budgets(:active).allocations.new(
      category: categories(:active), amount: 100, currency_code: "USD"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.added?(:category_id, :taken, value: categories(:active).id)
  end

  test "rejects a category from another budget" do
    allocation = budgets(:active).allocations.new(
      category: categories(:other), amount: 100, currency_code: "USD"
    )

    assert_not allocation.valid?
    assert allocation.errors.added?(:category, :wrong_budget)
  end

  test "uses an independent supported currency" do
    category = budgets(:active).categories.create!(name: "Trip")
    allocation = budgets(:active).allocations.new(category:, amount: 1, currency_code: "EUR", rate: "0.8")

    assert allocation.valid?
    assert_equal "€", allocation.currency_symbol
    assert_equal "Euro", allocation.currency_name

    allocation.currency_code = "XXX"
    assert_not allocation.valid?
  end

  test "allows plans to exceed total sources" do
    budget = budgets(:active)
    category = budget.categories.create!(name: "Ambitious")
    allocation = budget.allocations.create!(category:, amount: "1500.2501", currency_code: "USD")

    assert allocation.persisted?
    assert budget.overallocated?
    assert_equal BigDecimal("300.0001"), budget.overallocated_by
  end

  test "remaining amount never falls below zero" do
    allocation = allocations(:active)

    assert_equal BigDecimal("175"), allocation.remaining_amount
    allocation.update!(amount: 100)
    assert_equal BigDecimal("0"), allocation.remaining_amount
  end

  test "finished and deleted plans preserve facts but stop reserving money" do
    budget = budgets(:active)
    allocation = allocations(:active)

    allocation.update!(finished_at: Time.current)
    assert_predicate allocation, :finished?
    assert_not_predicate allocation, :active?
    assert_equal BigDecimal("125"), budget.allocations_amount_in_base

    allocation.update!(deleted_at: Time.current)
    assert_predicate allocation, :deleted?
    assert_equal BigDecimal("0"), budget.allocations_amount_in_base
    assert_equal allocation, Allocation.find(allocation.id)
  end
end
