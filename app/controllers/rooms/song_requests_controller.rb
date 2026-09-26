module Rooms
  class SongRequestsController < ApplicationController
    include RateLimitable

    before_action :require_room!
    before_action :require_participant!, except: [:play]
    rate_limit action: [:create, :cancel], to: 10, within: 1.minute

    def create
      @song_request = current_room.song_requests.new(song_request_params)
      @song_request.participant = current_participant

      singer = SongRequestSinger.new(song_request: @song_request, participant: current_participant)

      if @song_request.save && singer.save
        RoomBroadcast.queue_changed(current_room)
        redirect_to room_my_songs_path(current_room)
      else
        redirect_to room_my_songs_path(current_room)
      end
    end

    def cancel
      @song_request = current_participant.song_requests.find(params[:id])
      if @song_request.queued?
        @song_request.update!(status: :cancelled)
        RoomBroadcast.queue_changed(current_room)
        redirect_to room_my_songs_path(current_room)
      else
        redirect_to room_my_songs_path(current_room)
      end
    end

    def play
      @song_request = current_room.song_requests.queued.find(params[:id])

      # Cancela performance ativa se existir
      active_performance = current_room.performances.active.first
      if active_performance
        active_performance.update!(status: :aborted)
        # Marca como completed para não voltar para a fila
        active_performance.song_request.update!(status: :completed)
      end
      
      # Marca música como performing
      @song_request.update!(status: :performing)
      
      # Cria nova performance
      performance = Performance.create!(
        room: current_room,
        song_request: @song_request,
        status: :performing,
        started_at: Time.current
      )
      
      PerformanceSinger.create!(performance: performance, participant: @song_request.participant)
      
      # Broadcast para todas as telas
      RoomBroadcast.performance_started(current_room)
      RoomBroadcast.queue_changed(current_room)

      redirect_to room_projector_path(current_room.code)
    end

    private

    def song_request_params
      params.require(:song_request).permit(:title, :artist)
    end
  end
end
