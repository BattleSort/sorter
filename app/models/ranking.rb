class Ranking < ApplicationRecord
    def create_problem(size = 3)
        elms = elements.split(',')
        indices = [*0..(elms.size-1)].sample(size)
        ordered_elements = elms.values_at(*indices)
        answer = Digest::MD5.hexdigest(ordered_elements.join)
        # TODO: 同率順位を考慮するためにはどうしよう。めんどいから後々でいいか。同率なんてそんなないっしょ。
        Problem.new(
            id: SecureRandom.uuid,
            name: name,
            elements: ordered_elements.shuffle,
            answer: answer
        )
    end
end
