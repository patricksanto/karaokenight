class QueueOrder
  def initialize(room)
    @room = room
  end

  def call
    pending_requests = @room.song_requests.queued.includes(:participant).order(:created_at)
    return [] if pending_requests.empty?

    available_participants = @room.participants.available.pluck(:id)
    requests_by_participant = pending_requests.group_by(&:participant_id)

    last_singer_id = last_completed_performance_singer_id

    queue = []
    simulated_counts = Hash.new(0)
    remaining_requests = requests_by_participant.dup

    while remaining_requests.any?
      candidates = remaining_requests.select do |participant_id, requests|
        next false unless available_participants.include?(participant_id)
        next false if participant_id == last_singer_id && remaining_requests.size > 1
        true
      end

      break if candidates.empty?

      next_request = candidates.min_by do |participant_id, requests|
        [
          simulated_counts[participant_id],
          requests.first.created_at,
          participant_id
        ]
      end

      participant_id = next_request.first
      request = next_request.second.first

      queue << request
      simulated_counts[participant_id] += 1
      last_singer_id = participant_id

      remaining_requests[participant_id] = remaining_requests[participant_id][1..]
      remaining_requests.delete(participant_id) if remaining_requests[participant_id].empty?
    end

    queue
  end

  private

  def last_completed_performance_singer_id
    last_performance = @room.performances.revealed.order(:revealed_at).last
    return nil unless last_performance
    last_performance.performance_singers.first&.participant_id
  end
end
