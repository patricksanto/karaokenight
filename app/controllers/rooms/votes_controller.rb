module Rooms
  class VotesController < ApplicationController
    include RateLimitable

    before_action :require_room!
    before_action :require_participant!
    rate_limit action: [:create, :update], to: 20, within: 10.seconds

    def create
      performance = current_room.performances.find(params[:performance_id])
      vote = performance.votes.find_or_initialize_by(participant: current_participant)
      vote.assign_attributes(vote_params)

      if vote.save
        RoomBroadcast.vote_registered(current_room, performance)
        redirect_to room_stage_path(current_room)
      else
        redirect_to room_stage_path(current_room)
      end
    end

    def update
      performance = current_room.performances.find(params[:performance_id])
      vote = performance.votes.find_by!(participant: current_participant)

      if vote.update(vote_params)
        RoomBroadcast.vote_registered(current_room, performance)
        redirect_to room_stage_path(current_room)
      else
        redirect_to room_stage_path(current_room)
      end
    end

    private

    def vote_params
      params.require(:vote).permit(:score, :message)
    end
  end
end
