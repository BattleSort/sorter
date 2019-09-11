class Room < ApplicationRedis
    attr_accessor :user_ids, :level, :category, :problem_ids
    def initialize(h)
        self.user_ids = h[:user_ids]
        self.level = h[:level]
        self.category = h[:category]
        self.id = h[:id] || SecureRandom.uuid
        self.problem_ids = h[:problem_ids]
    end

    def join!(user_id)
        raise "想定外のユーザー" unless user_ids.include? user_id
        REDIS.sadd(room_user_ids_key, user_id)
    end

    def match?
        REDIS.scard(room_user_ids_key) == user_ids.size
    end

    def can_start?
        if REDIS.exists(room_status_key)
            return false
        else
            REDIS.set(room_status_key, "start")
            return true
        end
    end

    def can_submit?(user_id,problems_id)
        REDIS.get(user_delay_key(user_id,problems_id)).blank?
    end

    def disable_submit(user_id,problems_id,sec)
        REDIS.setex(user_delay_key(user_id,problems_id),sec,"wrong")
    end

    def result
        user_ids.map{|e|{
            id: e,
            problems: User.find!(e).problems,
            score: User.find!(e).problems.size
        }}.sort{|a,b|
            b[:score] - a[:score]
        }
    end

    def pop_problem
        tmp = problem_ids.shift
        save and tmp
    end

    private
    def room_user_ids_key
        "room-user_ids-#{id}"
    end

    def room_status_key
        "room-status-#{id}"
    end

    def user_delay_key(user_id, problems_id)
        "user-delay-#{user_id}-#{problems_id}"
    end
end
