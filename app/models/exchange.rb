class Exchange < ApplicationRecord
  belongs_to :budget, inverse_of: :exchanges
  belongs_to :sender_source, class_name: "Source", inverse_of: :outgoing_exchanges
  belongs_to :receiver_source, class_name: "Source", inverse_of: :incoming_exchange

  attr_accessor :receiver_source_name, :receiver_currency_code

  validates :receiver_source_name, presence: true, on: :create
  validates :sender_amount, numericality: { greater_than: 0 }
  validates :receiver_amount, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than: 0 }
  validate :sources_belong_to_budget
  validate :sender_source_is_active
  validate :sender_amount_fits_source
  validate :receiver_amount_matches_source

  before_update :prevent_mutation
  before_destroy :prevent_direct_destruction

  def save_with_receiver_source
    return false unless sender_source&.persisted?

    sender_source.with_lock do
      self.budget ||= sender_source.budget
      derive_receiver_amount
      self.receiver_source ||= create_receiver_source

      transaction do
        valid?
        receiver_source.valid?

        if errors.empty? && receiver_source.errors.empty?
          save!
          true
        else
          copy_receiver_errors if receiver_source.errors.any?
          false
        end
      end
    end
  end

  private
    def derive_receiver_amount
      return unless sender_amount.present? && rate.present?

      self.receiver_amount = (sender_amount * rate).round(4)
    end

    def create_receiver_source
      budget.sources.build(
        name: receiver_source_name,
        amount: receiver_amount,
        currency_code: receiver_currency_code,
        rate: receiver_currency_code == budget.base_currency_code ? 1 : sender_source.rate * rate
      )
    end

    def sources_belong_to_budget
      errors.add(:sender_source, "must belong to this budget") if sender_source && budget && sender_source.budget_id != budget.id
      errors.add(:receiver_source, "must belong to this budget") if receiver_source && budget && receiver_source.budget_id != budget.id
    end

    def sender_source_is_active
      errors.add(:sender_source, "must be active") if sender_source&.deleted?
    end

    def sender_amount_fits_source
      return if sender_source.nil? || sender_amount.nil?

      available = sender_source.spendable_amount(excluding_exchange: self)
      errors.add(:sender_amount, "must be less than or equal to #{available.to_s("F")}") if sender_amount > available
    end

    def receiver_amount_matches_source
      if receiver_source && receiver_amount.present? && receiver_amount != receiver_source.amount
        errors.add(:receiver_amount, "must match the receiver source")
      end
    end

    def copy_receiver_errors
      receiver_source.errors.full_messages.each { |message| errors.add(:base, "New source #{message.downcase}") }
    end

    def prevent_mutation
      errors.add(:base, "exchange cannot be changed")
      throw(:abort)
    end

    def prevent_direct_destruction
      return if destroyed_by_association

      errors.add(:base, "exchange cannot be destroyed directly")
      throw(:abort)
    end
end
