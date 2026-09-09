class Feature < ApplicationRecord
  TYPES = %w[ new_expense new_income new_source new_allocation lens_laboratory ].freeze
  FAVORITABLE_TYPES = %w[ new_expense new_income ].freeze

  belongs_to :budget, inverse_of: :features

  scope :in_menu_order, -> {
    order(Arel.sql(<<~SQL.squish), :id)
      CASE feature_type
      WHEN 'new_expense' THEN 0
      WHEN 'new_income' THEN 1
      WHEN 'new_source' THEN 2
      WHEN 'new_allocation' THEN 3
      ELSE 4 END
    SQL
  }
  scope :favorites, -> { where(favorite: true) }

  validates :feature_type, inclusion: { in: TYPES }, uniqueness: { scope: :budget_id }
  validate :only_supported_features_can_be_favorites

  def favoritable? = feature_type.in?(FAVORITABLE_TYPES)

  private
    def only_supported_features_can_be_favorites
      errors.add(:favorite, :unsupported) if favorite? && !favoritable?
    end
end
