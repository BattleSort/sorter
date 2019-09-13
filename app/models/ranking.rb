class Ranking < ApplicationRecord
  has_many :category_rankings, dependent: :destroy
end
