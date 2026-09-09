require "test_helper"

class RecentRecordsTest < ActiveSupport::TestCase
  setup { @budget = budgets(:active) }

  test "lists incomes and expenses together in chronological order" do
    income = @budget.incomes.create!(source: sources(:active), source_name: "Salary", amount: 80,
      currency_code: "USD", occurred_on: Date.new(2026, 8, 20))
    records = @budget.records.where(occurred_on: ..Date.new(2026, 8, 21)).chronological

    snapshot = RecentRecords.new.snapshot(budget: @budget, records:, on: Date.new(2026, 8, 21))

    assert_equal [ income.record, records(:active) ], snapshot.records
    assert_includes snapshot.records_by_date.fetch(Date.new(2026, 8, 20)).map(&:recordable), income
    assert_includes snapshot.records_by_date.fetch(Date.new(2026, 8, 19)).map(&:recordable), expenses(:active)
  end

  test "marks unusual days and repeated categories over plan" do
    category = @budget.categories.create!(name: "Coffee", icon: "coffee", colour: "yellow")
    @budget.allocations.create!(category:, amount: 10, currency_code: "USD", rate: 1)
    2.times do |index|
      @budget.expenses.create!(source: sources(:active), category:, amount: 6,
        occurred_on: Date.new(2026, 8, 20) + index.days)
    end
    records = @budget.records.where(occurred_on: ..Date.new(2026, 8, 21)).chronological

    snapshot = RecentRecords.new.snapshot(budget: @budget, records:, on: Date.new(2026, 8, 21))
    insight = snapshot.insights_by_date.fetch(Date.new(2026, 8, 21))

    assert_equal "Coffee", insight.plan_breaks.first.category.name
    assert_equal 2, insight.plan_breaks.first.occurrences
    assert_equal BigDecimal("12"), insight.plan_breaks.first.spent
    assert snapshot.insights_by_date.fetch(Date.new(2026, 8, 19)).unusual_multiple
  end
end
