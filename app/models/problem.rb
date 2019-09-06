class Problem
    include ActiveModel::Model
    attr_accessor :id, :name, :elements, :answer, :solved
    def to_client
        {
            id: id,
            name: name,
            elements: elements,
            solved: false
        }
    end
end
