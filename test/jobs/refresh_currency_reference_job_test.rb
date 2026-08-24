require "test_helper"

class RefreshCurrencyReferenceJobTest < ActiveJob::TestCase
  setup do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  teardown do
    Rails.cache.delete(CurrencyReference::CACHE_KEY)
  end

  test "replaces the cached table after a successful fetch" do
    fresh = payload("USD" => "1.2")
    client = Object.new
    client.define_singleton_method(:fetch) { fresh }

    job = RefreshCurrencyReferenceJob.new
    job.define_singleton_method(:client) { client }
    job.perform_now

    assert_equal fresh, Rails.cache.read(CurrencyReference::CACHE_KEY)
  end

  test "retains the previous table when refresh fails" do
    previous = payload("USD" => "1.1")
    CurrencyReference.preserve(previous)
    client = Object.new
    client.define_singleton_method(:fetch) { raise Frankfurter::Client::Error, "unavailable" }

    job = RefreshCurrencyReferenceJob.new
    job.define_singleton_method(:client) { client }
    job.perform_now

    assert_equal previous, Rails.cache.read(CurrencyReference::CACHE_KEY)
  end

  test "is scheduled daily at 18:00 UTC" do
    recurring = YAML.load_file(Rails.root.join("config/recurring.yml"))

    assert_equal "RefreshCurrencyReferenceJob", recurring.dig("production", "refresh_currency_reference", "class")
    assert_equal "background", recurring.dig("production", "refresh_currency_reference", "queue")
    assert_equal "at 6pm every day", recurring.dig("production", "refresh_currency_reference", "schedule")
  end

  private
    def payload(rates)
      {
        "reference_date" => "2026-08-24",
        "rates" => { "EUR" => "1" }.merge(rates)
      }
    end
end
