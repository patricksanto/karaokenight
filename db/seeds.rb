if Rails.env.development? || Rails.env.test?
  Room.destroy_all

  token = SecureRandom.hex(32)
  room = Room.create!(
    name: "Festa de Karaokê",
    status: :open,
    host_token: token
  )

  puts "Sala criada: #{room.code}"
  puts "Host token: #{token}"

  ana = Participant.create!(room: room, nickname: "Ana", emoji: "🎤", session_token: "ana_token")
  bruno = Participant.create!(room: room, nickname: "Bruno", emoji: "🎸", session_token: "bruno_token")
  carla = Participant.create!(room: room, nickname: "Carla", emoji: "🎵", session_token: "carla_token")

  puts "Participantes: #{ana.nickname}, #{bruno.nickname}, #{carla.nickname}"

  a1 = SongRequest.create!(room: room, participant: ana, title: "Bohemian Rhapsody", artist: "Queen")
  a2 = SongRequest.create!(room: room, participant: ana, title: "Don't Stop Me Now", artist: "Queen")
  b1 = SongRequest.create!(room: room, participant: bruno, title: "Wonderwall", artist: "Oasis")
  c1 = SongRequest.create!(room: room, participant: carla, title: "I Will Survive", artist: "Gloria Gaynor")

  [a1, a2, b1, c1].each do |sr|
    SongRequestSinger.create!(song_request: sr, participant: sr.participant)
  end

  puts "Pedidos criados: A1(#{a1.id}), A2(#{a2.id}), B1(#{b1.id}), C1(#{c1.id})"
end
