import Foundation
import StoreKit

/// R16: Subscription management for Pulse
@available(macOS 13.0, *)
public final class PulseSubscriptionManager: ObservableObject {
    public static let shared = PulseSubscriptionManager()
    @Published public private(set) var subscription: PulseSubscription?
    @Published public private(set) var products: [Product] = []
    
    private init() {}
    
    public func loadProducts() async {
        do {
            products = try await Product.products(for: [
                "com.pulse.macos.pro.monthly",
                "com.pulse.macos.pro.yearly",
                "com.pulse.macos.household.monthly",
                "com.pulse.macos.household.yearly"
            ])
        } catch { print("Failed to load products") }
    }
    
    public func canAccess(_ feature: PulseFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .advancedAlerts: return sub.tier != .free
        case .historicalReports: return sub.tier == .pro || sub.tier == .household
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .appleWatch: return sub.tier != .free
        case .household: return sub.tier == .household
        }
    }
    
    public func updateStatus() async {
        var found: PulseSubscription = PulseSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("household") {
                    found = PulseSubscription(tier: .household, status: t.revocationDate == nil ? "active" : "expired")
                } else if t.productID.contains("pro") {
                    found = PulseSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired")
                }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    
    public func restore() async throws {
        try await AppStore.sync()
        await updateStatus()
    }
    
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T {
        switch r { case .unverified: throw NSError(domain: "Pulse", code: -1); case .verified(let s): return s }
    }
}

public enum PulseFeature { case advancedAlerts, historicalReports, widgets, shortcuts, appleWatch, household }
