class Source < ApplicationRecord
  include Colourable, Iconable
  include Currencyable

  belongs_to :budget, inverse_of: :sources
  has_many :expenses, inverse_of: :source

  validates :name, presence: true
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget
  validate :base_source_is_not_deleted
  before_destroy :prevent_base_source_destruction, prepend: true, unless: -> { destroyed_by_association.present? }

  def deleted?
    deleted_at.present?
  end

  def base?
    budget&.base_source == self
  end

  def spendable_amount(excluding: nil)
    recorded_expenses = expenses
    recorded_expenses = recorded_expenses.where.not(id: excluding.id) if excluding&.persisted?
    amount - recorded_expenses.sum(:amount)
  end

  private
    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, "is not supported")
    end

    def base_source_is_not_deleted
      errors.add(:deleted_at, "cannot delete the base source") if deleted? && base?
    end

    def prevent_base_source_destruction
      return unless base?

      errors.add(:base, "source cannot be destroyed")
      throw :abort
    end
end
