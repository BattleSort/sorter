class MatchChannel < ApplicationCable::Channel
  PLAYER_NUMBER = 2

  def subscribed
    raise "user_idがないってどういうことよ" unless user_id
    stream_from user_room(user_id) #各自用

    room_queue = RoomQueue.new(room_key: match_room_name)

    # OPTIMIZE: 対戦サーバーが取り出してマッチングさせてもいいかも
    return if room_queue.push(user_id) < PLAYER_NUMBER
    return unless players = room_queue.get_players(PLAYER_NUMBER)

    # 部屋の成立 ここらへんYAGNIな気も
    room = Room.new(
      players: players,
      level: params[:level],
      category: params[:category]
    )

    players.each do |player|
      start_match(player, players.reject{|e|e==player}, room.id)
    end
  end

  def unsubscribed
    RoomQueue.new(room_key: match_room_name).disable_user(user_id)
  end 

  private
  # DEBUG用: 自分以外のuser-idを教えると不正が行えてしまう
  def start_match(owner, opponent,room_id)
    ActionCable.server.broadcast user_room(owner), type: "moveRoom", message: "対戦相手が見つかりました#{opponent}", room_id: room_id
  end

  def user_id
    params[:user_id].to_s
  end
  
  def user_room(user_id)
    "match#{user_id}"
  end

  def match_room_name
    "#{params[:level]}-#{params[:category]}"
  end
end
