class Recurrence < ApplicationRecord
  belongs_to :budget, inverse_of: :recurrences
  belongs_to :category, inverse_of: :recurrences
  has_many :occurrences, class_name: "RecurringOccurrence", dependent: :destroy
  has_many :expenses, through: :occurrences

  scope :active, -> { where(ended_at: nil) }

  attr_accessor :category_name_to_create, :category_icon, :category_colour

  validates :name, :occurs_on, presence: true
  validates :category_icon, inclusion: { in: Iconable::CATALOG.keys }, allow_blank: true
  validates :category_colour, inclusion: { in: Colourable::CATALOG.keys }, allow_blank: true
  validates :amount, numericality: { greater_than: 0 }
  validates :occurrence_period_in_days, numericality: { only_integer: true, greater_than: 0 }
  validates :currency_code, inclusion: { in: Currency::CATALOG.keys }
  validates :note, length: { maximum: 200 }, allow_blank: true
  validate :category_belongs_to_budget
  validate :category_is_active

  def active? = ended_at.nil?

  def save_with_category
    return save if category_name_to_create.blank?

    transaction do
      category_icon = CategoryIcon.new(category_name_to_create)
      self.category = budget.categories.build(
        name: category_name_to_create,
        icon: self.category_icon.presence || category_icon.matched_name,
        colour: category_colour.presence || category_icon.matched_colour
      )
      saved = save
      raise ActiveRecord::Rollback unless saved
      saved
    end
  end

  def record!(expense)
    with_lock do
      occurrences.create!(expense:, due_on: occurs_on)
      update!(occurs_on: occurs_on + occurrence_period_in_days.days)
    end
  end

  def end! = update!(ended_at: Time.current)

  private
    def category_belongs_to_budget
      errors.add(:category, :wrong_budget) if category && budget && category.budget_id != budget.id
    end

    def category_is_active
      errors.add(:category, :inactive) if category&.deleted?
    end
end
