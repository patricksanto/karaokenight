class RoomChannel < ApplicationCable::Channel
  def subscribed
    room = Room.find_by(code: params[:room_code])
    return reject unless room

    stream_from "room_#{room.code}"
  end

  def unsubscribed
  end
end
