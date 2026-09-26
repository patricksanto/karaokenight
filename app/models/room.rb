class Room < ApplicationRecord
  has_secure_password :host_token, validations: false

  has_many :participants, dependent: :destroy
  has_many :song_requests, dependent: :destroy
  has_many :performances, dependent: :destroy

  enum :status, { open: 0, closed: 1 }

  validates :code, presence: true, uniqueness: true
  validates :code, length: { is: 6 }, format: { with: /\A[A-HJ-NP-Z2-9]{6}\z/, message: "contém caracteres inválidos" }

  before_validation :generate_code, on: :create
  before_create :generate_host_token

  def to_param
    code
  end

  def active_performance
    performances.find_by(status: [:performing, :closing])
  end

  def current_performance
    performances.where(status: [:performing, :closing]).order(created_at: :desc).first
  end

  private

  def generate_code
    return if code.present?
    loop do
      self.code = SecureRandom.alphanumeric(6).upcase.gsub(/[01IO]/, "") { |c| {"0"=>"2","1"=>"2","I"=>"3","O"=>"4"}[c] }
      self.code = SecureRandom.alphanumeric(6).upcase while self.code.length != 6
      break unless Room.exists?(code: code)
    end
  end

  def generate_host_token
    self.host_token = SecureRandom.hex(32)
  end
end
