class RoomsController < ApplicationController
  def new
    @room = Room.new
  end

  def create
    @room = Room.new(room_params)
    @room.status = :open

    if @room.save
      cookies.signed[:host_token] = { value: @room.host_token, expires: 30.days, httponly: true }
      redirect_to room_host_path(@room.code)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    @room = Room.find_by(code: params[:id])
    unless @room
      redirect_to root_path
      return
    end
    if @room.closed?
      redirect_to root_path
      return
    end
    redirect_to new_room_session_path(@room)
  end

  def enter
    code = params[:code].to_s.strip.upcase
    room = Room.find_by(code: code)

    if room.nil?
      redirect_to root_path
    elsif room.closed?
      redirect_to root_path
    else
      redirect_to new_room_session_path(room)
    end
  end

  private

  def room_params
    params.require(:room).permit(:name)
  end
end
