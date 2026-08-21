class User < ApplicationRecord
  has_many :budgets, dependent: :destroy
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :email_address, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }

  def current_budget
    budgets.where(period_to: Date.current..).order(created_at: :desc, id: :desc).first
  end
end
