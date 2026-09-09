class Category < ApplicationRecord
  include Colourable, Iconable

  belongs_to :budget, inverse_of: :categories
  has_one :allocation, dependent: :restrict_with_error, inverse_of: :category
  has_many :expenses, dependent: :restrict_with_error, inverse_of: :category
  has_many :recurrences, dependent: :restrict_with_error, inverse_of: :category

  scope :active, -> { where(deleted_at: nil) }

  validates :name, presence: true

  def active? = deleted_at.nil?
  def deleted? = deleted_at.present?
  def used_amount = expenses.sum(BigDecimal("0"), &:amount_in_base_currency)

  def retire!
    transaction do
      retired_at = Time.current
      allocation&.update!(deleted_at: retired_at)
      recurrences.active.update_all(ended_at: retired_at)
      update!(deleted_at: retired_at)
    end
  end
end
