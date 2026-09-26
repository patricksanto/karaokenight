class ProjectorController < ApplicationController
  before_action :require_room!

  def show
    @room = current_room
    @performance = @room.performances.where(status: [:performing, :closing, :revealed]).order(updated_at: :desc).first
    @queue = QueueOrder.new(@room).call
    @active_voters = @room.participants.active.count
    @spotlight_message = @performance&.votes&.where&.not(message: [nil, ""])&.order("RANDOM()")&.first

    # QR code para entrar na sala
    join_url = "#{request.base_url}#{join_room_path(@room.code)}"
    @qr_code = RQRCode::QRCode.new(join_url)
  end
end
