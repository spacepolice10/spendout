class RateInfo < ApplicationRecord
  CAPACITY = 4
  Rate = Data.define(:currency_code, :rate, :reference_from, :reference_to)
  Snapshot = Data.define(:base_currency_code, :reference_date, :rates, :available)

  has_one :lens, as: :lensable
  serialize :currency_codes, coder: JSON, type: Array
  attr_accessor :monitored_against
  validates :currency_codes, presence: true
  validate :currency_codes_are_monitored

  def snapshot(budget:, on: Date.current)
    metadata = CurrencyReference.metadata(today: on)
    catalog = CurrencyReference.rates_against(budget.base_currency_code, today: on)
    reference_dates = CurrencyReference.reference_dates(today: on)
    return unavailable_snapshot(budget) unless metadata && catalog.any?

    rates = currency_codes.filter_map do |code|
      next unless catalog.key?(code) && reference_dates.key?(budget.base_currency_code) && reference_dates.key?(code)

      dates = [ reference_dates.fetch(budget.base_currency_code), reference_dates.fetch(code) ].minmax
      Rate.new(currency_code: code, rate: BigDecimal(catalog.fetch(code)), reference_from: dates.first, reference_to: dates.last)
    end
    return unavailable_snapshot(budget) if rates.empty?

    Snapshot.new(base_currency_code: budget.base_currency_code,
      reference_date: Date.iso8601(metadata.fetch("reference_date")), rates:, available: true)
  rescue ArgumentError, KeyError, TypeError
    unavailable_snapshot(budget)
  end

  def currency_codes=(values)
    super(Array(values).flatten.filter_map { |code| code.to_s.strip.upcase.presence }.uniq)
  end

  def self.currency_options_for(budget, selected: [])
    preferred = Array(selected) + budget.sources.where(deleted_at: nil).distinct.pluck(:currency_code)
    Currency.options_prioritizing(preferred + Currency::POPULAR_CURRENCIES)
      .reject { |_, code| code == budget.base_currency_code }
  end

  private
    def unavailable_snapshot(budget)
      Snapshot.new(base_currency_code: budget.base_currency_code, reference_date: nil, rates: [], available: false)
    end

    def currency_codes_are_monitored
      codes = Array(currency_codes)
      errors.add(:currency_codes, :too_many, count: CAPACITY) if codes.size > CAPACITY

      invalid = codes - Currency::CATALOG.keys
      errors.add(:currency_codes, :inclusion) if invalid.any?

      base = monitored_against.presence || lens&.budget&.base_currency_code
      errors.add(:currency_codes, :exclusion) if base && codes.include?(base)
    end
end
