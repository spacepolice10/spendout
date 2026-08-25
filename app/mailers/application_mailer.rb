class ApplicationMailer < ActionMailer::Base
  def self.credentials_sender
    if ENV["RAILS_MASTER_KEY"].present? && (user_name = Rails.application.credentials.dig(:smtp, :user_name))
      "Spendout <#{user_name}>"
    end
  end

  default from: ENV["MAILER_FROM_ADDRESS"] || credentials_sender || "Spendout <no-reply@localhost>"
  layout "mailer"
end
