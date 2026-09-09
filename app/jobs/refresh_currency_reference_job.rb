class RefreshCurrencyReferenceJob < ApplicationJob
  queue_as :background

  def perform
    CurrencyReference.refresh(client:)
  rescue StandardError => error
    Rails.logger.error("Currency reference refresh failed: #{error.class}: #{error.message}")
    raise
  end

  private
    def client
      Frankfurter::Client.new
    end
end
