module Rooms
  class PerformancesController < ApplicationController
    before_action :require_room!

    def start
      song_request = @room.song_requests.queued.find(params[:song_request_id])
      performance = Performance.new(
        room: @room,
        song_request: song_request,
        status: :performing,
        started_at: Time.current
      )

      if performance.save
        PerformanceSinger.create!(performance: performance, participant: song_request.participant)
        song_request.update!(status: :performing)

        eligible = @room.participants.available.where.not(id: song_request.participant_id)
        eligible.each do |voter|
          PerformanceVoter.create!(performance: performance, participant: voter)
        end

        RoomBroadcast.performance_started(@room)
        redirect_to room_host_path(@room.code)
      else
        redirect_to room_host_path(@room.code)
      end
    end

    def close
      performance = @room.performances.active.find(params[:id])
      performance.update!(status: :closing, voting_closes_at: 10.seconds.from_now)
      RoomBroadcast.performance_closed(@room)
      FinalizePerformanceJob.set(wait: 10.seconds).perform_later(performance.id)
      
      if request.format.json?
        render json: { status: 'ok' }
      else
        redirect_to room_host_path(@room.code)
      end
    end

    def finish
      performance = @room.performances.active.find(params[:id])
      performance.update!(
        status: :revealed,
        average_score: nil,
        votes_count: 0,
        revealed_at: Time.current
      )
      performance.song_request.update!(status: :completed)
      RoomBroadcast.performance_finalized(@room, performance)
      
      if request.format.json?
        render json: { status: 'ok' }
      else
        redirect_to room_projector_path(@room.code)
      end
    end

    def abort
      performance = @room.performances.active.find(params[:id])
      performance.update!(status: :aborted)
      performance.song_request.update!(status: :queued)
      RoomBroadcast.performance_aborted(@room)
      redirect_to room_host_path(@room.code)
    end

    private

    def require_room!
      @room = Room.find_by!(code: params[:room_id] || params[:room_code])
    end
  end
end
