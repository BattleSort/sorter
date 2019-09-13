class Problem < ApplicationRedis
    attr_accessor :name, :elements, :answer, :right_elements, :solved_users
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

    def push_solved_user(user_id, required_time)
        REDIS.lpush(solved_user_key, {user_id: user_id, required_time: required_time}.to_json)
    end

    def get_first_solve_user_id
        return nil unless delete # fでatomicに
        REDIS.lrange(solved_user_key, 0, -1)
             .map{|e|JSON.parse(e, symbolize_names: true)}
             .min_by{|a|a[:equired_time]}[:user_id]
    end

    private
    def solved_user_key
        "solved-#{id}"
    end
end
