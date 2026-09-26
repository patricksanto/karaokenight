require "test_helper"

class QueueOrderTest < ActiveSupport::TestCase
  setup do
    @room = Room.create!(
      code: "ABC234",
      name: "Test Room",
      status: :open,
      host_token_digest: BCrypt::Password.create("secret")
    )

    @ana = Participant.create!(room: @room, nickname: "Ana", emoji: "🎤", session_token_digest: "token1")
    @bruno = Participant.create!(room: @room, nickname: "Bruno", emoji: "🎸", session_token_digest: "token2")
    @carla = Participant.create!(room: @room, nickname: "Carla", emoji: "🎹", session_token_digest: "token3")
  end

  test "Ana A1/A2, Bruno B1, Carla C1 resulta em A1/B1/C1/A2" do
    a1 = SongRequest.create!(room: @room, participant: @ana, title: "Song A1", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: a1, participant: @ana)

    b1 = SongRequest.create!(room: @room, participant: @bruno, title: "Song B1", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: b1, participant: @bruno)

    c1 = SongRequest.create!(room: @room, participant: @carla, title: "Song C1", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: c1, participant: @carla)

    a2 = SongRequest.create!(room: @room, participant: @ana, title: "Song A2", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: a2, participant: @ana)

    queue = QueueOrder.new(@room).call

    assert_equal [a1, b1, c1, a2], queue
  end

  test "último cantor não repete quando há alternativa" do
    a1 = SongRequest.create!(room: @room, participant: @ana, title: "Song A1", artist: "Artist", status: :completed)
    SongRequestSinger.create!(song_request: a1, participant: @ana)

    b1 = SongRequest.create!(room: @room, participant: @bruno, title: "Song B1", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: b1, participant: @bruno)

    performance = Performance.create!(room: @room, song_request: a1, status: :revealed, started_at: 1.minute.ago, revealed_at: Time.current)
    PerformanceSinger.create!(performance: performance, participant: @ana)

    queue = QueueOrder.new(@room).call

    assert_equal [b1], queue
  end

  test "último cantor repete quando está sozinho" do
    a1 = SongRequest.create!(room: @room, participant: @ana, title: "Song A1", artist: "Artist", status: :completed)
    SongRequestSinger.create!(song_request: a1, participant: @ana)

    a2 = SongRequest.create!(room: @room, participant: @ana, title: "Song A2", artist: "Artist", status: :queued)
    SongRequestSinger.create!(song_request: a2, participant: @ana)

    performance = Performance.create!(room: @room, song_request: a1, status: :revealed, started_at: 1.minute.ago, revealed_at: Time.current)
    PerformanceSinger.create!(performance: performance, participant: @ana)

    queue = QueueOrder.new(@room).call

    assert_equal [a2], queue
    assert_equal @ana, queue.first.participant
  end
end
