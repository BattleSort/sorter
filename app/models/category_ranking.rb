class CategoryRanking < ApplicationRecord
    belongs_to :ranking    
    belongs_to :category
    validates :category_id, :uniqueness => {:scope => :ranking_id}
end
