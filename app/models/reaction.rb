class Reaction < ApplicationRecord
  KINDS = %w[fire clap crown heart disco].freeze

  belongs_to :performance
  belongs_to :participant

  validates :kind, inclusion: { in: KINDS }

  scope :for_performance, ->(perf) { where(performance: perf) }

  # Returns { "fire" => 12, "clap" => 8, ... } for a given performance
  def self.counts_for(performance)
    KINDS.index_with { |k| where(performance: performance, kind: k).count }
  end
end
