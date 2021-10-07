class RemoveCategoryFromRanking < ActiveRecord::Migration[6.0]
  def change
    remove_column :rankings, :category, :string
  end
end
