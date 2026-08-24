class RefreshCurrencyReferenceRatesJob < ApplicationJob
  queue_as :background

  def perform
    CurrencyReferenceRates.write(client.fetch)
  rescue StandardError => error
    Rails.logger.error("Currency reference rate refresh failed: #{error.class}: #{error.message}")
  end

  private
    def client
      Frankfurter::Client.new
    end
end
