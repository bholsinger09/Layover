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
            VStack(spacing: 0) {
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

                            Label("Chess", systemImage: "square.grid.3x3.fill")
                                .tag(RoomActivityType.chess)
                        }
                        .pickerStyle(.inline)
                    }
                }
                
                // Custom large action buttons
                HStack(spacing: 30) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green, lineWidth: 6)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        Task {
                            isCreating = true
                            await onCreate(roomName, selectedActivity)
                            isCreating = false
                        }
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.red)
                                .scaleEffect(2)
                        } else {
                            Text("Create")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(roomName.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green, lineWidth: 6)
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(roomName.isEmpty || isCreating)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                .background(Color(white: 0.1))
            }
            .navigationTitle("Create Room")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }
}

#Preview {
    CreateRoomView(
        currentUser: User(username: "Test User"),
        onCreate: { _, _ in }
    )
}
