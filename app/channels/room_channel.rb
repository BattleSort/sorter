class RoomChannel < ApplicationCable::Channel
  PROBLEM_NUMBER = 10
  WRONG_ANSWER_PENALTY_SECONDS = 3
  def subscribed 
    room = Room.find!(params[:room_id])
    room.join!(params[:user_id])

    stream_from user_channel # ユーザーと1on1のstream
    stream_from room_channel # ルーム内全員
    return unless room.match?
    return unless room.can_start? #既に始まっているかどうか

    # TODO: 全員集まったら部屋を入れなくしていて、リロードしたときに死ぬから、room_id、user_idの一致で問題を再配信するくらいの親切さがほしい。
    # 実装としてはroom_idの最後に配信した問題を再配信するという感じかな。

    ActionCable.server.broadcast room_channel, message: "試合開始！", type: "gameStart"

    # NOTE: 各問題の要素数、だんだん増えていくと競技として面白そう。
    # TODO: 問題が作られるのはランキングからだけでなく、数字、文字列から作られる可能性がある。Problemが共通のフォーマットとしてありたい。
    room.problem_ids = Ranking.create_problems(PROBLEM_NUMBER, room.level*4, room.category).map(&:id)
    deliver_problem room.pop_problem
  rescue StandardError => e
    ActionCable.server.broadcast user_channel, message: e if Rails.env.development?
    raise e
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def submit(hash)
    room = Room.find!(params[:room_id])
    problem = Problem.find!(hash["problem_id"])
    user = User.find!(params[:user_id])

    unless room.can_submit?(user.id,problem.id)
      ActionCable.server.broadcast user_channel, {
        message: "#{WRONG_ANSWER_PENALTY_SECONDS}秒以内に再提出はできません",
        type: "penalty"
      } and return
    end

    # 最初の人のみがdelete==1
    if problem.correct?(hash["answer"]) && problem.delete == 1
      ActionCable.server.broadcast room_channel, message: "#{user.id}さんが「#{problem.name}」を解きました", type: "notice"
      user.add_problem(problem) # TODO: socreの計算ロジック
      return if deliver_problem room.pop_problem

      ActionCable.server.broadcast room_channel, message: "ゲーム終了です", result: "#{room.result.to_json}", type: "gameEnd"
    else
      ActionCable.server.broadcast user_channel, message: "不正解です", type: "wrongAnswer"
      room.disable_submit(user.id,problem.id,WRONG_ANSWER_PENALTY_SECONDS)
    end
  rescue StandardError => e
    ActionCable.server.broadcast user_channel, message: e if Rails.env.development?
    raise e
  end

  private
  def deliver_problem(problem_id)
    return nil unless problem_id
    problem = Problem.find!(problem_id)
    ActionCable.server.broadcast room_channel, problem: problem.to_client, type: "deliverProblem"
    true
  end

  def room_channel
    "room-#{params[:room_id]}"
  end

  def user_channel
    "user-#{params[:user_id]}"
  end
end
