class Room < ApplicationRedis
    attr_accessor :players, :level, :category, :problem_ids
    def initialize(h)
        self.players = h[:players]
        self.level = h[:level]
        self.category = h[:category]
        self.id = h[:id] || SecureRandom.uuid
        self.problem_ids = h[:problem_ids]
    end

    def join!(user_id)
        raise "想定外のユーザー" unless players.include? user_id
        REDIS.sadd(room_players_key, user_id)
    end

    def match?
        REDIS.scard(room_players_key) == players.size
    end

    def can_start?
        if REDIS.exists(room_status_key)
            return false
        else
            REDIS.set(room_status_key, "start")
            return true
        end
    end

    def can_submit?(user_id)
        REDIS.get(user_delay_key(user_id)).blank?
    end

    def disable_submit(user_id,sec)
        REDIS.setex(user_delay_key(user_id),sec,"wrong")
    end

    def result
        players.map{|e|{
            id: e,
            problems: User.find!(e).problems,
            score: User.find!(e).problems.size
        }}.tap{|e|pp e}.sort{|a,b|
            b[:score] - a[:score]
        }
    end

    def pop_problem
        tmp = self.problem_ids.shift
        save and tmp
    end

    private
    def room_players_key
        "room-players-#{id}"
    end

    def room_status_key
        "room-status-#{id}"
    end


    def user_delay_key(user_id)
        "user-delay-#{user_id}"
    end
end
