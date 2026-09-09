class CurrencyReference
  CACHE_KEY = "currency_reference/frankfurter/v1"
  REFRESH_FAILURE_KEY = "#{CACHE_KEY}/refresh_failure"
  CACHE_TTL = 30.days
  REFRESH_FAILURE_TTL = 5.minutes
  MAX_AGE_IN_DAYS = 7

  class << self
    def preserve(rate_metadata)
      Rails.cache.write(CACHE_KEY, rate_metadata, expires_in: CACHE_TTL)
      Rails.cache.delete(REFRESH_FAILURE_KEY)
    end

    def refresh(client: Frankfurter::Client.new)
      preserve(client.handle_request)
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
      rate_metadata = metadata(today:)
      return {} unless rate_metadata

      rate_catalog = current_rates(rate_metadata, today:)
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

    def reference_dates(today: Date.current)
      rate_metadata = metadata(today:)
      return {} unless rate_metadata

      current_reference_dates(rate_metadata, today:)
    end

    def metadata(today: Date.current)
      rate_metadata = Rails.cache.read(CACHE_KEY)
      return rate_metadata if current?(rate_metadata, today:)

      refresh_after_miss if Rails.configuration.x.currency_reference.refresh_on_miss
      rate_metadata = Rails.cache.read(CACHE_KEY)
      rate_metadata if current?(rate_metadata, today:)
    end

    private
      def current?(rate_metadata, today:)
        return false unless rate_metadata.is_a?(Hash) && rate_metadata["rates"].is_a?(Hash)

        reference_date = Date.iso8601(rate_metadata.fetch("reference_date"))
        reference_date.between?(today - MAX_AGE_IN_DAYS, today)
      rescue ArgumentError, KeyError
        false
      end

      def refresh_after_miss
        return if Rails.cache.exist?(REFRESH_FAILURE_KEY)

        refresh
      rescue StandardError => error
        Rails.cache.write(REFRESH_FAILURE_KEY, true, expires_in: REFRESH_FAILURE_TTL)
        Rails.logger.error("Currency reference refresh after cache miss failed: #{error.class}: #{error.message}")
      end

      def current_rates(rate_metadata, today:)
        current_dates = current_reference_dates(rate_metadata, today:)

        rate_metadata.fetch("rates").slice(*current_dates.keys)
      end

      def current_reference_dates(rate_metadata, today:)
        reference_dates = rate_metadata.fetch("reference_dates", {})
        default_date = rate_metadata.fetch("reference_date")

        rate_metadata.fetch("rates").each_key.filter_map do |currency|
          reference_date = Date.iso8601(reference_dates.fetch(currency, default_date))
          [ currency, reference_date ] if reference_date.between?(today - MAX_AGE_IN_DAYS, today)
        rescue ArgumentError, TypeError
          nil
        end.to_h
      end

      def decimal_string(decimal)
        decimal.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
      end

      def currency_code(currency)
        currency.to_s.strip.upcase.tap { |code| Currency.find!(code) }
      end
  end
end
