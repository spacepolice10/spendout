require "test_helper"

class RefreshCurrencyReferenceRatesJobTest < ActiveJob::TestCase
  setup do
    Rails.cache.delete(CurrencyReferenceRates::CACHE_KEY)
  end

  teardown do
    Rails.cache.delete(CurrencyReferenceRates::CACHE_KEY)
  end

  test "replaces the cached table after a successful fetch" do
    fresh = payload("USD" => "1.2")
    client = Object.new
    client.define_singleton_method(:fetch) { fresh }

    job = RefreshCurrencyReferenceRatesJob.new
    job.define_singleton_method(:client) { client }
    job.perform_now

    assert_equal fresh, Rails.cache.read(CurrencyReferenceRates::CACHE_KEY)
  end

  test "retains the previous table when refresh fails" do
    previous = payload("USD" => "1.1")
    CurrencyReferenceRates.write(previous)
    client = Object.new
    client.define_singleton_method(:fetch) { raise Frankfurter::Client::Error, "unavailable" }

    job = RefreshCurrencyReferenceRatesJob.new
    job.define_singleton_method(:client) { client }
    job.perform_now

    assert_equal previous, Rails.cache.read(CurrencyReferenceRates::CACHE_KEY)
  end

  test "is scheduled daily at 18:00 UTC" do
    recurring = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_equal "RefreshCurrencyReferenceRatesJob", recurring.dig("production", "refresh_currency_reference_rates", "class")
    assert_equal "background", recurring.dig("production", "refresh_currency_reference_rates", "queue")
    assert_equal "at 6pm every day", recurring.dig("production", "refresh_currency_reference_rates", "schedule")
  end

  private
    def payload(rates)
      {
        "provider" => "Frankfurter",
        "reference_date" => "2026-08-24",
        "fetched_at" => "2026-08-24T18:00:00Z",
        "rates" => { "EUR" => "1" }.merge(rates)
      }
    end
end
