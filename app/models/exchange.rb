class Exchange < ApplicationRecord
  belongs_to :budget, inverse_of: :exchanges
  belongs_to :parent_source, class_name: "Source", inverse_of: :outgoing_exchanges
  belongs_to :child_source, class_name: "Source", inverse_of: :incoming_exchange

  attr_accessor :child_source_name

  validates :child_source_name, presence: true, on: :create
  validates :parent_amount, numericality: { greater_than: 0 }
  validates :child_amount, numericality: { greater_than: 0 }
  validates :rate, numericality: { greater_than: 0 }
  validates :parent_currency_code, :child_currency_code, inclusion: { in: Currency::CATALOG.keys }
  validate :sources_belong_to_budget
  validate :currencies_are_different
  validate :parent_source_is_active
  validate :parent_amount_fits_source
  validate :snapshots_match_sources

  before_validation :set_derived_attributes
  before_update :prevent_mutation
  before_destroy :prevent_direct_destruction

  def save_with_child_source
    return false unless parent_source&.persisted?

    parent_source.with_lock do
      set_derived_attributes
      self.child_source ||= build_child_source

      transaction do
        exchange_valid = valid?
        child_valid = child_source.valid?

        if exchange_valid && child_valid
          save!
          true
        else
          copy_child_errors unless child_valid
          false
        end
      end
    end
  end

  private
    def set_derived_attributes
      return unless parent_source

      self.budget ||= parent_source.budget
      self.parent_currency_code = parent_source.currency_code
      return unless parent_amount.present? && rate.present?

      self.child_amount = (parent_amount * rate).round(4)
    end

    def build_child_source
      budget.sources.build(
        name: child_source_name,
        amount: child_amount,
        currency_code: child_currency_code,
        rate: child_currency_code == budget.base_currency_code ? 1 : parent_source.rate * rate
      )
    end

    def sources_belong_to_budget
      errors.add(:parent_source, "must belong to this budget") if parent_source && budget && parent_source.budget_id != budget.id
      errors.add(:child_source, "must belong to this budget") if child_source && budget && child_source.budget_id != budget.id
    end

    def currencies_are_different
      return if parent_currency_code.blank? || child_currency_code.blank?

      errors.add(:child_currency_code, "must differ from the parent currency") if parent_currency_code == child_currency_code
    end

    def parent_source_is_active
      errors.add(:parent_source, "must be active") if parent_source&.deleted?
    end

    def parent_amount_fits_source
      return if parent_source.nil? || parent_amount.nil?

      available = parent_source.spendable_amount(excluding_exchange: self)
      errors.add(:parent_amount, "must be less than or equal to #{available.to_s("F")}") if parent_amount > available
    end

    def snapshots_match_sources
      if parent_source && parent_currency_code.present? && parent_currency_code != parent_source.currency_code
        errors.add(:parent_currency_code, "must match the parent source")
      end
      if child_source && child_currency_code.present? && child_currency_code != child_source.currency_code
        errors.add(:child_currency_code, "must match the child source")
      end
      if child_source && child_amount.present? && child_amount != child_source.amount
        errors.add(:child_amount, "must match the child source")
      end
    end

    def copy_child_errors
      child_source.errors.full_messages.each { |message| errors.add(:base, "New source #{message.downcase}") }
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
