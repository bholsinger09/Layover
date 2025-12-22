import SwiftUI

/// Row view for displaying a room in a list
struct RoomRowView: View {
    let room: Room
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.name)
                    .font(.headline)
                
                Spacer()
                
                activityIcon
            }
            
            HStack {
                Label("\(room.participantIDs.count)/\(room.maxParticipants)", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if room.isPrivate {
                    Label("Private", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !room.participants.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(room.participants) { participant in
                            Text(participant.username)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var activityIcon: some View {
        switch room.activityType {
        case .appleTVPlus:
            Image(systemName: "tv.fill")
                .foregroundStyle(.blue)
        case .appleMusic:
            Image(systemName: "music.note")
                .foregroundStyle(.pink)
        case .texasHoldem:
            Image(systemName: "suit.spade.fill")
                .foregroundStyle(.red)
        case .chess:
            Image(systemName: "square.grid.3x3.fill")
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    List {
        RoomRowView(room: Room(
            name: "Movie Night",
            hostID: UUID(),
            participantIDs: [UUID(), UUID()],
            activityType: .appleTVPlus
        ))
        
        RoomRowView(room: Room(
            name: "Poker Game",
            hostID: UUID(),
            participantIDs: [UUID()],
            activityType: .texasHoldem,
            isPrivate: true
        ))
    }
}
