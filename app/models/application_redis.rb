class ApplicationRedis
    attr_accessor :id
    include ActiveModel::Model

    def save
        REDIS.set(self.class.name+id, self.to_json)
        self
    end

    def delete
        REDIS.del(self.class.name+id)
    end

    def self.find!(key)
        raise "idがないぞ" unless key && r = REDIS.get(self.name+key)
        new(JSON.parse(r, symbolize_names: true))
    end
end
