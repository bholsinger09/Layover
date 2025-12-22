import SwiftUI

/// View for editing room details
struct EditRoomView: View {
    @Environment(\.dismiss) private var dismiss
    let room: Room
    let onUpdate: (String, Bool, Int) async -> Void
    
    @State private var roomName: String
    @State private var isPrivate: Bool
    @State private var maxParticipants: Int
    @State private var isUpdating = false
    
    init(room: Room, onUpdate: @escaping (String, Bool, Int) async -> Void) {
        self.room = room
        self.onUpdate = onUpdate
        _roomName = State(initialValue: room.name)
        _isPrivate = State(initialValue: room.isPrivate)
        _maxParticipants = State(initialValue: room.maxParticipants)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $roomName)
                    
                    Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 2...50)
                    
                    Toggle("Private Room", isOn: $isPrivate)
                }
                
                Section {
                    Text("Activity Type: \(activityTypeName)")
                        .foregroundStyle(.secondary)
                    
                    Text("Created: \(room.createdAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Room")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isUpdating = true
                            await onUpdate(roomName, isPrivate, maxParticipants)
                            dismiss()
                        }
                    }
                    .disabled(roomName.isEmpty || isUpdating)
                }
            }
        }
    }
    
    private var activityTypeName: String {
        switch room.activityType {
        case .appleTVPlus:
            return "Apple TV+"
        case .appleMusic:
            return "Apple Music"
        case .texasHoldem:
            return "Texas Hold'em"
        case .chess:
            return "Chess"
        }
    }
}
