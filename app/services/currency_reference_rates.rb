class CurrencyReferenceRates
  CACHE_KEY = "currency_reference_rates/frankfurter/v1"
  CACHE_TTL = 30.days
  MAX_AGE_IN_DAYS = 7

  Result = Data.define(:rates, :provider, :reference_date) do
    def available?
      rates.any?
    end
  end

  class << self
    def for(base_currency_code, today: Date.current)
      payload = Rails.cache.read(CACHE_KEY)
      return empty unless valid_payload?(payload)

      reference_date = Date.iso8601(payload.fetch("reference_date"))
      return empty if reference_date > today || reference_date < today - MAX_AGE_IN_DAYS

      eur_rates = payload.fetch("rates").transform_values { |rate| BigDecimal(rate) }
      base_rate = eur_rates[base_currency_code]
      return empty unless base_rate&.positive?

      rates = eur_rates.each_with_object({}) do |(currency_code, rate), result|
        next if currency_code == base_currency_code

        result[currency_code] = decimal_string((rate / base_rate).round(12))
      end

      Result.new(rates:, provider: payload.fetch("provider"), reference_date:)
    rescue ArgumentError, KeyError, TypeError
      empty
    end

    def write(payload)
      Rails.cache.write(CACHE_KEY, payload, expires_in: CACHE_TTL)
    end

    private
      def valid_payload?(payload)
        payload.is_a?(Hash) && payload["rates"].is_a?(Hash) && payload["rates"].any?
      end

      def decimal_string(decimal)
        decimal.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
      end

      def empty
        Result.new(rates: {}, provider: nil, reference_date: nil)
      end
  end
end
