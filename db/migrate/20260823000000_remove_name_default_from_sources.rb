class RemoveNameDefaultFromSources < ActiveRecord::Migration[8.0]
  def up
    change_column_default :sources, :name, from: "Main source", to: nil
  end

  def down
    change_column_default :sources, :name, from: nil, to: "Main source"
  end
end
