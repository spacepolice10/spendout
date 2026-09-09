class Lens < ApplicationRecord
  self.table_name = "lenses"

  BUILTIN_TYPES = %w[ SourceHolder PlanOverview ].freeze
  SINGLETON_TYPES = (BUILTIN_TYPES + %w[ Rollover RateInfo ]).freeze

  delegated_type :lensable, types: %w[
    SourceHolder PlanOverview Rollover MostExpensiveCategories UpcomingRecurrences RateInfo
  ], dependent: :destroy

  belongs_to :budget, inverse_of: :lenses

  scope :positioned, -> { order(:position, :created_at, :id) }

  validates :lensable_type, uniqueness: { scope: :budget_id }, if: :singleton?
  before_create :append_to_budget
  after_destroy :close_position_gap, unless: :destroyed_by_association
  before_destroy :prevent_builtin_destruction, if: :protect_builtin_from_destruction?

  def builtin? = lensable_type.in?(BUILTIN_TYPES)
  def removable? = !builtin?
  def singleton? = lensable_type.in?(SINGLETON_TYPES)
  def snapshot(on: Date.current) = lensable.snapshot(budget:, on:)

  def move!(direction)
    offset = { "up" => -1, "down" => 1 }.fetch(direction)

    self.class.transaction do
      ordered_lenses = budget.lenses.lock.positioned.to_a
      current_index = ordered_lenses.index { |lens| lens.id == id }
      target_index = current_index + offset
      return false unless target_index.between?(0, ordered_lenses.length - 1)

      ordered_lenses[current_index], ordered_lenses[target_index] =
        ordered_lenses[target_index], ordered_lenses[current_index]
      ordered_lenses.each_with_index do |lens, position|
        lens.update_columns(position:) unless lens.position == position
      end
    end

    true
  end

  private
    def append_to_budget
      self.position = (budget.lenses.maximum(:position) || -1) + 1
    end

    def close_position_gap
      budget.lenses.positioned.each_with_index do |lens, position|
        lens.update_columns(position:) unless lens.position == position
      end
    end

    def protect_builtin_from_destruction? = builtin? && destroyed_by_association.nil?
    def prevent_builtin_destruction = throw(:abort)
end
