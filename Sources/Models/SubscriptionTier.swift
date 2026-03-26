import Foundation

/// R16: Subscription tiers for Pulse
public enum PulseSubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case household = "household"
    
    public var displayName: String {
        switch self { case .free: return "Free"; case .pro: return "Pulse Pro"; case .household: return "Pulse Household" }
    }
    public var monthlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 2.99; case .household: return 4.99 }
    }
    public var yearlyPrice: Decimal? {
        switch self { case .free: return nil; case .pro: return 19.99; case .household: return 39.99 }
    }
    public var maxMacs: Int {
        switch self { case .free: return 1; case .pro: return 1; case .household: return 5 }
    }
    public var supportsAdvancedAlerts: Bool { self != .free }
    public var supportsHistoricalReports: Bool { self == .pro || self == .household }
    public var supportsWidgets: Bool { self != .free }
    public var supportsShortcuts: Bool { self != .free }
    public var supportsAppleWatch: Bool { self != .free }
    public var trialDays: Int { self == .free ? 0 : 14 }
}

public struct PulseSubscription: Codable {
    public let tier: PulseSubscriptionTier
    public let status: String
    public let expiresAt: Date?
    public init(tier: PulseSubscriptionTier, status: String = "active", expiresAt: Date? = nil) {
        self.tier = tier; self.status = status; self.expiresAt = expiresAt
    }
}
