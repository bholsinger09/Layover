import SwiftUI

// MARK: - Settings Sections Extension

extension ProfileView {
    
    var profileSection: some View {
        Section {
            UserProfileCard(
                username: currentUsername,
                selectedImage: selectedProfileImage,
                onImageSelected: { image in
                    selectedProfileImage = image
                }
            )
            
            Button {
                showingUsernameEdit = true
            } label: {
                Label("Edit Username", systemImage: "pencil")
            }
        }
    }
    
    var accountSection: some View {
        Section("Account") {
            NavigationLink {
                AccountDeletionView(
                    currentUsername: currentUsername,
                    isAuthenticated: $isAuthenticated
                )
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }
    
    var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            
            NavigationLink {
                TermsOfServiceView()
            } label: {
                Label("Terms of Service", systemImage: "doc.text")
            }
        }
    }
    
    var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                isAuthenticated = false
                dismiss()
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
