class RenameRateWatchesToRateInfos < ActiveRecord::Migration[8.1]
  def up
    rename_table :rate_watches, :rate_infos

    execute <<~SQL
      UPDATE lenses
      SET lensable_type = 'RateInfo'
      WHERE lensable_type = 'RateWatch'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE lenses
      SET lensable_type = 'RateWatch'
      WHERE lensable_type = 'RateInfo'
    SQL

    rename_table :rate_infos, :rate_watches
  end
end
