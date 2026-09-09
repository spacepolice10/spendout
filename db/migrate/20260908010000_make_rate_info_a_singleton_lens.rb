class MakeRateInfoASingletonLens < ActiveRecord::Migration[8.1]
  def change
    remove_index :lenses, name: "index_one_singleton_lens_type_per_budget"
    add_index :lenses, %i[ budget_id lensable_type ], unique: true,
      where: "lensable_type IN ('SourceHolder', 'PlanOverview', 'Rollover', 'Cybercat', 'RateInfo')",
      name: "index_one_singleton_lens_type_per_budget"
  end
end
