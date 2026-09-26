class FinalizePerformanceJob < ApplicationJob
  queue_as :default

  def perform(performance_id)
    performance = Performance.find_by(id: performance_id)
    return unless performance&.closing?
    return if performance.voting_closes_at.nil? || performance.voting_closes_at > Time.current

    votes = performance.votes
    if votes.any?
      average = votes.average(:score).to_f.round(1)
      messages = votes.where.not(message: [nil, ""]).order(:created_at).pluck(:id)

      performance.update!(
        status: :revealed,
        average_score: average,
        votes_count: votes.count,
        messages_order: messages.join(","),
        revealed_at: Time.current
      )
    else
      performance.update!(
        status: :revealed,
        average_score: nil,
        votes_count: 0,
        revealed_at: Time.current
      )
    end

    performance.song_request.update!(status: :completed)
    RoomBroadcast.performance_finalized(performance.room, performance)
  end
end
