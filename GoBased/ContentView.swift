import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // AR Experience Tab
            ARContainerView()
                .environmentObject(locationManager)
                .environmentObject(walletManager)
                .tabItem {
                    Label("AR", systemImage: "camera.fill")
                }
                .tag(0)
            
            // Map Tab
            MapView()
                .environmentObject(locationManager)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)
            
            // Wallet Tab
            WalletView()
                .environmentObject(walletManager)
                .tabItem {
                    Label("Wallet", systemImage: "wallet.pass.fill")
                }
                .tag(2)
            
            // Profile Tab
            ProfileView()
                .environmentObject(walletManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Request location permission
            locationManager.requestLocationPermission()
        }
        .accentColor(.blue)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    if walletManager.isConnected {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connected Wallet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let address = walletManager.shortAddress {
                                Text(address)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    } else {
                        Button("Connect Wallet") {
                            walletManager.connectWalletInApp()
                        }
                    }
                }
                
                // Stats Section
                Section {
                    StatsView(
                        nftsCollected: 0,  // Replace with actual data
                        questsCompleted: 0, // Replace with actual data
                        totalDistance: 0.0  // Replace with actual data
                    )
                }
                
                // Quest Progress Section
                Section(header: Text("Quest Progress")) {
                    QuestProgressView(completed: 0, total: 10) // Replace with actual data
                }
                
                // Achievements Section
                Section(header: Text("Achievements")) {
                    AchievementView(
                        title: "First Steps",
                        description: "Complete your first quest",
                        isUnlocked: false
                    )
                    AchievementView(
                        title: "Collector",
                        description: "Collect 5 NFTs",
                        isUnlocked: false
                    )
                    AchievementView(
                        title: "Explorer",
                        description: "Walk 10km total",
                        isUnlocked: false
                    )
                }
                
                // Settings Section
                Section {
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    if walletManager.isConnected {
                        Button(action: { walletManager.disconnect() }) {
                            Label("Disconnect Wallet", systemImage: "link.badge.minus")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("enableSounds") private var enableSounds = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("App Settings")) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    Toggle("Enable Sounds", isOn: $enableSounds)
                }
                
                Section(header: Text("About")) {
                    Link("Terms of Service", destination: URL(string: AppConstants.websiteURL + "/terms")!)
                    Link("Privacy Policy", destination: URL(string: AppConstants.websiteURL + "/privacy")!)
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Support")) {
                    Link("Contact Support", destination: URL(string: "mailto:" + AppConstants.supportEmail)!)
                    Link("Follow us on Twitter", destination: URL(string: "https://twitter.com/" + AppConstants.twitterHandle.dropFirst())!)
                }
                
                Section(header: Text("Data")) {
                    Button(role: .destructive, action: clearAppData) {
                        Text("Clear App Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func clearAppData() {
        // Clear user defaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        // Reset settings
        enableNotifications = true
        enableSounds = true
    }
}

// MARK: - Helper Views
struct AchievementView: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundColor(isUnlocked ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
}

struct QuestProgressView: View {
    let completed: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quest Progress")
                    .font(.headline)
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(completed), total: Double(total))
                .tint(.blue)
        }
    }
}

struct StatsView: View {
    let nftsCollected: Int
    let questsCompleted: Int
    let totalDistance: Double
    
    var body: some View {
        HStack {
            StatCard(title: "NFTs", value: "\(nftsCollected)")
            StatCard(title: "Quests", value: "\(questsCompleted)")
            StatCard(title: "Distance", value: String(format: "%.1f km", totalDistance))
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Constants
enum AppConstants {
    static let appName = "GoBased"
    static let supportEmail = "support@gobased.com"
    static let websiteURL = "https://gobased.com"
    static let twitterHandle = "@GoBased"
    
    static let defaultMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
}

// MARK: - Notifications
extension Notification.Name {
    static let questCompleted = Notification.Name("questCompleted")
    static let nftCollected = Notification.Name("nftCollected")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Preview Provider
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(WalletManager())
                .environmentObject(LocationManager())
            
            // Dark mode preview
            ContentView()
                .environmentObject(WalletManager())
                .environmentObject(LocationManager())
                .preferredColorScheme(.dark)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(WalletManager())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(
            nftsCollected: 5,
            questsCompleted: 10,
            totalDistance: 15.5
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        StatCard(title: "NFTs", value: "5")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

// MARK: - Helper Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Custom Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Environment Keys
struct RefreshKey: EnvironmentKey {
    static let defaultValue = {}
}

extension EnvironmentValues {
    var refresh: () -> Void {
        get { self[RefreshKey.self] }
        set { self[RefreshKey.self] = newValue }
    }
}

// MARK: - Custom Navigation Bar Appearance
extension View {
    func configureNavigationBar() -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
}
