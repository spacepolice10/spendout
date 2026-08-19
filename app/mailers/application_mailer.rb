class ApplicationMailer < ActionMailer::Base
  default from: "Spendout <#{Rails.application.credentials.dig(:smtp, :user_name)}>"
  layout "mailer"
end
