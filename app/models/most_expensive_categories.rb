class MostExpensiveCategories < ApplicationRecord
  Record = Data.define(:name, :icon, :colour, :deleted, :amount)
  Snapshot = Data.define(:starts_on, :ends_on, :currency_code, :records)

  has_one :lens, as: :lensable
  validates :starts_on, presence: true

  def snapshot(budget:, on: Date.current)
    records = budget.expenses.includes(:source, :category).where(occurred_on: starts_on..on)
      .group_by(&:category).map do |category, expenses|
        Record.new(name: category.name, icon: category.icon, colour: category.colour,
          deleted: category.deleted?, amount: expenses.sum(BigDecimal("0"), &:amount_in_base_currency))
      end.sort_by { |record| -record.amount }.first(3)
    Snapshot.new(starts_on:, ends_on: on, currency_code: budget.base_currency_code, records:)
  end
end
