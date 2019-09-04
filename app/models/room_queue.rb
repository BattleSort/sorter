class RoomQueue
    attr_accessor :room_key 
    def initialize(h)
        self.room_key = h[:room_key]    
    end

    # return list length
    def push(user_id)
        # リストに入っている間にユーザーが死ぬ可能性があるので生死の管理をする
        enable_user(user_id)
        # 後から来た人が左から詰められる
        REDIS.lpush(room_key, user_id)
    end

    # 有効なプレイヤーを返す。内部的には一旦取り出して、切断されていたらならキューの先頭に詰め直している。
    def get_players(player_number)
        players = player_number.times.map{REDIS.rpop(room_key)}
        alives, deads = players.partition{|e|user_enabled?(e)}
        if alives.size != player_number
            alives.each{|e|REDIS.rpush(room_key, e)}
            nil
        else
            alives.each{|e|disable_user(e)}
        end
    end

    def disable_user(user_id)
        REDIS.del(room_user_key(user_id))
    end

    private
    def room_user_key(user_id)
        room_key+"-"+user_id
    end

    def enable_user(user_id)
        REDIS.set(room_user_key(user_id),"alive")
    end
    
    def user_enabled?(user_id)
        REDIS.exists(room_user_key(user_id))
    end
end
