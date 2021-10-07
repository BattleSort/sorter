class RoomController < ApplicationController
  def index
  end
  def categories
    render json: Category.all.map{|e|{id: e.id,name: e.name}}.to_json
  end
end
