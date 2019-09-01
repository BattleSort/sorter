class RoomChannel < ApplicationCable::Channel
  PROBLEM_NUMBER = 3
  def subscribed
    stream_from room_channel # ルーム内全員
    stream_from user_channel # ユーザーと1on1

    return unless REDIS.get(params[:room_id]) #既に揃っていたら何もしない
    # レディスでカウントして全員揃ったら問題配信か
    pp room_info
    # 全員揃ったら
    # これもワーカーでもできる
    if REDIS.incr(room_channel).to_i >= room_info[:count]
      battle_start
      REDIS.del(room_channel)
      REDIS.del(params[:room_id])
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def submit(hash)
    raise "何かがおかしい" unless REDIS.get(hash["problem_id"])
    p hash["answer"]
    p REDIS.get(hash["problem_id"])
    if REDIS.get(hash["problem_id"]) == hash["answer"]
      p "hello ac"
      ActionCable.server.broadcast room_channel, message: "#{hash["user_id"]}さんが#{hash["problem_id"]}を解きました", type: "notice"
    else
      p "hello wa"
      ActionCable.server.broadcast user_channel, message: "不正解です", type: "wrong answer"
    end
  end

  private
  def battle_start
    # problemsで実際に問題が解けるくらいの構造的なデータを渡す
    # TODO: 何から問題数は決まるんやろ

    # NOTE: 各問題の要素数、だんだん増えていくと競技として面白そう。
    # TODO: カテゴリに合ったランキングを取得する仕組み allじゃなくてidで絞り込む実装
    problems = PROBLEM_NUMBER.times.map{Ranking.all.sample.create_problem}
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
