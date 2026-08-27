class RefreshCurrencyReferenceJob < ApplicationJob
  queue_as :background

  def perform
    CurrencyReference.preserve(client.handle_request)
  rescue StandardError => error
    Rails.logger.error("Currency reference refresh failed: #{error.class}: #{error.message}")
  end

  private
    def client
      Frankfurter::Client.new
    end
end
