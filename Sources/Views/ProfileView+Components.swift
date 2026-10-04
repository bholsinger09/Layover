import SwiftUI
import PhotosUI

// MARK: - User Profile Card with Picture Picker

struct UserProfileCard: View {
    let username: String
    @State var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    let onImageSelected: (UIImage?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture with Tap-to-Edit
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    // Profile Picture
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.orange, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                            }
                    }
                    
                    // Edit Badge
                    VStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("CHANGE")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(.blue.opacity(0.8)))
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        onImageSelected(uiImage)
                    }
                }
            }
            
            // Username and Status
            VStack(spacing: 4) {
                Text(username)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("LayoverLounge Member")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Hint text
            Text("Tap photo to change")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Info Row

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

// MARK: - Section Header

struct SectionHeader: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
    }
}

// MARK: - Bullet Point

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
        }
    }
}
