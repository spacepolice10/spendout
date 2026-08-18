class AuthCode < ApplicationRecord
  ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  CODE_LENGTH = 6
  EXPIRATION_TIME = 15.minutes

  scope :active, -> { where(expires_at: Time.current...) }
  scope :expired, -> { where(expires_at: ..Time.current) }

  normalizes :email_address, with: ->(value) { normalize_email_address(value) }

  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create

  validates :email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :code, presence: true, uniqueness: true

  class << self
    def produce(email_address)
      transaction do
        normalized_email_address = normalize_email_address(email_address)
        where(email_address: normalized_email_address).delete_all
        create!(email_address: normalized_email_address)
      end.tap do |auth_code|
        AuthenticationMailer.sign_in_instructions(
          email_address: auth_code.email_address,
          code: auth_code.code
        ).deliver_later
      end
    end

    def consume(code, email_address:)
      sanitized_code = sanitize(code)
      normalized_email_address = normalize_email_address(email_address)

      transaction do
        auth_code = active.find_by(code: sanitized_code, email_address: normalized_email_address)
        normalized_email_address if auth_code && where(id: auth_code.id).delete_all == 1
      end
    end

    def cleanup
      expired.delete_all
    end

    def normalize_email_address(email_address)
      email_address.to_s.strip.downcase.presence
    end

    def sanitize(code)
      code.to_s.upcase.gsub(/[\s-]/, "")
    end
  end

  private
    def generate_code
      self.code ||= loop do
        candidate = Array.new(CODE_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
        break candidate unless self.class.exists?(code: candidate)
      end
    end

    def set_expiration
      self.expires_at ||= EXPIRATION_TIME.from_now
    end
end
