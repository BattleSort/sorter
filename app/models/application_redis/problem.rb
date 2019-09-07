class Problem < ApplicationRedis
    attr_accessor :name, :elements, :answer, :right_elements
    def to_client
        {
            id: id,
            name: name,
            elements: elements
        }
    end

    def correct?(sub)
        answer == sub
    end
end
