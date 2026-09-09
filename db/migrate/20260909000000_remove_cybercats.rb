class RemoveCybercats < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM lenses WHERE lensable_type = 'Cybercat'"
    drop_table :cybercats

    remove_index :lenses, name: "index_one_singleton_lens_type_per_budget"
    add_index :lenses, %i[ budget_id lensable_type ], unique: true,
      where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover', 'RateInfo')",
      name: "index_one_singleton_lens_type_per_budget"
  end

  def down
    create_table :cybercats do |t|
      t.timestamps
    end

    remove_index :lenses, name: "index_one_singleton_lens_type_per_budget"
    add_index :lenses, %i[ budget_id lensable_type ], unique: true,
      where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover', 'Cybercat', 'RateInfo')",
      name: "index_one_singleton_lens_type_per_budget"
  end
end
