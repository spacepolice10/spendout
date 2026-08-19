class RemoveSourceFromAllocations < ActiveRecord::Migration[8.1]
  def up
    remove_index :allocations, name: "index_allocations_on_source_id_and_deleted_at"
    remove_reference :allocations, :source, null: false, foreign_key: true
  end

  def down
    add_reference :allocations, :source, null: true, foreign_key: true
    add_index :allocations, [ :source_id, :deleted_at ]
  end
end
