class Category < ApplicationRecord
    has_many :category_rankings
    has_many :rankings, through: :category_rankings
end
