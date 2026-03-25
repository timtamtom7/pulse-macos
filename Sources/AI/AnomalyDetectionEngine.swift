import Foundation

/// AI-powered anomaly detection for system resources
final class AnomalyDetectionEngine {
    static let shared = AnomalyDetectionEngine()
    
    private init() {}
    
    // MARK: - Anomaly Types
    
    enum AnomalyType {
        case cpuSpike
        case memoryLeak
        case diskSpaceLow
        case networkAnomaly
        case temperatureHigh
    }
    
    struct Anomaly: Identifiable {
        let id = UUID()
        let type: AnomalyType
        let severity: Severity
        let message: String
        let timestamp: Date
        let value: Double
        let threshold: Double
        
        enum Severity {
            case low
            case medium
            case high
            case critical
        }
    }
    
    // MARK: - Anomaly Detection
    
    /// Detect anomalies in system stats history
    func detectAnomalies(history: [SystemStatsSample]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        guard history.count >= 5 else { return anomalies }
        
        // CPU anomaly detection
        let cpuAnomalies = detectCPUAnomalies(history: history)
        anomalies.append(contentsOf: cpuAnomalies)
        
        // Memory anomaly detection
        let memoryAnomalies = detectMemoryAnomalies(history: history)
        anomalies.append(contentsOf: memoryAnomalies)
        
        // Disk anomaly detection
        let diskAnomalies = detectDiskAnomalies(history: history)
        anomalies.append(contentsOf: diskAnomalies)
        
        return anomalies
    }
    
    // MARK: - CPU Anomaly Detection
    
    private func detectCPUAnomalies(history: [SystemStatsSample]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        let cpuUsages = history.map { $0.cpuUsage }
        let mean = cpuUsages.reduce(0, +) / Double(cpuUsages.count)
        let stdDev = standardDeviation(cpuUsages, mean: mean)
        
        for sample in history.suffix(5) {
            let deviation = abs(sample.cpuUsage - mean)
            if deviation > 2 * stdDev && sample.cpuUsage > 80 {
                anomalies.append(Anomaly(
                    type: .cpuSpike,
                    severity: deviation > 3 * stdDev ? .high : .medium,
                    message: "CPU usage spike detected: \(Int(sample.cpuUsage * 100))%",
                    timestamp: sample.timestamp,
                    value: sample.cpuUsage,
                    threshold: mean + 2 * stdDev
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Memory Anomaly Detection
    
    private func detectMemoryAnomalies(history: [SystemStatsSample]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        // Detect memory leak pattern: steady increase over time
        guard history.count >= 10 else { return anomalies }
        
        let recentHistory = Array(history.suffix(10))
        let memoryUsages = recentHistory.map { $0.memoryUsage }
        
        // Check for monotonic increase (memory leak pattern)
        var increasing = true
        for i in 1..<memoryUsages.count {
            if memoryUsages[i] < memoryUsages[i-1] - 0.01 { // 1% threshold
                increasing = false
                break
            }
        }
        
        if increasing && memoryUsages.last! > memoryUsages.first! + 0.1 { // 10% increase
            anomalies.append(Anomaly(
                type: .memoryLeak,
                severity: .high,
                message: "Possible memory leak detected: memory usage increased \(Int((memoryUsages.last! - memoryUsages.first!) * 100))% over recent period",
                timestamp: recentHistory.last!.timestamp,
                value: memoryUsages.last!,
                threshold: memoryUsages.first! + 0.1
            ))
        }
        
        return anomalies
    }
    
    // MARK: - Disk Anomaly Detection
    
    private func detectDiskAnomalies(history: [SystemStatsSample]) -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        for sample in history.suffix(5) {
            if sample.diskUsage > 0.9 { // 90% disk usage
                anomalies.append(Anomaly(
                    type: .diskSpaceLow,
                    severity: sample.diskUsage > 0.95 ? .critical : .high,
                    message: "Disk space critically low: \(Int((1 - sample.diskUsage) * 100))% remaining",
                    timestamp: sample.timestamp,
                    value: sample.diskUsage,
                    threshold: 0.9
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Prediction
    
    /// Predict when a resource will reach a threshold
    func predictExhaustionTime(
        history: [SystemStatsSample],
        resourceType: ResourceType,
        threshold: Double
    ) -> Date? {
        guard history.count >= 5 else { return nil }
        
        let values: [Double]
        switch resourceType {
        case .cpu:
            values = history.map { $0.cpuUsage }
        case .memory:
            values = history.map { $0.memoryUsage }
        case .disk:
            values = history.map { $0.diskUsage }
        }
        
        // Simple linear regression
        let n = Double(values.count)
        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0
        
        for (i, value) in values.enumerated() {
            let x = Double(i)
            sumX += x
            sumY += value
            sumXY += x * value
            sumX2 += x * x
        }
        
        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > 0.001 else { return nil }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        guard slope > 0 else { return nil } // Not increasing
        
        // Solve for when value reaches threshold
        // y = slope * x + intercept
        // threshold = slope * x + intercept
        // x = (threshold - intercept) / slope
        let xAtThreshold = (threshold - intercept) / slope
        
        if xAtThreshold < Double(values.count) {
            // It's already past threshold in our data
            return history.last?.timestamp
        }
        
        let secondsUntilExhaustion = (xAtThreshold - Double(values.count - 1)) * 5 * 60 // Assuming 5 min intervals
        
        return Date(timeIntervalSinceNow: secondsUntilExhaustion)
    }
    
    // MARK: - Helpers
    
    private func standardDeviation(_ values: [Double], mean: Double) -> Double {
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    enum ResourceType {
        case cpu
        case memory
        case disk
    }
}

// MARK: - SystemStatsSample

struct SystemStatsSample {
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let networkUpload: Double
    let networkDownload: Double
}
