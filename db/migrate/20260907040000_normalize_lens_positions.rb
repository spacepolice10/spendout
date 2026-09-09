class NormalizeLensPositions < ActiveRecord::Migration[8.1]
  def up
    lens_class = Class.new(ActiveRecord::Base) { self.table_name = "lenses" }

    lens_class.distinct.pluck(:budget_id).each do |budget_id|
      lens_class.where(budget_id:).order(:position, :created_at, :id).each_with_index do |lens, position|
        lens.update_columns(position:)
      end
    end

    add_index :lenses, [ :budget_id, :position ]
  end

  def down
    remove_index :lenses, [ :budget_id, :position ]
  end
end
