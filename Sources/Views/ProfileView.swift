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
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 600)
        #endif
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

/// Privacy Policy view
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last updated: December 26, 2025")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Group {
                    SectionHeader("Information We Collect")
                    Text("LayoverLounge collects minimal information to provide you with the best experience:")
                    BulletPoint("Username and email address (for authentication)")
                    BulletPoint("Watch history and favorites (stored locally on your device)")
                    BulletPoint("Room participation and SharePlay activity")
                    BulletPoint("Usage analytics (anonymized)")
                }
                
                Group {
                    SectionHeader("How We Use Your Information")
                    Text("We use your information to:")
                    BulletPoint("Provide and maintain our services")
                    BulletPoint("Personalize your experience with recommendations")
                    BulletPoint("Enable SharePlay features and room collaboration")
                    BulletPoint("Improve our app and develop new features")
                    BulletPoint("Communicate with you about updates and changes")
                }
                
                Group {
                    SectionHeader("Data Storage")
                    Text("Your personal data, including favorites and watch history, is stored locally on your device. We do not share this information with third parties.")
                }
                
                Group {
                    SectionHeader("SharePlay Data")
                    Text("When using SharePlay features, certain information (room names, content selections) may be shared with other participants in your FaceTime call through Apple's GroupActivities framework.")
                }
                
                Group {
                    SectionHeader("Data Retention")
                    Text("You can delete your account and all associated data at any time through the Account settings. Upon deletion, your data is immediately removed from your device. Some anonymized analytics may be retained for up to 30 days for security purposes.")
                }
                
                Group {
                    SectionHeader("Your Rights")
                    Text("You have the right to:")
                    BulletPoint("Access your personal data")
                    BulletPoint("Correct inaccurate data")
                    BulletPoint("Delete your account and all data")
                    BulletPoint("Export your data")
                }
                
                Group {
                    SectionHeader("Contact Us")
                    Text("If you have questions about this Privacy Policy, please contact us at privacy@layoverlounge.app")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Terms of Service view
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last updated: December 26, 2025")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                Group {
                    SectionHeader("Acceptance of Terms")
                    Text("By accessing and using LayoverLounge, you accept and agree to be bound by the terms and provision of this agreement.")
                }
                
                Group {
                    SectionHeader("Description of Service")
                    Text("LayoverLounge is a social entertainment platform that enables users to watch Apple TV+ content and listen to Apple Music together via SharePlay during FaceTime calls.")
                }
                
                Group {
                    SectionHeader("User Accounts")
                    Text("You are responsible for:")
                    BulletPoint("Maintaining the confidentiality of your account")
                    BulletPoint("All activities that occur under your account")
                    BulletPoint("Ensuring your account information is accurate")
                }
                
                Group {
                    SectionHeader("Content and Conduct")
                    Text("Users agree to:")
                    BulletPoint("Use the service only for lawful purposes")
                    BulletPoint("Respect other users' privacy and experience")
                    BulletPoint("Not share inappropriate content in rooms")
                    BulletPoint("Comply with Apple's terms for SharePlay, Apple TV+, and Apple Music")
                }
                
                Group {
                    SectionHeader("Third-Party Services")
                    Text("LayoverLounge integrates with Apple services including SharePlay, Apple TV+, and Apple Music. Your use of these services is subject to Apple's terms and conditions. You must have valid subscriptions to access respective content.")
                }
                
                Group {
                    SectionHeader("Intellectual Property")
                    Text("All content, features, and functionality of LayoverLounge are owned by the service provider and are protected by copyright, trademark, and other intellectual property laws.")
                }
                
                Group {
                    SectionHeader("Termination")
                    Text("We reserve the right to terminate or suspend your account at any time for violations of these terms. You may delete your account at any time through the app settings.")
                }
                
                Group {
                    SectionHeader("Disclaimer")
                    Text("LayoverLounge is provided 'as is' without warranties of any kind. We do not guarantee uninterrupted or error-free service.")
                }
                
                Group {
                    SectionHeader("Changes to Terms")
                    Text("We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the modified terms.")
                }
                
                Group {
                    SectionHeader("Contact")
                    Text("For questions about these Terms of Service, contact us at legal@layoverlounge.app")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// Helper views for formatting
struct SectionHeader: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .padding(.leading, 8)
    }
}
