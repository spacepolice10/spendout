class Source < ApplicationRecord
  include Colourable, Iconable

  belongs_to :budget, inverse_of: :sources
  has_many :allocations, dependent: :destroy, inverse_of: :source

  validates :name, presence: true
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget
  validate :amount_covers_allocations
  validate :base_source_is_not_deleted
  before_destroy :prevent_base_source_destruction, prepend: true, unless: -> { destroyed_by_association.present? }

  def currency
    budget.currencies.find { |currency| currency.alphabetic_code == currency_code }
  end

  def deleted?
    deleted_at.present?
  end

  def base?
    budget&.base_source == self
  end

  def allocated_amount(excluding: nil)
    active_allocations = allocations.where(deleted_at: nil)
    active_allocations = active_allocations.where.not(id: excluding.id) if excluding&.persisted?
    active_allocations.sum(:amount)
  end

  def available_amount
    amount - allocated_amount
  end

  private
    def currency_is_available_in_budget
      return if currency_code.blank? || budget.nil? || currency.present?

      errors.add(:currency_code, "must be available in this budget")
    end


    def amount_covers_allocations
      return if amount.nil? || new_record?

      errors.add(:amount, "must cover active allocations") if amount < allocated_amount
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
