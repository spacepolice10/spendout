class CreateFeatures < ActiveRecord::Migration[8.1]
  class MigrationFeature < ActiveRecord::Base
    self.table_name = "features"
  end

  def up
    create_table :features do |t|
      t.references :budget, null: false, foreign_key: true
      t.string :feature_type, null: false
      t.boolean :favorite, null: false, default: false
      t.timestamps
    end

    add_index :features, [ :budget_id, :feature_type ], unique: true
    add_check_constraint :features,
      "feature_type IN ('new_expense', 'new_income', 'lens_laboratory')",
      name: "features_known_type"

    budget_ids = select_values("SELECT id FROM budgets")
    now = Time.current
    rows = budget_ids.product(%w[ new_expense new_income lens_laboratory ]).map do |budget_id, feature_type|
      { budget_id:, feature_type:, favorite: false, created_at: now, updated_at: now }
    end
    MigrationFeature.insert_all!(rows) if rows.any?
  end

  def down
    drop_table :features
  end
end
