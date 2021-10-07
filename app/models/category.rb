# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ApplicationRecord
  has_many :category_rankings, dependent: :destroy
  has_many :rankings, through: :category_rankings

  def sample_rankings(size)
    rankings.order("RANDOM()").limit(size)
  end
end
