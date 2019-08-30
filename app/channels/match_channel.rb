class MatchChannel < ApplicationCable::Channel
  PLAYER_NUMBER = 2
  # user_idのkeyで生きているかを管理
  # レベルとカテゴリのキーでユーザーを詰めていき、2以上いたら始める
  def subscribed
    stream_from "match" # 全員用
    stream_from "match#{user_id}" #各自用
    REDIS.set(user_id,"alive")

    # 対戦サーバーが取り出してマッチングさせてもいいかも
    if REDIS.lpush(match_room_name, user_id) >= PLAYER_NUMBER
      players = []
      PLAYER_NUMBER.times{players.push(REDIS.rpop(match_room_name))}

      #  TODO: 存在するか調べてもし全員存在しなかった場合は、rpushで右からキューに詰めてあげるほうが親切
      unless players.all?{|e|REDIS.del(e)==1}
        return players.each{|e|abort_match(e)}
      end
      players.each do |player|
        start_match(player,players.reject{|e|e==player})
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
