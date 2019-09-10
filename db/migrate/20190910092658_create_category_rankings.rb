class CreateCategoryRankings < ActiveRecord::Migration[6.0]
  def change
    create_table :category_rankings do |t|
      t.references :category, null: false, foreign_key: true
      t.references :ranking, null: false, foreign_key: true

      t.timestamps
    end
  end
end
