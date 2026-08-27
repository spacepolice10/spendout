class CurrencyReference
  CACHE_KEY = "currency_reference/frankfurter/v1"
  CACHE_TTL = 30.days
  MAX_AGE_IN_DAYS = 7

  class << self
    def preserve(rate_metadata)
      Rails.cache.write(CACHE_KEY, rate_metadata, expires_in: CACHE_TTL)
    end

    def request_rate(from_currency, to_currency, today: Date.current)
      from_currency = currency_code(from_currency)
      to_currency = currency_code(to_currency)
      return "1" if from_currency == to_currency

      rates_against(from_currency, today:)[to_currency]
    rescue ArgumentError
      nil
    end

    def rates_against(base_currency, today: Date.current)
      base_currency = currency_code(base_currency)
      rate_metadata = Rails.cache.read(CACHE_KEY)
      return {} unless current?(rate_metadata, today:)

      rate_catalog   = rate_metadata.fetch("rates")
      base_rate = BigDecimal(rate_catalog.fetch(base_currency))
      return {} unless base_rate.positive?

      rate_catalog.each_with_object({ base_currency => "1" }) do |(currency, rate), normalized|
        next if currency == base_currency

        rate = BigDecimal(rate)
        normalized[currency] = decimal_string((rate / base_rate).round(12)) if rate.positive?
      end
    rescue ArgumentError, KeyError, TypeError
      {}
    end

    private
      def current?(rate_metadata, today:)
        return false unless rate_metadata.is_a?(Hash) && rate_metadata["rates"].is_a?(Hash)

        reference_date = Date.iso8601(rate_metadata.fetch("reference_date"))
        reference_date.between?(today - MAX_AGE_IN_DAYS, today)
      rescue ArgumentError, KeyError
        false
      end

      def decimal_string(decimal)
        decimal.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
      end

      def currency_code(currency)
        currency.to_s.strip.upcase.tap { |code| Currency.find!(code) }
      end
  end
end
