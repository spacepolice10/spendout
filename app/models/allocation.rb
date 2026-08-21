class Allocation < ApplicationRecord
  include Colourable, Iconable
  include Currencyable

  belongs_to :budget, inverse_of: :allocations
  has_many :expenses, inverse_of: :allocation

  scope :planned, -> { where(planned: true) }
  scope :unplanned, -> { where(planned: false) }

  validates :name, presence: true
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget

  def deleted?
    deleted_at.present?
  end

  private
    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, "is not supported")
    end
end
