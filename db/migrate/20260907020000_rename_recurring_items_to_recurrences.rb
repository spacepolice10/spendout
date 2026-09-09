class RenameRecurringItemsToRecurrences < ActiveRecord::Migration[8.0]
  def up
    rename_table :recurring_items, :recurrences
    rename_column :recurring_occurrences, :recurring_item_id, :recurrence_id
    rename_table :upcoming_recurring_items, :upcoming_recurrences

    execute <<~SQL.squish
      UPDATE lenses
      SET lensable_type = 'UpcomingRecurrences'
      WHERE lensable_type = 'UpcomingRecurringItems'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE lenses
      SET lensable_type = 'UpcomingRecurringItems'
      WHERE lensable_type = 'UpcomingRecurrences'
    SQL

    rename_table :upcoming_recurrences, :upcoming_recurring_items
    rename_column :recurring_occurrences, :recurrence_id, :recurring_item_id
    rename_table :recurrences, :recurring_items
  end
end
