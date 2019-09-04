class Room
    attr_accessor :players, :id, :level, :category
    def initialize(h)
        self.id = SecureRandom.uuid
        self.players = h[:players]
        REDIS.set(id, self.to_json)
    end
end
