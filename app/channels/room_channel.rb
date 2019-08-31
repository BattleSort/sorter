class RoomChannel < ApplicationCable::Channel
  PROBLEM_NUMBER = 3
  def subscribed
    stream_from room_channel # ルーム内全員
    stream_from user_channel # ユーザーと1on1

    pp 8789297228
    return unless REDIS.get(params[:room_id])
    # レディスでカウントして全員揃ったら問題配信か
    pp room_info
    # 全員揃ったら
    # これもワーカーでもできる
    if REDIS.incr(room_channel).to_i.tap{|e|p e} >= room_info[:count].tap{|e|p e}
      pp 12312312
      battle_start
      REDIS.del(room_channel)
      REDIS.del(params[:room_id])
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private
  def battle_start
    # problemsで実際に問題が解けるくらいの構造的なデータを渡す
    # TODO: 何から問題数は決まるんやろ

    # NOTE: 各問題の要素数、だんだん増えていくと競技として面白そう。
    # TODO: カテゴリに合ったランキングを取得する仕組み
    problems = PROBLEM_NUMBER.times.map{Ranking.first.create_problem}
    # problems = [Problem.mock, Problem.mock, Problem.mock, Problem.mock]
    problems.each do |problem|
      REDIS.set(problem.id, problem.answer)
    end
    
    ActionCable.server.broadcast room_channel, message: "試合開始！", problems: problems.map(&:to_client), type: "battleStart"
  end
  def room_channel
    "room-#{params[:room_id]}"
  end

  def user_channel
    "user-#{params[:user_id]}"
  end

  # level, category, count
  def room_info
    @room_info ||= JSON.parse( REDIS.get(params[:room_id]),symbolize_names: true )
  end
end
