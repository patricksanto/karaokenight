require "test_helper"

class PerformanceTest < ActiveSupport::TestCase
  setup do
    @room = Room.create!(
      code: "PERF23",
      name: "Test Room",
      status: :open,
      host_token_digest: BCrypt::Password.create("secret")
    )

    @participant = Participant.create!(room: @room, nickname: "Singer", emoji: "🎤", session_token_digest: "token1")
    @song_request = SongRequest.create!(room: @room, participant: @participant, title: "Test Song", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: @song_request, participant: @participant)
  end

  test "só pode haver uma apresentação ativa por sala" do
    performance1 = Performance.create!(
      room: @room,
      song_request: @song_request,
      status: :performing,
      started_at: Time.current
    )

    song_request2 = SongRequest.create!(room: @room, participant: @participant, title: "Song 2", artist: "Artist", status: :queued)
    performance2 = Performance.new(
      room: @room,
      song_request: song_request2,
      status: :performing,
      started_at: Time.current
    )

    assert_not performance2.valid?
  end

  test "finalização é idempotente" do
    performance = Performance.create!(
      room: @room,
      song_request: @song_request,
      status: :closing,
      started_at: Time.current,
      voting_closes_at: 10.seconds.from_now
    )

    Vote.create!(performance: performance, participant: @participant, score: 8)

    performance.update!(voting_closes_at: 10.seconds.ago)

    FinalizePerformanceJob.perform_now(performance.id)
    performance.reload

    assert_equal "revealed", performance.status
    assert_equal 1, performance.votes_count
    assert_equal 8.0, performance.average_score

    FinalizePerformanceJob.perform_now(performance.id)
    performance.reload

    assert_equal "revealed", performance.status
    assert_equal 1, performance.votes_count
  end

  test "apresentação abortada não conta" do
    performance = Performance.create!(
      room: @room,
      song_request: @song_request,
      status: :aborted,
      started_at: Time.current
    )

    assert_equal "aborted", performance.status
    assert_equal "queued", @song_request.reload.status
  end
end
