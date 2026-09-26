class SongRequestSinger < ApplicationRecord
  belongs_to :song_request
  belongs_to :participant

  validates :participant_id, uniqueness: { scope: :song_request_id }
end
