class MatchChannel < ApplicationCable::Channel
  PLAYER_NUMBER = 2
  # user_idのkeyで生きているかを管理
  # レベルとカテゴリのキーでユーザーを詰めていき、2以上いたら始める
  def subscribed
    stream_from "match" # 全員用
    stream_from user_room(user_id) #各自用
    REDIS.set(user_id,"alive")
    personal("hello #{user_id}")
    # 対戦サーバーが取り出してマッチングさせてもいいかも
    num = REDIS.lpush(match_room_name, user_id)
    if num >= PLAYER_NUMBER
      players = []
      PLAYER_NUMBER.times{players.push(REDIS.rpop(match_room_name))}
      mes("player #{players}")
      alives, deads = players.partition{|e|REDIS.exists(e)}
      if alives.size != PLAYER_NUMBER
        alives.each do |player|
          personal player
          REDIS.rpush(match_room_name, player)
        end
        deads.each do |player|
          personal "message #{player}"
          REDIS.del(player)
        end
        return
      end
      # 部屋の成立
      room_id = SecureRandom.uuid
      REDIS.set(room_id, room_hash.merge(count: players.size).to_json)
      players.each do |player|
        start_match(player,players.reject{|e|e==player},room_id)
        REDIS.del(player)
      end
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    REDIS.del(user_id)
  end

  def start_match(owner, opponent,room_id)
    # 受け取りやすいデータ構造で
    ActionCable.server.broadcast user_room(owner), type: "moveRoom", message: "対戦相手が見つかりました#{opponent}", room_id: room_id
  end

  def abort_match(owner)
    ActionCable.server.broadcast user_room(owner), "対戦相手が通信を切断しました"
  end

  def all(message)
    ActionCable.server.broadcast "match", message
  end

  def personal(message)
    ActionCable.server.broadcast user_room(user_id), message
  end

  def mes(message)
    ActionCable.server.broadcast "match", message: message
  end

  private
  def user_id
    params[:user_id].to_s
  end
  
  def user_room(user_id)
    "match#{user_id}"
  end

  def match_room_name
    "#{params[:level]}-#{params[:category]}"
  end

  def room_hash
    {level: params[:level], category: params[:category]}
  end
end
