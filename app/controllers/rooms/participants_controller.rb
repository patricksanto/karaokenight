module Rooms
  class ParticipantsController < ApplicationController
    before_action :require_room!
    before_action :require_participant!

    def stage
      @performance = current_room.current_performance
      @queue = QueueOrder.new(current_room).call.first(5)
      @is_singer = @performance && @performance.singers.include?(current_participant)
      @is_next = @queue.first && @queue.first.participant_id == current_participant.id
    end

    def queue
      @queue = QueueOrder.new(current_room).call
      @position = @queue.index { |sr| sr.participant_id == current_participant.id }
    end

    def my_songs
      @my_songs = current_participant.song_requests.where(room: current_room).order(created_at: :desc)
      @song_request = SongRequest.new
    end

    def toggle_availability
      current_participant.update!(available: !current_participant.available?)
      RoomBroadcast.queue_changed(current_room)
      redirect_to room_stage_path(current_room)
    end
  end
end
