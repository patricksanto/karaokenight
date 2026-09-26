class Participant < ApplicationRecord
  has_secure_password :session_token, validations: false

  belongs_to :room
  has_many :song_requests, dependent: :destroy
  has_many :song_request_singers, dependent: :destroy
  has_many :performance_singers, dependent: :destroy
  has_many :performance_voters, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :nickname, presence: true, length: { in: 2..24 }
  validates :nickname, uniqueness: { scope: :room_id, case_sensitive: false }
  validates :emoji, presence: true

  scope :active, -> { where(revoked_at: nil) }
  scope :available, -> { active.where(available: true) }

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def completed_performances_count
    performance_singers.joins(:performance).where(performances: { status: :revealed }).count
  end

  def pending_song_requests
    song_requests.where(status: :queued)
  end
end
