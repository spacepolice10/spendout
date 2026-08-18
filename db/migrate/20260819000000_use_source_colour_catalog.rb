class UseSourceColourCatalog < ActiveRecord::Migration[8.1]
  def up
    change_column_default :sources, :colour, from: "hotpink", to: "green"
    execute "UPDATE sources SET colour = 'green' WHERE colour = 'hotpink'"
  end

  def down
    change_column_default :sources, :colour, from: "green", to: "hotpink"
  end
end
