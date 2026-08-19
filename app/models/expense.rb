class Expense < ApplicationRecord
  belongs_to :budget, inverse_of: :expenses
  belongs_to :source, inverse_of: :expenses
  belongs_to :allocation, optional: true, inverse_of: :expenses

  before_validation :set_default_occurred_on
  before_validation :inherit_currency_from_source

  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :amount, numericality: { greater_than: 0 }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :occurred_during_budget
  validate :source_belongs_to_budget
  validate :source_is_active
  validate :allocation_belongs_to_budget
  validate :allocation_is_active
  validate :amount_fits_source

  def save_with_source_capacity
    return save unless source&.persisted?

    source.with_lock { save }
  end

  def destroy_with_source_lock!
    source.with_lock { destroy! }
  end

  def currency
    budget.currencies.find { |currency| currency.alphabetic_code == currency_code }
  end

  private
    def set_default_occurred_on
      return if occurred_on.present? || budget.nil?

      self.occurred_on = Date.current.clamp(budget.period_from, budget.period_to)
    end

    def inherit_currency_from_source
      self.currency_code = source&.currency_code
    end

    def occurred_during_budget
      return if occurred_on.blank? || budget.nil?
      return if occurred_on.between?(budget.period_from, budget.period_to)

      errors.add(:occurred_on, "must be within the budget period")
    end

    def source_belongs_to_budget
      return if source.nil? || budget.nil? || source.budget_id == budget.id

      errors.add(:source, "must belong to this budget")
    end

    def source_is_active
      errors.add(:source, "must be active") if source&.deleted?
    end

    def allocation_belongs_to_budget
      return if allocation.nil? || budget.nil? || allocation.budget_id == budget.id

      errors.add(:allocation, "must belong to this budget")
    end

    def allocation_is_active
      errors.add(:allocation, "must be active") if allocation&.deleted?
    end

    def amount_fits_source
      return if source.nil? || amount.nil? || source.budget_id != budget_id

      available = source.spendable_amount(excluding: self)
      errors.add(:amount, "must be less than or equal to #{available.to_s("F")}") if amount > available
    end
end
