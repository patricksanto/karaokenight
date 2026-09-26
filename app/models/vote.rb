class Vote < ApplicationRecord
  belongs_to :performance
  belongs_to :participant

  validates :score, presence: true, inclusion: { in: 0..10 }
  validates :message, length: { maximum: 140 }
  validates :participant_id, uniqueness: { scope: :performance_id }

  validate :performance_is_open_for_voting
  validate :participant_is_eligible

  private

  def performance_is_open_for_voting
    return unless performance
    if performance.status == "revealed"
      errors.add(:base, "Votação encerrada")
    elsif performance.voting_closed?
      errors.add(:base, "Prazo de votação encerrado")
    end
  end

  def participant_is_eligible
    return unless performance && participant
    if performance.performance_singers.exists?(participant: participant)
      errors.add(:base, "Cantores não podem votar na própria apresentação")
    end
  end
end
