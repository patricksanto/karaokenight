module Rooms
  class ReactionsController < ApplicationController
    include RateLimitable

    before_action :require_room!
    before_action :require_participant!

    # Rate limit: máx 10 reactions em 5 segundos por participante
    rate_limit action: [:create], to: 10, within: 5.seconds

    def create
      performance = current_room.performances.active.first
      return head :unprocessable_entity unless performance
      return head :unprocessable_entity unless Reaction::KINDS.include?(params[:kind])

      Reaction.create!(
        performance:  performance,
        participant:  current_participant,
        kind:         params[:kind]
      )

      RoomBroadcast.reaction_sent(current_room, performance, params[:kind])
      head :ok
    end
  end
end
