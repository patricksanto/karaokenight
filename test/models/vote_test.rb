require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup do
    @room = Room.create!(
      code: "TEST23",
      name: "Test Room",
      status: :open,
      host_token_digest: BCrypt::Password.create("secret")
    )

    @singer = Participant.create!(room: @room, nickname: "Singer", emoji: "🎤", session_token_digest: "token1")
    @voter = Participant.create!(room: @room, nickname: "Voter", emoji: "🎸", session_token_digest: "token2")

    @song_request = SongRequest.create!(room: @room, participant: @singer, title: "Test Song", artist: "Artist", status: :performing)
    SongRequestSinger.create!(song_request: @song_request, participant: @singer)

    @performance = Performance.create!(
      room: @room,
      song_request: @song_request,
      status: :performing,
      started_at: Time.current
    )
    PerformanceSinger.create!(performance: @performance, participant: @singer)
    PerformanceVoter.create!(performance: @performance, participant: @voter)
  end

  test "cantor não pode votar na própria apresentação" do
    vote = Vote.new(performance: @performance, participant: @singer, score: 10)

    assert_not vote.valid?
    assert_includes vote.errors[:base], "Cantores não podem votar na própria apresentação"
  end

  test "votante elegível pode votar" do
    vote = Vote.new(performance: @performance, participant: @voter, score: 8, message: "Great!")

    assert vote.valid?
  end

  test "voto repetido atualiza sem duplicar" do
    vote1 = Vote.create!(performance: @performance, participant: @voter, score: 8)
    vote2 = Vote.find_or_initialize_by(performance: @performance, participant: @voter)
    vote2.update!(score: 10)

    assert_equal 1, @performance.votes.count
    assert_equal 10, @performance.votes.first.score
  end

  test "nota deve estar entre 0 e 10" do
    vote = Vote.new(performance: @performance, participant: @voter, score: 11)
    assert_not vote.valid?

    vote.score = -1
    assert_not vote.valid?

    vote.score = 5
    assert vote.valid?
  end

  test "mensagem deve ter no máximo 140 caracteres" do
    vote = Vote.new(performance: @performance, participant: @voter, score: 10, message: "a" * 141)
    assert_not vote.valid?

    vote.message = "a" * 140
    assert vote.valid?
  end
end
