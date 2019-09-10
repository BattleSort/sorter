class Category < ApplicationRecord
    has_many :category_rankings, dependent: :destroy
    has_many :rankings, through: :category_rankings
end
