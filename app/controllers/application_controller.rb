class ApplicationController < ActionController::Base
  skip_forgery_protection
  helper_method :current_participant, :current_room, :participant_signed_in?

  private

  def current_room
    @current_room ||= begin
      code = params[:room_code] || params[:room_id] || params[:id] || params[:code]
      Room.find_by(code: code) if code
    end
  end

  def current_participant
    @current_participant ||= resolve_current_participant
  end

  def resolve_current_participant
    participant_id = session[:participant_id]
    return nil unless participant_id

    participant = Participant.find_by(id: participant_id)
    return nil unless participant
    return nil if participant.revoked?
    return nil if current_room && participant.room_id != current_room.id

    participant
  end

  def participant_signed_in?
    current_participant.present?
  end

  def require_participant!
    unless participant_signed_in?
      redirect_to new_room_session_path(current_room)
    end
  end

  def require_room!
    unless current_room
      redirect_to root_path
    end
  end
end
