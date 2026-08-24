class Expense < ApplicationRecord
  include Currencyable

  belongs_to :budget, inverse_of: :expenses
  belongs_to :source, inverse_of: :expenses
  belongs_to :allocation, optional: true, inverse_of: :expenses, autosave: true

  attr_accessor :category_name_to_create

  before_validation :change_default_occurred_on
  before_validation :set_currency_and_source_snapshot

  validates :amount, numericality: { greater_than: 0 }
  validates :source_amount, numericality: { greater_than: 0 }
  validates :source_currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :source_rate, :conversion_rate, numericality: { greater_than: 0 }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :occurred_during_budget
  validate :source_belongs_to_budget
  validate :allocation_belongs_to_budget
  validate :source_is_active
  validate :allocation_is_active
  validate :amount_fits_source
  validate :monetary_facts_cannot_change, on: :update

  def save_with_source_capacity
    set_currency_and_source_snapshot
    initialize_category_to_create

    return save unless source&.persisted?

    source.with_lock { save }
  end

  def destroy_with_source_lock!
    source.with_lock { destroy! }
  end

  private
    def initialize_category_to_create
      return if category_name_to_create.blank? || allocation&.new_record?

      self.allocation = budget.allocations.build(
        name: category_name_to_create,
        amount: 0,
        planned: false,
        currency_code: currency_code.presence || source&.currency_code,
        rate: rate.presence || source&.rate
      )
    end

    def change_default_occurred_on
      return if occurred_on.present? || budget.nil?

      self.occurred_on = Date.current.clamp(budget.period_from, budget.period_to)
    end

    def set_currency_and_source_snapshot
      return unless source

      self.currency_code ||= source.currency_code
      self.source_currency_code = source.currency_code
      self.source_rate = source.rate

      if currency_code == source_currency_code
        self.conversion_rate = 1
        self.source_amount = amount
      elsif amount.present? && conversion_rate.present? && conversion_rate.positive?
        self.source_amount = (amount / conversion_rate).round(4)
      end

      self.rate = source_rate * conversion_rate if source_rate.present? && conversion_rate.present?
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

    def source_is_active
      errors.add(:source, "must be active") if source&.deleted?
    end

    def allocation_is_active
      errors.add(:allocation, "must be active") if allocation&.deleted?
    end

    def amount_fits_source
      return if source.nil? || amount.nil? || source.budget_id != budget_id

      return if source_amount.nil?

      available = source.spendable_amount(excluding: self)
      if source_amount > available
        attribute = currency_code == source_currency_code ? :amount : :source_amount
        errors.add(attribute, "must be less than or equal to #{available.to_s("F")}")
      end
    end

    def monetary_facts_cannot_change
      attributes = %w[
        amount currency_code rate source_id source_amount source_currency_code source_rate conversion_rate
      ]
      errors.add(:base, "expense monetary facts cannot be changed") if attributes.any? { |attribute| will_save_change_to_attribute?(attribute) }
    end
end
