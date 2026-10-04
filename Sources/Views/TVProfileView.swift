import SwiftUI
import PhotosUI

public struct TVProfileView: View {
    let currentUser: User
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    public init(currentUser: User, authViewModel: AuthenticationViewModel) {
        self.currentUser = currentUser
        self.authViewModel = authViewModel
    }

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var selectedProfileImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.title3)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.black)

                // Main content
                ScrollView {
                    VStack(spacing: profileSpacing) {
                        // Profile card with photo picker
                        profileCardSection
                        
                        Divider()
                            .padding(.vertical, 20)

                        // Sign out button
                        Button(action: {
                            Task {
                                await authViewModel.signOut()
                            }
                        }) {
                            Text("Sign Out")
                                .font(.system(size: signOutButtonFontSize, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: signOutButtonMaxWidth)
                                .frame(height: signOutButtonHeight)
                                .background(Color.orange)
                                .cornerRadius(signOutButtonCornerRadius)
                        }

                        // Delete account button
                        Button(action: { showingDeleteConfirmation = true }) {
                            Text("Delete Account")
                                .font(.system(size: deleteButtonFontSize, weight: .bold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: deleteButtonMaxWidth)
                                .frame(height: deleteButtonHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: deleteButtonCornerRadius)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }

                        Spacer()
                    }
                    .padding(profilePadding)
                }
                .background(Color.black)
            }
            .background(Color.black)
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text(deleteAccountMessage)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Profile Card Section
    
    private var profileCardSection: some View {
        VStack(spacing: 12) {
            // Profile Picture with Tap-to-Edit
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                VStack(spacing: 8) {
                    // Profile Picture
                    if let selectedProfileImage {
                        Image(uiImage: selectedProfileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: profileIconSize, height: profileIconSize)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: profileIconSize, height: profileIconSize)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: profileIconSize * 0.5))
                                    .foregroundStyle(.white)
                            }
                    }
                    
                    // Edit Badge Below Picture
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Change")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.blue)
                }
            }
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        print("✅ Photo selected successfully")
                        selectedProfileImage = uiImage
                    }
                }
            }
            
            // User info
            VStack(spacing: 4) {
                Text(currentUser.username)
                    .font(profileNameFont)
                    .fontWeight(.bold)
                
                if let email = currentUser.email {
                    Text(email)
                        .font(profileEmailFont)
                        .foregroundStyle(.gray)
                }
            }
            
            // Hint text
            Text("Tap photo to change")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            print("🎨 TVProfileView appeared - username: \(currentUser.username), hasImage: \(selectedProfileImage != nil)")
        }
    }

    private var deleteAccountMessage: String {
        "This action cannot be undone. All your data will be permanently deleted."
    }

    #if os(tvOS)
    private var profileIconSize: CGFloat { 100 }
    private var profileNameFont: Font { .largeTitle }
    private var profileEmailFont: Font { .title3 }
    private var profileSpacing: CGFloat { 30 }
    private var buttonSpacing: CGFloat { 20 }
    private var signOutButtonFontSize: CGFloat { 38 }
    private var signOutButtonMaxWidth: CGFloat { 900 }
    private var signOutButtonHeight: CGFloat { 100 }
    private var signOutButtonCornerRadius: CGFloat { 16 }
    private var deleteButtonFontSize: CGFloat { 38 }
    private var deleteButtonMaxWidth: CGFloat { 900 }
    private var deleteButtonHeight: CGFloat { 100 }
    private var deleteButtonCornerRadius: CGFloat { 16 }
    private var signOutButtonBottomPadding: CGFloat { 60 }
    private var profilePadding: CGFloat { 40 }
    #else
    private var profileIconSize: CGFloat { 60 }
    private var profileNameFont: Font { .title }
    private var profileEmailFont: Font { .body }
    private var profileSpacing: CGFloat { 20 }
    private var buttonSpacing: CGFloat { 12 }
    private var signOutButtonFontSize: CGFloat { 16 }
    private var signOutButtonMaxWidth: CGFloat { 300 }
    private var signOutButtonHeight: CGFloat { 44 }
    private var signOutButtonCornerRadius: CGFloat { 8 }
    private var deleteButtonFontSize: CGFloat { 16 }
    private var deleteButtonMaxWidth: CGFloat { 300 }
    private var deleteButtonHeight: CGFloat { 44 }
    private var deleteButtonCornerRadius: CGFloat { 8 }
    private var signOutButtonBottomPadding: CGFloat { 30 }
    private var profilePadding: CGFloat { 20 }
    #endif
}
