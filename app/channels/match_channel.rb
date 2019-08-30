class MatchChannel < ApplicationCable::Channel
  PLAYER_NUMBER = 3
  # user_idのkeyで生きているかを管理
  # レベルとカテゴリのキーでユーザーを詰めていき、2以上いたら始める
  def subscribed
    stream_from "match" # 全員用
    stream_from "match#{user_id}" #各自用
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

      players.each do |player|
        start_match(player,players.reject{|e|e==player})
        REDIS.del(player)
      end
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    REDIS.del(user_id)
  end

  def start_match(owner, opponent)
    ActionCable.server.broadcast "match#{owner}", "対戦相手が見つかりました#{opponent} room_id: hogehoge"

  end

  def abort_match(owner)
    ActionCable.server.broadcast "match#{owner}", "対戦相手が通信を切断しました"
  end

  def all(message)
    ActionCable.server.broadcast "match", message
  end

  def personal(message)
    ActionCable.server.broadcast "match#{user_id}", message
  end

  def mes(message)
    ActionCable.server.broadcast "match", message: message
  end

  private
  def user_id
    params[:user_id].to_s
  end
  def match_room_name
    "#{params[:level]}-#{params[:category]}"
  end
end
