class SongRequest < ApplicationRecord
  belongs_to :room
  belongs_to :participant
  has_one :song_request_singer, dependent: :destroy
  has_one :performance, dependent: :nullify

  enum :status, { queued: 0, performing: 1, completed: 2, cancelled: 3 }

  validates :title, presence: true, length: { maximum: 120 }
  validates :artist, presence: true, length: { maximum: 120 }

  validate :limit_pending_requests, on: :create

  scope :pending, -> { where(status: [:queued, :performing]) }

  private

  def limit_pending_requests
    return unless participant
    pending_count = participant.song_requests.where(status: :queued).count
    errors.add(:base, "Limite de 2 pedidos pendentes atingido") if pending_count >= 2
  end
end
