class Expense < ApplicationRecord
  belongs_to :budget, inverse_of: :expenses
  belongs_to :source, inverse_of: :expenses
  belongs_to :allocation, optional: true, inverse_of: :expenses, autosave: true

  attr_accessor :category_name_to_create

  before_validation :change_default_occurred_on
  before_validation :predefine_currency_and_source_amount

  validates :amount, numericality: { greater_than: 0 }
  validates :source_amount, numericality: { greater_than: 0 }
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :conversion_rate, numericality: { greater_than: 0 }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :occurred_during_budget
  validate :source_belongs_to_budget
  validate :allocation_belongs_to_budget
  validate :source_is_active
  validate :allocation_is_active
  validate :amount_fits_source
  def save_with_source_capacity
    predefine_currency_and_source_amount
    initialize_category_to_create

    return save unless source&.persisted?

    source.with_lock { save }
  end

  def destroy_with_source_lock!
    source.with_lock { destroy! }
  end

  def amount_in_base_currency
    source_amount / source.rate
  end

  def currency_name
    currency_metadata[:name]
  end

  def currency_symbol
    currency_metadata[:symbol]
  end

  private
    def initialize_category_to_create
      return if category_name_to_create.blank? || allocation&.new_record?

      category_icon = CategoryIcon.new(category_name_to_create)

      self.allocation = budget.allocations.build(
        name: category_name_to_create,
        icon: category_icon.matched_name,
        colour: category_icon.matched_colour,
        amount: 0,
        planned: false,
        currency_code: currency_code.presence || source&.currency_code,
        rate: source&.rate && conversion_rate ? source.rate * conversion_rate : source&.rate
      )
    end

    def change_default_occurred_on
      return if occurred_on.present? || budget.nil?

      self.occurred_on = Date.current.clamp(budget.period_from, budget.period_to)
    end

    def predefine_currency_and_source_amount
      return unless source

      self.currency_code ||= source.currency_code

      if currency_code == source.currency_code
        self.conversion_rate = 1
        self.source_amount = amount
      elsif amount.present? && conversion_rate.present? && conversion_rate.positive?
        self.source_amount = (amount / conversion_rate).round(4)
      end
    end

    def currency_metadata
      Currency.find!(currency_code)
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
      errors.add(:allocation, "must be active") if allocation && !allocation.active?
    end

    def amount_fits_source
      return if source.nil? || amount.nil? || source.budget_id != budget_id

      return if source_amount.nil?

      available = source.spendable_amount(excluding: self)
      if source_amount > available
        attribute = currency_code == source.currency_code ? :amount : :source_amount
        errors.add(attribute, "must be less than or equal to #{available.to_s("F")}")
      end
    end

end
