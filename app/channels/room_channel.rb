class RoomChannel < ApplicationCable::Channel
  PROBLEM_NUMBER = 3
  WRONG_ANSWER_PENALTY_SECONDS = 10
  def subscribed
    stream_from room_channel # ルーム内全員
    stream_from user_channel # ユーザーと1on1

    # TODO: 全員集まったら部屋を消す感じにしてるけど、リロードしたときに死ぬから、room_id、user_idの一致で問題を再配信するくらいの親切さがほしい。
    return unless REDIS.get(params[:room_id]) #既に揃っていたら何もしない
    # レディスでカウントして全員揃ったら問題配信か
    pp room_info
    # 全員揃ったら
    # これもワーカーでもできる
    if REDIS.incr(room_incr_key).to_i >= room_info[:count]
      battle_start
      REDIS.del(room_incr_key)
      REDIS.del(params[:room_id])
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def submit(hash)
    # TODO: user_idとか推測されないやつにしないと他のユーザーのフリして回答できちゃう
    # TODO: token的なのと照合して操作しないと基本的にガバガバ
    # user_idはparamからとれるか
    raise "何かがおかしい" unless REDIS.get(hash["problem_id"])

    # 提出済みkeyが残っていたら弾く
    if REDIS.get(user_delay_key).present? 
      ActionCable.server.broadcast user_channel, message: "10秒以内に再提出はできません", type: "penalty"
      return
    end
    # 既に解いてたら飛ばす
    if REDIS.ismember(hash["user_id"],hash["problem_id"])
      # クライアント側で弾くことを期待したい
      ActionCable.server.broadcast user_channel, message: "提出済みです", type: "already"
    end

    if REDIS.get(hash["problem_id"]) == hash["answer"]
      p "hello ac"
      ActionCable.server.broadcast room_channel, message: "#{hash["user_id"]}さんが#{hash["problem_id"]}を解きました", type: "notice"
      # 解いた問題の集合、saddで重複されないから連続して送信されたとしても大丈夫
      REDIS.sadd(hash["user_id"], hash["problem_id"])
    else
      p "hello wa"
      ActionCable.server.broadcast user_channel, message: "不正解です", type: "wrong answer"
      REDIS.setex(user_delay_key,WRONG_ANSWER_PENALTY_SECONDS,"wrong")
    end

    if REDIS.scard(hash["user_id"]) >= PROBLEM_NUMBER
      end_battle hash["user_id"]
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
      # 問題名とか知りたいし、hashにして保存しておいてもいいかも
      REDIS.set(problem.id, problem.answer)
    end
    
    ActionCable.server.broadcast room_channel, message: "試合開始！", problems: problems.map(&:to_client), type: "battleStart"
  end

  def end_battle(user_id)
    ActionCable.server.broadcast room_channel, message: "#{user_id}さんが全問解きました。試合終了です。", type: "battleEnd", user_id: user_id
  end

  def room_channel
    "room-#{params[:room_id]}"
  end

  def user_channel
    "user-#{params[:user_id]}"
  end

  def room_incr_key
    "room-incr-#{params[:room_id]}"
  end

  def user_delay_key
    "user-delay-#{params[:user_id]}"
  end

  # level, category, count
  def room_info
    @room_info ||= JSON.parse( REDIS.get(params[:room_id]),symbolize_names: true )
  end
end
