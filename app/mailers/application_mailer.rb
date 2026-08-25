class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAILER_FROM_ADDRESS"] || "Spendout <#{Rails.application.credentials.dig(:smtp, :user_name)}>"
  layout "mailer"
end
