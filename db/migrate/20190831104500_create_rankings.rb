class CreateRankings < ActiveRecord::Migration[6.0]
  def change
    create_table :rankings do |t|
      t.string :name
      t.string :elements
      t.string :category

      t.timestamps
    end
  end
end
