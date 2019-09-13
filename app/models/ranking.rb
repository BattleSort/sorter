# == Schema Information
#
# Table name: rankings
#
#  id         :integer          not null, primary key
#  name       :string
#  elements   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Ranking < ApplicationRecord
  has_many :category_rankings, dependent: :destroy
end
