require "bigdecimal"
require "json"
require "net/http"

module Frankfurter
  class Client
    ENDPOINT = "https://api.frankfurter.dev/v2/rates?base=EUR&date=%<date>s"
    PROVIDER = "Frankfurter"

    class Error < StandardError; end

    def fetch
      response = perform_request
      raise Error, "Frankfurter returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      parse(response.body)
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

      def parse(body)
        rows = JSON.parse(body, decimal_class: BigDecimal)
        raise Error, "expected a non-empty array" unless rows.is_a?(Array) && rows.any?

        dates = []
        rates = { "EUR" => "1" }

        rows.each do |row|
          raise Error, "expected an object for every rate" unless row.is_a?(Hash)

          date = Date.iso8601(row.fetch("date"))
          base = row.fetch("base")
          quote = row.fetch("quote")
          rate = decimal(row.fetch("rate"))

          raise Error, "unexpected base currency" unless base == "EUR"
          raise Error, "rate must be positive" unless rate.positive?
          next if quote == "EUR"
          next unless Currency::CATALOG.key?(quote)

          raise Error, "duplicate quote currency" if rates.key?(quote)

          dates << date
          rates[quote] = rate.to_s("F")
        end

        raise Error, "rates have inconsistent reference dates" unless dates.uniq.one?

        {
          "provider" => PROVIDER,
          "reference_date" => dates.first.iso8601,
          "fetched_at" => Time.current.iso8601,
          "rates" => rates
        }
      end

      def decimal(value)
        value.is_a?(BigDecimal) ? value : BigDecimal(value.to_s)
      end
  end
end
