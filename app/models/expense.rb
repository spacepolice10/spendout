class Expense < ApplicationRecord
  include Currencyable

  belongs_to :budget, inverse_of: :expenses
  belongs_to :source, inverse_of: :expenses
  belongs_to :allocation, optional: true, inverse_of: :expenses, autosave: true

  attr_accessor :category_name_to_create

  before_validation :set_default_occurred_on
  before_validation :inherit_currency_from_source

  validates :amount, numericality: { greater_than: 0 }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :occurred_during_budget
  validate :source_belongs_to_budget
  validate :allocation_belongs_to_budget
  validate :allocation_is_active
  validate :amount_fits_source

  def save_with_source_capacity
    build_category_to_create

    return save unless source&.persisted?

    source.with_lock { save }
  end

  def destroy_with_source_lock!
    source.with_lock { destroy! }
  end

  private
    def build_category_to_create
      return if category_name_to_create.blank? || allocation&.new_record?

      self.allocation = budget.allocations.build(
        name: category_name_to_create,
        amount: 0,
        planned: false,
        currency_code: source&.currency_code,
        rate: source&.rate
      )
    end

    def set_default_occurred_on
      return if occurred_on.present? || budget.nil?

      self.occurred_on = Date.current.clamp(budget.period_from, budget.period_to)
    end

    def inherit_currency_from_source
      self.currency_code = source&.currency_code
      self.rate = source&.rate
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
