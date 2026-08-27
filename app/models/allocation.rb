class Allocation < ApplicationRecord
  include Colourable, Iconable
  include Currencyable

  belongs_to :budget, inverse_of: :allocations
  has_many :expenses, inverse_of: :allocation

  scope :planned, -> { where(planned: true) }
  scope :unplanned, -> { where(planned: false) }
  scope :active, -> { where(deleted_at: nil, finished_at: nil) }

  validates :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget

  def deleted?
    deleted_at.present?
  end

  def finished?
    finished_at.present?
  end

  def active?
    !deleted? && !finished?
  end

  def remaining_amount
    [ amount - used_amount, BigDecimal("0") ].max
  end

  def used_amount
    expenses.joins(:source).pluck(:source_amount, "sources.rate").sum(BigDecimal("0")) do |source_amount, source_rate|
      source_amount / source_rate * rate
    end
  end

  private
    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, "is not supported")
    end
end
