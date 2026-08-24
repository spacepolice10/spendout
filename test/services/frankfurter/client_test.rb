require "test_helper"

module Frankfurter
  class ClientTest < ActiveSupport::TestCase
    test "parses a complete EUR rate table as decimal strings" do
      payload = parse(<<~JSON)
        [
          {"date":"2026-08-24","base":"EUR","quote":"USD","rate":1.17500},
          {"date":"2026-08-24","base":"EUR","quote":"EUR","rate":1.0},
          {"date":"2026-08-24","base":"EUR","quote":"VND","rate":30912.125},
          {"date":"2026-08-24","base":"EUR","quote":"XXX","rate":2}
        ]
      JSON

      assert_equal "Frankfurter", payload["provider"]
      assert_equal "2026-08-24", payload["reference_date"]
      assert_equal({ "EUR" => "1", "USD" => "1.175", "VND" => "30912.125" }, payload["rates"])
      assert Time.iso8601(payload["fetched_at"])
    end

    test "rejects malformed and unsafe rate tables" do
      assert_raises(Client::Error) { parse("{}") }
      assert_raises(Client::Error) do
        parse('[{"date":"2026-08-24","base":"USD","quote":"VND","rate":2}]')
      end
      assert_raises(Client::Error) do
        parse('[{"date":"2026-08-24","base":"EUR","quote":"VND","rate":0}]')
      end
      assert_raises(Client::Error) do
        parse('[{"date":"2026-08-24","base":"EUR","quote":"USD","rate":1.1},' \
          '{"date":"2026-08-23","base":"EUR","quote":"VND","rate":2}]')
      end
    end

    test "rejects unsuccessful HTTP responses and wraps network failures" do
      unavailable = Net::HTTPServiceUnavailable.new("1.1", "503", "Service Unavailable")
      client = Client.new
      client.define_singleton_method(:perform_request) { unavailable }
      error = assert_raises(Client::Error) { client.fetch }
      assert_match(/HTTP 503/, error.message)

      client = Client.new
      client.define_singleton_method(:perform_request) { raise Net::ReadTimeout, "timed out" }
      error = assert_raises(Client::Error) { client.fetch }
      assert_match(/request failed.*timed out/, error.message)
    end

    private
      def parse(json)
        Client.new.send(:parse, json)
      end
  end
end
