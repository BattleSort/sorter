class Ranking < ApplicationRecord
    has_many :category_rankings, dependent: :destroy
    
    def self.create_problems(num,size,category_id)
        # FIXME: これでいいんやろか
        category = Category.find(category_id)
        category.rankings.order("RANDOM()").limit(num).map{|e|e.create_problem(size)}
    end

    def create_problem(size = 8)
        elms = elements.split(',')
        indices = [*0..(elms.size-1)].sample(size).sort
        ordered_elements = elms.values_at(*indices)
        p ordered_elements
        answer = Digest::MD5.hexdigest(ordered_elements.join(""))
        # TODO: 同率順位を考慮するためにはどうしよう。めんどいから後々でいいか。同率なんてそんなないっしょ。
        Problem.new(
            id: SecureRandom.uuid,
            name: name,
            right_elements: ordered_elements,
            elements: ordered_elements.shuffle,
            answer: answer
        ).save
    end
end
