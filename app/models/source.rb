class Source < ApplicationRecord
  include Colourable, Iconable
  include Currencyable

  belongs_to :budget, inverse_of: :sources
  has_many :expenses, inverse_of: :source
  has_many :outgoing_exchanges, class_name: "Exchange", foreign_key: :parent_source_id, inverse_of: :parent_source
  has_one :incoming_exchange, class_name: "Exchange", foreign_key: :child_source_id, inverse_of: :child_source

  validates :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget

  before_destroy :prevent_direct_destruction

  def spendable_amount(excluding: nil, excluding_exchange: nil)
    recorded_expenses = expenses
    recorded_expenses = recorded_expenses.where.not(id: excluding.id) if excluding&.persisted?
    recorded_exchanges = outgoing_exchanges
    recorded_exchanges = recorded_exchanges.where.not(id: excluding_exchange.id) if excluding_exchange&.persisted?
    amount - recorded_expenses.sum(:amount) - recorded_exchanges.sum(:parent_amount)
  end

  def deleted?
    deleted_at.present?
  end

  private
    def prevent_direct_destruction
      return if destroyed_by_association

      errors.add(:base, "source cannot be destroyed directly")
      throw(:abort)
    end

    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, "is not supported")
    end
end
