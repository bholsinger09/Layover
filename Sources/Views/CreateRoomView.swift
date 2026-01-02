import SwiftUI

/// View for creating a new room
public struct CreateRoomView: View {
    @Environment(\.dismiss) private var dismiss

    public let currentUser: User
    public let onCreate: (String, RoomActivityType) async -> Void
    
    public init(currentUser: User, onCreate: @escaping (String, RoomActivityType) async -> Void) {
        self.currentUser = currentUser
        self.onCreate = onCreate
    }

    @State private var roomName = ""
    @State private var selectedActivity: RoomActivityType = .appleTVPlus
    @State private var isCreating = false

    public var body: some View {
        NavigationStack {
            Form {
                Section("Room Details") {
                    TextField("Room Name", text: $roomName)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                }

                Section("Activity Type") {
                    Picker("Activity", selection: $selectedActivity) {
                        Label("Apple TV+", systemImage: "tv.fill")
                            .tag(RoomActivityType.appleTVPlus)

                        Label("Apple Music", systemImage: "music.note")
                            .tag(RoomActivityType.appleMusic)

                        Label("Texas Hold'em", systemImage: "suit.spade.fill")
                            .tag(RoomActivityType.texasHoldem)

                        Label("Chess", systemImage: "square.grid.3x3.fill")
                            .tag(RoomActivityType.chess)
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Create Room")
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
                    Button("Create") {
                        Task {
                            isCreating = true
                            await onCreate(roomName, selectedActivity)
                            isCreating = false
                        }
                    }
                    .disabled(roomName.isEmpty || isCreating)
                }
            }
        }
    }
}

#Preview {
    CreateRoomView(
        currentUser: User(username: "Test User"),
        onCreate: { _, _ in }
    )
}
