module Currencyable
  extend ActiveSupport::Concern

  included do
    before_validation :use_unit_rate_for_base_currency

    validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
    validates :rate, numericality: { greater_than: 0 }
  end

  def amount_in_base
    amount / rate
  end

  def currency_metadata
    Currency.find!(currency_code)
  end

  def currency_name
    currency_metadata[:name]
  end

  def currency_numeric_code
    currency_metadata[:numeric_code]
  end

  def currency_symbol
    currency_metadata[:symbol]
  end

  def currency_flag
    currency_metadata[:flag]
  end

  private
    def use_unit_rate_for_base_currency
      self.rate = 1 if currency_code.present? && currency_code == budget&.base_currency_code
    end
end
