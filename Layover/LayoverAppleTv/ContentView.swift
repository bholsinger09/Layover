//
//  ContentView.swift
//  LayoverAppleTv
//
//  Created by Ben H on 1/2/26.
//

//
//  ContentView.swift
//  LayoverTV
//
//  Created by Ben H on 1/2/26.
//

import SwiftUI
import LayoverKit

struct ContentView: View {
    @State private var authViewModel = AuthenticationViewModel(authService: AuthenticationService())
    @State private var roomListViewModel = RoomListViewModel(roomService: RoomService(), sharePlayService: SharePlayService())
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                NavigationStack {
                    RoomListView(
                        currentUser: user,
                        roomListViewModel: roomListViewModel,
                        authViewModel: authViewModel
                    )
                }
            } else {
                SignInView(viewModel: authViewModel)
            }
        }
        .task {
            await authViewModel.checkCredentialState()
        }
    }
}

// Simplified RoomListView for tvOS
struct RoomListView: View {
    let currentUser: User
    @State var roomListViewModel: RoomListViewModel
    @ObservedObject var authViewModel: AuthenticationViewModel
    @State private var showingCreateRoom = false
    
    var body: some View {
        List {
            ForEach(roomListViewModel.rooms) { room in
                NavigationLink {
                    RoomDetailView(room: room, currentUser: currentUser)
                } label: {
                    RoomRowView(room: room)
                }
            }
        }
        .navigationTitle("Layover")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateRoom = true
                } label: {
                    Label("Create Room", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await authViewModel.signOut()
                    }
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .sheet(isPresented: $showingCreateRoom) {
            CreateRoomView(currentUser: currentUser) { name, activityType in
                Task {
                    await roomListViewModel.createRoom(name: name, host: currentUser, activityType: activityType)
                    showingCreateRoom = false
                }
            }
        }
        .task {
            await roomListViewModel.loadRooms()
        }
    }
}

// Room detail view for tvOS
struct RoomDetailView: View {
    let room: Room
    let currentUser: User
    
    var body: some View {
        VStack(spacing: 40) {
            Text(room.name)
                .font(.largeTitle)
            
            Text("Activity: \(room.activityType.rawValue)")
                .font(.title2)
            
            Text("Host: \(room.hostID.uuidString)")
                .font(.caption)
            
            switch room.activityType {
            case .appleMusic:
                AppleMusicView(
                    room: room,
                    currentUser: currentUser,
                    sharePlayService: SharePlayService()
                )
            case .appleTVPlus:
                AppleTVView(
                    room: room,
                    currentUser: currentUser,
                    sharePlayService: SharePlayService()
                )
            case .texasHoldem:
                TexasHoldemView(
                    room: room,
                    currentUser: currentUser,
                    sharePlayService: SharePlayService()
                )
            case .chess:
                Text("Chess coming soon")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
