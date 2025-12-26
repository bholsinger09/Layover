import SwiftUI

/// Profile and settings view
struct ProfileView: View {
    @Binding var currentUsername: String
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedUsername: String
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteInProgress = false
    @State private var deleteConfirmationText = ""
    @State private var showingUsernameEdit = false
    
    init(currentUsername: Binding<String>, isAuthenticated: Binding<Bool>) {
        self._currentUsername = currentUsername
        self._isAuthenticated = isAuthenticated
        self._editedUsername = State(initialValue: currentUsername.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUsername)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("LayoverLounge Member")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                    
                    Button {
                        showingUsernameEdit = true
                    } label: {
                        Label("Edit Username", systemImage: "pencil")
                    }
                }
                
                // Account Settings Section
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
                
                // App Info Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                // Sign Out Section
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
            .navigationTitle("Profile")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Edit Username", isPresented: $showingUsernameEdit) {
                TextField("Username", text: $editedUsername)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if !editedUsername.isEmpty {
                        currentUsername = editedUsername
                    }
                }
            } message: {
                Text("Enter your new username")
            }
        }
    }
}

/// Dedicated account deletion view following Apple's guidelines
struct AccountDeletionView: View {
    let currentUsername: String
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var confirmationText = ""
    @State private var showingFinalConfirmation = false
    @State private var isDeletingAccount = false
    @State private var userUnderstands1 = false
    @State private var userUnderstands2 = false
    @State private var userUnderstands3 = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Warning header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    
                    Text("Delete Account")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This action cannot be undone")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                Divider()
                
                // What will be deleted
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will be deleted")
                        .font(.headline)
                    
                    InfoRow(icon: "person.fill.xmark", text: "Your account and profile information")
                    InfoRow(icon: "star.fill", text: "All favorites and watchlist items")
                    InfoRow(icon: "clock.fill", text: "Complete watch history and statistics")
                    InfoRow(icon: "rectangle.stack.fill", text: "All rooms you've created")
                    InfoRow(icon: "folder.fill", text: "All personal data associated with your account")
                }
                .padding()
                .background(.quaternary)
                .cornerRadius(12)
                
                // Important information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Please note")
                        .font(.headline)
                    
                    Toggle(isOn: $userUnderstands1) {
                        Text("I understand my data will be permanently deleted")
                            .font(.subheadline)
                    }
                    
                    Toggle(isOn: $userUnderstands2) {
                        Text("I understand this action cannot be reversed")
                            .font(.subheadline)
                    }
                    
                    Toggle(isOn: $userUnderstands3) {
                        Text("I understand I'll need to create a new account to use LayoverLounge again")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(.quaternary)
                .cornerRadius(12)
                
                // Data retention policy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Deletion Timeline")
                        .font(.headline)
                    
                    Text("Your account and personal data will be deleted immediately upon confirmation. Some aggregated, anonymized analytics data may be retained for up to 30 days for security and legal compliance purposes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.quaternary)
                .cornerRadius(12)
                
                // Delete button
                VStack(spacing: 16) {
                    Button(role: .destructive) {
                        showingFinalConfirmation = true
                    } label: {
                        if isDeletingAccount {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Delete My Account")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!allChecked || isDeletingAccount)
                    .padding(.top, 8)
                    
                    Text("Need help? Contact support before deleting your account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Delete Account")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            TextField("Type DELETE to confirm", text: $confirmationText)
            Button("Cancel", role: .cancel) {
                confirmationText = ""
            }
            Button("Delete Account", role: .destructive) {
                if confirmationText.uppercased() == "DELETE" {
                    deleteAccount()
                }
            }
            .disabled(confirmationText.uppercased() != "DELETE")
        } message: {
            Text("Type DELETE to permanently delete your account '\(currentUsername)' and all associated data. This action cannot be undone.")
        }
    }
    
    private var allChecked: Bool {
        userUnderstands1 && userUnderstands2 && userUnderstands3
    }
    
    private func deleteAccount() {
        isDeletingAccount = true
        
        // Simulate deletion process
        Task {
            // Wait 2 seconds to show deletion in progress
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                // Clear all user data
                UserDefaults.standard.removeObject(forKey: "userLibrary")
                UserDefaults.standard.synchronize()
                
                // Sign out
                isAuthenticated = false
                
                // Dismiss all views
                dismiss()
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    ProfileView(
        currentUsername: .constant("TestUser"),
        isAuthenticated: .constant(true)
    )
}
