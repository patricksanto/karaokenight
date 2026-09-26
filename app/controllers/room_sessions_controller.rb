class RoomSessionsController < ApplicationController
  before_action :require_room!

  def new
    redirect_to room_stage_path(current_room) if participant_signed_in?
  end

  def create
    nickname = params[:nickname].to_s.strip
    emoji    = params[:emoji].presence || "🎤"

    if nickname.length < 2 || nickname.length > 24
      redirect_to new_room_session_path(current_room)
      return
    end

    if current_room.participants.active.exists?(["LOWER(nickname) = ?", nickname.downcase])
      redirect_to new_room_session_path(current_room)
      return
    end

    token = SecureRandom.hex(32)
    participant = current_room.participants.create!(
      nickname: nickname,
      emoji:    emoji,
      session_token: token,
      available: true
    )

    session[:participant_id] = participant.id

    redirect_to room_stage_path(current_room)
  end
end
