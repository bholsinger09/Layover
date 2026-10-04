import SwiftUI

/// Profile and settings view
struct ProfileView: View {
    @Binding var currentUsername: String
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) var dismiss
    
    @State var editedUsername: String
    @State var showingUsernameEdit = false
    @State var selectedProfileImage: UIImage?
    
    init(currentUsername: Binding<String>, isAuthenticated: Binding<Bool>) {
        self._currentUsername = currentUsername
        self._isAuthenticated = isAuthenticated
        self._editedUsername = State(initialValue: currentUsername.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile Card (outside list, at top)
                VStack {
                    UserProfileCard(
                        username: currentUsername,
                        selectedImage: selectedProfileImage,
                        onImageSelected: { image in
                            selectedProfileImage = image
                        }
                    )
                    
                    // Edit Username Button
                    Button {
                        showingUsernameEdit = true
                    } label: {
                        Label("Edit Username", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
                .background(.ultraThinMaterial)
                .padding(.bottom, 8)
                
                // Settings List
                List {
                    accountSection
                    aboutSection
                    signOutSection
                }
            }
            .navigationTitle("Profile")
#if os(iOS)
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

// MARK: - Preview

#Preview {
    ProfileView(
        currentUsername: .constant("TestUser"),
        isAuthenticated: .constant(true)
    )
}

// MARK: - Account Deletion View

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
                deleteWarningHeader
                Divider()
                whatWillBeDeletedSection
                confirmationToggles
                dataRetentionPolicy
                deleteButton
            }
            .padding()
        }
        .navigationTitle("Delete Account")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .alert("Final Confirmation", isPresented: $showingFinalConfirmation) {
            TextField("Type DELETE to confirm", text: $confirmationText)
            Button("Cancel", role: .cancel) { confirmationText = "" }
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
    
    private var deleteWarningHeader: some View {
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
    }
    
    private var whatWillBeDeletedSection: some View {
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
    }
    
    private var confirmationToggles: some View {
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
    }
    
    private var dataRetentionPolicy: some View {
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
    }
    
    private var deleteButton: some View {
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
    
    private var allChecked: Bool {
        userUnderstands1 && userUnderstands2 && userUnderstands3
    }
    
    private func deleteAccount() {
        isDeletingAccount = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: "userLibrary")
                UserDefaults.standard.synchronize()
                
                isAuthenticated = false
                dismiss()
            }
        }
    }
}

// MARK: - Privacy Policy View

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
                
                privacySections
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private var privacySections: some View {
        Group {
            privacySection1
            privacySection2
            privacySection3
            privacySection4
            privacySection5
            privacySection6
            privacySection7
        }
    }
    
    private var privacySection1: some View {
        Group {
            SectionHeader("Information We Collect")
            Text("LayoverLounge collects minimal information to provide you with the best experience:")
            BulletPoint("Username and email address (for authentication)")
            BulletPoint("Watch history and favorites (stored locally on your device)")
            BulletPoint("Room participation and SharePlay activity")
            BulletPoint("Usage analytics (anonymized)")
        }
    }
    
    private var privacySection2: some View {
        Group {
            SectionHeader("How We Use Your Information")
            Text("We use your information to:")
            BulletPoint("Provide and maintain our services")
            BulletPoint("Personalize your experience with recommendations")
            BulletPoint("Enable SharePlay features and room collaboration")
            BulletPoint("Improve our app and develop new features")
            BulletPoint("Communicate with you about updates and changes")
        }
    }
    
    private var privacySection3: some View {
        Group {
            SectionHeader("Data Storage")
            Text("Your personal data, including favorites and watch history, is stored locally on your device. We do not share this information with third parties.")
        }
    }
    
    private var privacySection4: some View {
        Group {
            SectionHeader("SharePlay Data")
            Text("When using SharePlay features, certain information (room names, content selections) may be shared with other participants in your FaceTime call through Apple's GroupActivities framework.")
        }
    }
    
    private var privacySection5: some View {
        Group {
            SectionHeader("Data Retention")
            Text("You can delete your account and all associated data at any time through the Account settings. Upon deletion, your data is immediately removed from your device. Some anonymized analytics may be retained for up to 30 days for security purposes.")
        }
    }
    
    private var privacySection6: some View {
        Group {
            SectionHeader("Your Rights")
            Text("You have the right to:")
            BulletPoint("Access your personal data")
            BulletPoint("Correct inaccurate data")
            BulletPoint("Delete your account and all data")
            BulletPoint("Export your data")
        }
    }
    
    private var privacySection7: some View {
        Group {
            SectionHeader("Contact Us")
            Text("If you have questions about this Privacy Policy, please contact us at privacy@layoverlounge.app")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Terms of Service View

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
                
                termsSections
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private var termsSections: some View {
        Group {
            termsSection1
            termsSection2
            termsSection3
            termsSection4
            termsSection5
            termsSection6
            termsSection7
            termsSection8
            termsSection9
            termsSection10
        }
    }
    
    private var termsSection1: some View {
        Group {
            SectionHeader("Acceptance of Terms")
            Text("By accessing and using LayoverLounge, you accept and agree to be bound by the terms and provision of this agreement.")
        }
    }
    
    private var termsSection2: some View {
        Group {
            SectionHeader("Description of Service")
            Text("LayoverLounge is a social entertainment platform that enables users to watch Apple TV+ content and listen to Apple Music together via SharePlay during FaceTime calls.")
        }
    }
    
    private var termsSection3: some View {
        Group {
            SectionHeader("User Accounts")
            Text("You are responsible for:")
            BulletPoint("Maintaining the confidentiality of your account")
            BulletPoint("All activities that occur under your account")
            BulletPoint("Ensuring your account information is accurate")
        }
    }
    
    private var termsSection4: some View {
        Group {
            SectionHeader("Content and Conduct")
            Text("Users agree to:")
            BulletPoint("Use the service only for lawful purposes")
            BulletPoint("Respect other users' privacy and experience")
            BulletPoint("Not share inappropriate content in rooms")
            BulletPoint("Comply with Apple's terms for SharePlay, Apple TV+, and Apple Music")
        }
    }
    
    private var termsSection5: some View {
        Group {
            SectionHeader("Third-Party Services")
            Text("LayoverLounge integrates with Apple services including SharePlay, Apple TV+, and Apple Music. Your use of these services is subject to Apple's terms and conditions. You must have valid subscriptions to access respective content.")
        }
    }
    
    private var termsSection6: some View {
        Group {
            SectionHeader("Intellectual Property")
            Text("All content, features, and functionality of LayoverLounge are owned by the service provider and are protected by copyright, trademark, and other intellectual property laws.")
        }
    }
    
    private var termsSection7: some View {
        Group {
            SectionHeader("Termination")
            Text("We reserve the right to terminate or suspend your account at any time for violations of these terms. You may delete your account at any time through the app settings.")
        }
    }
    
    private var termsSection8: some View {
        Group {
            SectionHeader("Disclaimer")
            Text("LayoverLounge is provided 'as is' without warranties of any kind. We do not guarantee uninterrupted or error-free service.")
        }
    }
    
    private var termsSection9: some View {
        Group {
            SectionHeader("Changes to Terms")
            Text("We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the modified terms.")
        }
    }
    
    private var termsSection10: some View {
        Group {
            SectionHeader("Contact")
            Text("For questions about these Terms of Service, contact us at legal@layoverlounge.app")
                .foregroundStyle(.secondary)
        }
    }
}
