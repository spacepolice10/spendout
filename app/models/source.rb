class Source < ApplicationRecord
  include Colourable, Iconable
  include Currencyable

  DESIGNS = {
    "americat_express" => { face: nil, selectable: true },
    "mastercat" => { face: "cat-face-friendly-v2.png", selectable: true },
    "meowisa" => { face: "cat-face-sleepy-v2.png", selectable: true },
    "unipaw" => { face: "cat-face-curious-v2.png", selectable: true },
    "cash" => { face: "cat-face-grumpy-v2.png", selectable: true },
    "bank" => { face: "cat-face-friendly-v2.png", selectable: false },
    "savings" => { face: "cat-face-sleepy-v2.png", selectable: false },
    "digital_wallet" => { face: "cat-face-curious-v2.png", selectable: false }
  }.freeze

  enum :design, {
    americat_express: 0, mastercat: 1, meowisa: 2, unipaw: 3,
    cash: 4, bank: 5, savings: 6, digital_wallet: 7
  },
    default: :americat_express, validate: true

  belongs_to :budget, inverse_of: :sources
  has_many :expenses, inverse_of: :source
  has_many :outgoing_exchanges, class_name: "Exchange", foreign_key: :sender_source_id, inverse_of: :sender_source
  has_one :incoming_exchange, class_name: "Exchange", foreign_key: :receiver_source_id, inverse_of: :receiver_source

  validates :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :currency_is_available_in_budget
  validate :currency_cannot_change, on: :update
  validate :rate_cannot_change, on: :update

  before_destroy :prevent_direct_destruction

  def spendable_amount(excluding: nil, excluding_exchange: nil)
    recorded_expenses = expenses
    recorded_expenses = recorded_expenses.where.not(id: excluding.id) if excluding&.persisted?
    recorded_exchanges = outgoing_exchanges
    recorded_exchanges = recorded_exchanges.where.not(id: excluding_exchange.id) if excluding_exchange&.persisted?
    amount - recorded_expenses.sum(:source_amount) - recorded_exchanges.sum(:sender_amount)
  end

  def deleted?
    deleted_at.present?
  end

  def design_name
    I18n.t("sources.designs.#{design}", default: design.to_s.humanize)
  end

  def design_face
    DESIGNS.fetch(design, DESIGNS.fetch("americat_express")).fetch(:face)
  end

  def self.design_options
    DESIGNS.filter_map do |value, design|
      [ I18n.t("sources.designs.#{value}"), value ] if design.fetch(:selectable)
    end
  end

  private
    def prevent_direct_destruction
      return if destroyed_by_association

      errors.add(:base, :direct_destruction)
      throw(:abort)
    end

    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, :unavailable)
    end

    def currency_cannot_change
      errors.add(:currency_code, :changed) if will_save_change_to_currency_code?
    end

    def rate_cannot_change
      errors.add(:rate, :changed) if will_save_change_to_rate?
    end
end
