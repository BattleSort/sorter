class Problem
    include ActiveModel::Model
    attr_accessor :id, :name, :elements, :answer
    def to_client
        {
            id: id,
            name: name,
            elements: elements
        }
    end
end
