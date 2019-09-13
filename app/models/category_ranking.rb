# == Schema Information
#
# Table name: category_rankings
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  ranking_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CategoryRanking < ApplicationRecord
  belongs_to :ranking
  belongs_to :category
  validates :category_id, uniqueness: { scope: :ranking_id }
end
