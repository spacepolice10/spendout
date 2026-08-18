class Allocation < ApplicationRecord
  include Colourable, Iconable

  belongs_to :budget, inverse_of: :allocations
  belongs_to :source, inverse_of: :allocations

  before_validation :inherit_currency_from_source

  validates :name, presence: true
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :source_belongs_to_budget
  validate :source_is_active
  validate :amount_fits_source, unless: :deleted?

  def save_with_source_capacity
    return save unless source&.persisted?

    source.with_lock { save }
  end

  def currency
    budget.currencies.find { |currency| currency.alphabetic_code == currency_code }
  end

  def deleted?
    deleted_at.present?
  end

  private
    def inherit_currency_from_source
      self.currency_code = source&.currency_code
    end

    def source_belongs_to_budget
      return if source.nil? || budget.nil? || source.budget_id == budget.id

      errors.add(:source, "must belong to this budget")
    end

    def source_is_active
      errors.add(:source, "must be active") if source&.deleted?
    end

    def amount_fits_source
      return if source.nil? || amount.nil? || source.budget_id != budget_id

      available = source.amount - source.allocated_amount(excluding: self)
      errors.add(:amount, "must be less than or equal to #{available.to_s("F")}") if amount > available
    end
end
