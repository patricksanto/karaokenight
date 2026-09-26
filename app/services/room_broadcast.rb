class RoomBroadcast
  # Broadcast quando a fila muda
  def self.queue_changed(room)
    broadcast(room, type: "queue_changed", html: render_queue(room))
  end

  # Broadcast quando uma performance começa
  def self.performance_started(room)
    performance = room.performances.performing.first
    return unless performance
    broadcast(room, type: "performance_started", html: render_stage(room, performance))
  end

  # Broadcast quando a votação fecha (status: closing)
  def self.performance_closed(room)
    performance = room.performances.closing.first
    return unless performance
    broadcast(room, type: "stage_update", html: render_stage(room, performance))
  end

  # Broadcast quando a performance é finalizada e o resultado revelado
  def self.performance_finalized(room, performance)
    broadcast(room, type: "stage_update", html: render_stage(room, performance))
  end

  # Broadcast quando a performance é abortada
  def self.performance_aborted(room)
    broadcast(room, type: "stage_update", html: render_stage(room, nil))
    broadcast(room, type: "queue_changed", html: render_queue(room))
  end

  # Broadcast quando um voto é registado (atualiza score ao vivo e mensagem flutuante)
  def self.vote_registered(room, performance)
    avg = performance.votes.average(:score)&.round(1)
    last_vote = performance.votes.order(created_at: :desc).first
    broadcast(room,
      type:          "vote_update",
      votes_count:   performance.votes.count,
      average_score: avg,
      message:       last_vote&.message.presence
    )
  end

  # Broadcast quando uma reaction é enviada (atualiza contadores em tempo real)
  def self.reaction_sent(room, performance, kind)
    broadcast(room,
      type:      "reaction_update",
      counts:    Reaction.counts_for(performance),
      total:     performance.reactions.count,
      last_kind: kind
    )
  end

  private

  def self.broadcast(room, payload)
    ActionCable.server.broadcast("room_#{room.code}", payload)
  end

  def self.render_stage(room, performance)
    ApplicationController.render(
      partial: "rooms/participants/stage_state",
      locals: {
        room: room,
        performance: performance,
        is_singer: false,
        is_next: false
      },
      formats: [:html]
    )
  rescue => e
    Rails.logger.error "[RoomBroadcast] render_stage failed: #{e.message}"
    ""
  end

  def self.render_queue(room)
    ApplicationController.render(
      partial: "rooms/participants/queue_content",
      locals: { room: room },
      formats: [:html]
    )
  rescue => e
    Rails.logger.error "[RoomBroadcast] render_queue failed: #{e.message}"
    ""
  end
end
