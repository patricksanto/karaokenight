class HostController < ApplicationController
  before_action :require_room!
  before_action :authenticate_host!

  def show
    @room = current_room
    @participants = @room.participants.active.order(:nickname)
    @queue = QueueOrder.new(@room).call
    @performance = @room.current_performance
    @pending_requests = @room.song_requests.queued.includes(:participant).order(:created_at)
  end

  def authenticate
    token = params[:host_token].to_s
    if current_room&.authenticate_host_token(token)
      cookies.signed[:host_token] = { value: token, expires: 30.days, httponly: true }
      redirect_to room_host_path(current_room.code)
    else
      redirect_to root_path
    end
  end

  private

  def authenticate_host!
    token = cookies.signed[:host_token]
    unless token && current_room&.authenticate_host_token(token)
      redirect_to root_path
    end
  end
end
