class CreateCybercats < ActiveRecord::Migration[8.0]
  def change
    create_table :cybercats do |t|
      t.timestamps
    end

    remove_index :lenses, name: "index_one_singleton_lens_type_per_budget"
    add_index :lenses, %i[ budget_id lensable_type ], unique: true,
      where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover', 'Cybercat')",
      name: "index_one_singleton_lens_type_per_budget"
  end
end
