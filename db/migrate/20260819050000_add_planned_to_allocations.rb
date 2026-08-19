class AddPlannedToAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :allocations, :planned, :boolean, null: false, default: true
  end
end
