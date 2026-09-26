class Performance < ApplicationRecord
  belongs_to :room
  belongs_to :song_request
  has_many :performance_singers, dependent: :destroy
  has_many :performance_voters, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :reactions, dependent: :destroy

  enum :status, { performing: 0, closing: 1, revealed: 2, aborted: 3 }

  validates :status, presence: true

  validate :only_one_active_performance, on: :create

  scope :active, -> { where(status: [:performing, :closing]) }

  def singers
    Participant.joins(:performance_singers).where(performance_singers: { performance_id: id })
  end

  def eligible_voters
    Participant.joins(:performance_voters).where(performance_voters: { performance_id: id })
  end

  def voting_closed?
    voting_closes_at.present? && Time.current >= voting_closes_at
  end

  def calculate_result!
    visible_votes = votes.where(hidden_at: nil)
    count = visible_votes.count
    avg = count > 0 ? visible_votes.average(:score).round(1) : nil
    messages = votes.where.not(message: [nil, ""]).where(hidden_at: nil).pluck(:id).shuffle
    update!(
      average_score: avg,
      votes_count: count,
      messages_order: messages.join(","),
      revealed_at: Time.current,
      status: :revealed
    )
    song_request.update!(status: :completed)
  end

  private

  def only_one_active_performance
    return unless room
    if room.performances.active.exists?
      errors.add(:base, "Já existe uma apresentação ativa nesta sala")
    end
  end
end
