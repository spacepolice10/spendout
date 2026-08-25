class User < ApplicationRecord
  has_secure_password validations: false

  has_many :budgets, dependent: :destroy
  has_many :sessions, dependent: :destroy

  enum :role, { member: 0, administrator: 1 }, default: :member

  normalizes :email_address, with: ->(value) { value.to_s.strip.downcase.presence }

  validates :email_address, presence: true,
    format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, confirmation: true, allow_blank: true
  validates :password_digest, presence: true, if: :administrator?

  def current_budget
    budgets.where(period_to: Date.current..).order(created_at: :desc, id: :desc).first
  end
end
