class Rollover < ApplicationRecord
  include Currencyable

  Snapshot = Data.define(:date, :currency_code, :period_limit, :available_today,
    :remaining_today, :percentage_remaining, :expenses_today)

  has_one :lens, as: :lensable

  def budget = lens&.budget

  enum :limit_source, { manual: 0, budget: 1 }, default: :budget, validate: true

  validates :amount, numericality: { greater_than_or_equal_to: 0 }, if: :manual?
  validates :opening_amount, numericality: { greater_than_or_equal_to: 0 }, if: :budget?
  validates :starts_on, :ends_on, presence: true
  validate :period_is_ordered

  def snapshot(budget:, on: Date.current)
    return unless starts_on <= on && on <= ends_on

    limit = manual? ? amount_in_base_currency : [ opening_amount - budget.allocations_amount_in_base, BigDecimal("0") ].max
    expenses = discretionary_expenses(budget).where(occurred_on: starts_on..on)
    spent = expenses.sum(BigDecimal("0"), &:amount_in_base_currency)
    today = expenses.select { |expense| expense.occurred_on == on }.sum(BigDecimal("0"), &:amount_in_base_currency)
    available = limit / period_days * days_elapsed(on) - (spent - today)
    remaining = [ available - today, BigDecimal("0") ].max
    percentage = available.positive? ? [ remaining / available * 100, BigDecimal("100") ].min : BigDecimal("0")

    Snapshot.new(date: on, currency_code: budget.base_currency_code, period_limit: limit,
      available_today: available, remaining_today: remaining,
      percentage_remaining: percentage, expenses_today: today)
  end

  private
    def discretionary_expenses(budget)
      scope = budget.expenses.includes(:source)
      manual? ? scope : scope.where.not(category_id: budget.allocations.select(:category_id))
    end

    def period_days = (ends_on - starts_on + 1).to_i
    def days_elapsed(on) = (on - starts_on + 1).to_i

    def period_is_ordered
      errors.add(:ends_on, :before_starts_on) if starts_on && ends_on && ends_on < starts_on
    end
end
