module Currencyable
  extend ActiveSupport::Concern

  included do
    before_validation :utilize_unit_rate_of_base_currency

    validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
    validates :rate, numericality: { greater_than: 0 }
  end

  def amount_in_base_currency
    amount / rate
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
    def currency_metadata
      Currency.find!(currency_code)
    end

    def utilize_unit_rate_of_base_currency
      self.rate = 1 if currency_code.present? && currency_code == budget&.base_currency_code
    end
end
