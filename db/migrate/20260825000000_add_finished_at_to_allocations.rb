class AddFinishedAtToAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :allocations, :finished_at, :datetime
    add_index :allocations, :finished_at
  end
end
