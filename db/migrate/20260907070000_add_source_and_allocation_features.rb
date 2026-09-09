class AddSourceAndAllocationFeatures < ActiveRecord::Migration[8.1]
  FEATURE_TYPES = %w[new_expense new_income new_source new_allocation lens_laboratory].freeze
  ADDED_TYPES = %w[new_source new_allocation].freeze

  def up
    remove_check_constraint :features, name: "features_known_type"
    add_check_constraint :features, "feature_type IN (#{FEATURE_TYPES.map { |type| connection.quote(type) }.join(', ')})", name: "features_known_type"

    rows = existing_feature_rows
    feature_model.insert_all(rows) if rows.any?
  end

  def down
    feature_model.where(feature_type: ADDED_TYPES).delete_all
    remove_check_constraint :features, name: "features_known_type"
    add_check_constraint :features, "feature_type IN ('new_expense', 'new_income', 'lens_laboratory')", name: "features_known_type"
  end

  private
    def feature_model
      @feature_model ||= Class.new(ActiveRecord::Base) do
        self.table_name = "features"
      end
    end

    def existing_feature_rows
      now = Time.current
      select_values("SELECT id FROM budgets").product(ADDED_TYPES).map do |budget_id, feature_type|
        { budget_id:, feature_type:, favorite: false, created_at: now, updated_at: now }
      end
    end
end
