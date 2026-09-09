class Income < ApplicationRecord
  include Recordable

  belongs_to :budget, inverse_of: :incomes
  belongs_to :source, inverse_of: :incomes

  before_validation :predefine_currency_and_source_amount

  validates :source_name, :occurred_on, presence: true
  validates :amount, :source_amount, :conversion_rate, numericality: { greater_than: 0 }
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :occurred_during_budget
  validate :source_belongs_to_budget
  validate :source_is_active
  validate :prevent_mutation, on: :update

  def amount_in_base_currency = source_amount / source.rate

  def destroy_with_source_lock
    source.with_lock do
      if source.spendable_amount - source_amount < 0
        errors.add(:base, :would_overdraw)
        false
      else
        destroy
      end
    end
  end

  private
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

    def occurred_during_budget
      errors.add(:occurred_on, :outside_budget_period) if occurred_on && budget && !occurred_on.between?(budget.period_from, budget.period_to)
    end

    def source_belongs_to_budget
      errors.add(:source, :wrong_budget) if source && budget && source.budget_id != budget.id
    end

    def source_is_active
      errors.add(:source, :inactive) if source&.deleted?
    end

    def prevent_mutation
      errors.add(:base, :immutable)
    end
end
