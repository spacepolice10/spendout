class Allocation < ApplicationRecord
  include Currencyable

  belongs_to :budget, inverse_of: :allocations
  belongs_to :category, inverse_of: :allocation, autosave: true
  has_many :expenses, through: :category

  attr_accessor :category_name_to_create, :category_icon, :category_colour

  before_validation :initialize_category_to_create

  scope :active, -> { where(deleted_at: nil, finished_at: nil) }

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :category_icon, inclusion: { in: Iconable::CATALOG.keys }, allow_blank: true
  validates :category_colour, inclusion: { in: Colourable::CATALOG.keys }, allow_blank: true
  validates :category_id, uniqueness: { scope: :budget_id }
  validate :currency_is_available_in_budget
  validate :category_belongs_to_budget
  validate :category_is_active

  def deleted?
    deleted_at.present?
  end

  def finished?
    finished_at.present?
  end

  def active?
    !deleted? && !finished?
  end

  def remaining_amount
    [ amount - used_amount, BigDecimal("0") ].max
  end

  def used_amount
    expenses.joins(:source).pluck(:source_amount, "sources.rate").sum(BigDecimal("0")) do |source_amount, source_rate|
      source_amount / source_rate * rate
    end
  end

  delegate :name, :icon, :colour, to: :category

  private
    def initialize_category_to_create
      return if category_name_to_create.blank? || category&.new_record?

      category_icon = CategoryIcon.new(category_name_to_create)
      self.category = budget.categories.build(
        name: category_name_to_create,
        icon: self.category_icon.presence || category_icon.matched_name,
        colour: category_colour.presence || category_icon.matched_colour
      )
    end

    def currency_is_available_in_budget
      return if currency_code.blank? || Currency::CATALOG.key?(currency_code)

      errors.add(:currency_code, :unavailable)
    end

    def category_belongs_to_budget
      errors.add(:category, :wrong_budget) if category && budget && category.budget_id != budget.id
    end

    def category_is_active
      errors.add(:category, :inactive) if category&.deleted?
    end
end
