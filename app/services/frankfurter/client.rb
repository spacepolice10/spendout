require "bigdecimal"
require "json"
require "net/http"

module Frankfurter
  class Client
    ENDPOINT = "https://api.frankfurter.dev/v2/rates?base=EUR&date=%<date>s"
    class Error < StandardError; end

    def handle_request
      response = perform_request
      raise Error, "Frankfurter returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      parsed(response.body)
    rescue JSON::ParserError, ArgumentError, KeyError, TypeError => error
      raise Error, "Invalid Frankfurter response: #{error.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError => error
      raise Error, "Frankfurter request failed: #{error.message}"
    end

    private
      def perform_request
        endpoint = URI(format(ENDPOINT, date: Date.current.iso8601))

        Net::HTTP.start(endpoint.host, endpoint.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
          request = Net::HTTP::Get.new(endpoint)
          request["Accept"] = "application/json"
          http.request(request)
        end
      end

      def parsed(body)
        rate_list = JSON.parse(body, decimal_class: BigDecimal)
        raise Error, "expected a non-empty array" unless rate_list.is_a?(Array) && rate_list.any?

        reference_dates = {}
        rate_catalog = {}

        rate_list.each do |rate|
          raise Error, "expected an object for every rate" unless rate.is_a?(Hash)

          date = Date.iso8601(rate.fetch("date"))
          base = rate.fetch("base")
          quoted_currency = rate.fetch("quote")
          rate = decimal(rate.fetch("rate"))

          raise Error, "unexpected base currency" unless base == "EUR"
          raise Error, "rate must be positive" unless rate.positive?
          next unless Currency::CATALOG.key?(quoted_currency)
          raise Error, "invalid EUR identity rate" if quoted_currency == "EUR" && rate != 1

          raise Error, "duplicate quoted currency" if rate_catalog.key?(quoted_currency)

          reference_dates[quoted_currency] = date.iso8601
          rate_catalog[quoted_currency] = quoted_currency == "EUR" ? "1" : rate.to_s("F")
        end

        raise Error, "missing EUR identity rate" unless rate_catalog["EUR"] == "1"

        {
          "reference_date" => reference_dates.values.max,
          "rates" => rate_catalog,
          "reference_dates" => reference_dates
        }
      end

      def decimal(value)
        value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
      end
  end
end
