class PerformanceVoter < ApplicationRecord
  belongs_to :performance
  belongs_to :participant

  validates :participant_id, uniqueness: { scope: :performance_id }
end
