# Pulse — Brand Guide

## 1. Concept & Vision

Pulse is a live system monitor that keeps you informed about your Mac's vitals — CPU, memory, disk, and network — at a glance. It feels like a **high-end instrument cluster**: precise, real-time, data-dense but readable. The brand is confident and modern, with a dark aesthetic that feels native to macOS menu bar utilities while standing out as premium.

**App type:** Menu bar utility (LSUIElement)
**Core function:** Real-time CPU/memory/disk/network monitoring, process list, widget gallery, alert notifications, history/export.

---

## 2. Icon Concept — "The Live Pulse"

### Visual Description

A circular gauge/monitor with a pulsing waveform (ECG/pulse line) inside. The waveform peaks in the center — the "heartbeat" of the system. The circle has a subtle glow effect suggesting a live, active monitor. The overall feel is **live, precise, and high-performance** — a tool for people who care about what's happening under the hood.

**Key elements:**
- **Shape:** A circular form (like a gauge or radar display) with a pulsing line graph inside
- **Primary glyph:** An ECG-style heartbeat line — two peaks (PQRST pattern simplified to two sharp peaks)
- **Fill:** The circle background is dark (`#1E1E2E`) with a subtle gradient suggesting depth. The pulse line is electric cyan (`#6C9EFF`) with a soft glow.
- **Color coding:** The ring around the circle uses the same color coding as the usage stats — green/yellow/red gradient at the edges

### Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Background | `#1E1E2E` | App background |
| Surface | `#2A2A3E` | Cards, panels |
| Surface Light | `#363650` | Elevated surfaces |
| Primary Accent | `#6C9EFF` | Pulse line, primary UI |
| CPU System | `#FF9F6C` | CPU system usage |
| CPU User | `#6C9EFF` | CPU user usage |
| Status Green | `#4ADE80` | Healthy / low usage |
| Status Amber | `#FBBF24` | Moderate usage |
| Status Red | `#F87171` | High / critical usage |
| Network Up | `#4ADE80` | Upload |
| Network Down | `#60A5FA` | Download |
| Text Primary | `#FFFFFF` | Main labels |
| Text Secondary | `#A0A0B8` | Secondary labels |

### Typography

- **Primary font:** SF Pro (system, clean, readable at small sizes for data)
- **Headings:** SF Pro Medium, 14–16pt
- **Data/numbers:** SF Pro Rounded Medium (tabular figures for alignment)
- **Labels:** SF Pro Text Regular, 11–12pt
- **Fallback:** `.systemFont` with `design: .rounded` for data

### Visual Motif

**The ECG Pulse** — the live heartbeat line inside a circular monitor. This is the iconic motif: a simplified PQRST wave. The circular container evokes a gauge or radar. The cyan glow on the pulse line suggests active, real-time data. The dark background keeps focus on the data — Pulse is a monitoring tool, and it looks like one.

### Icon at Different Sizes

| Size | Rendering |
|------|-----------|
| **16×16** | Small circle with a tiny pulse line. Cyan dot. Minimal. |
| **32×32** | Circle with a simple single-peak pulse line inside. Cyan. |
| **64×64** | Circle with full double-peak pulse line. Faint glow. Ring shows faint color gradient. |
| **128×128** | Pulse line with a subtle outer glow. Circle has a faint gradient ring (green→amber→red). |
| **256×256** | Rich: full ECG waveform, glow effect, faint circular grid lines in background. |
| **512×512** | Detailed: circular grid, multi-segment pulse line, glow, slight dark gradient background inside circle. |
| **1024×1024** | Full brand: dark charcoal background, large circular monitor, bold ECG double-peak line in electric cyan with a soft outer glow, subtle concentric grid rings inside the circle suggesting precision instrumentation, small satellite dots/nodes suggesting system nodes (CPU/RAM/DISK/NET), polished shadow, premium finish. |

---

## 3. Placeholder Icon (SwiftUI)

The placeholder icon renders the Pulse brand concept as a SwiftUI view for preview. Place in `Sources/Views/AppIconView.swift`.

```swift
import SwiftUI

struct PulseAppIconView: View {
    var body: some View {
        PulseIconShape()
            .frame(width: 256, height: 256)
    }
}

struct PulseIconShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Dark charcoal background
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(hex: "1E1E2E"))

                // Shadow
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(0.3), radius: size * 0.05, x: 0, y: size * 0.04)

                // Circular monitor ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "4ADE80"),
                                Color(hex: "FBBF24"),
                                Color(hex: "F87171")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: size * 0.015
                    )
                    .frame(width: size * 0.62, height: size * 0.62)

                // Inner circle (dark surface)
                Circle()
                    .fill(Color(hex: "2A2A3E"))
                    .frame(width: size * 0.58, height: size * 0.58)

                // Concentric grid rings (subtle)
                ForEach([0.2, 0.35, 0.48], id: \.self) { ringSize in
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: size * 0.008)
                        .frame(width: size * ringSize, height: size * ringSize)
                }

                // ECG pulse line
                PulseWave(size: size)
                    .stroke(
                        Color(hex: "6C9EFF"),
                        style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.5, height: size * 0.18)
                    .shadow(color: Color(hex: "6C9EFF").opacity(0.6), radius: size * 0.02)

                // Center dot (heart of the monitor)
                Circle()
                    .fill(Color(hex: "6C9EFF"))
                    .frame(width: size * 0.04, height: size * 0.04)
                    .shadow(color: Color(hex: "6C9EFF").opacity(0.8), radius: size * 0.015)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct PulseWave: Shape {
    let size: CGFloat

    var animPhase: Double = 0

    var animatableData: Double {
        get { animPhase }
        set { animPhase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height

        // ECG-style double peak
        // Flat start → small P peak → Q dip → R/S tall peak → T peak → flat end
        path.move(to: CGPoint(x: 0, y: h * 0.5))

        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.5))
        // P wave
        path.addQuadCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.35),
            control: CGPoint(x: w * 0.14, y: h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.25, y: h * 0.5),
            control: CGPoint(x: w * 0.22, y: h * 0.6)
        )

        // Q dip
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.7))

        // R peak (tall)
        path.addLine(to: CGPoint(x: w * 0.38, y: h * 0.05))

        // S dip
        path.addLine(to: CGPoint(x: w * 0.44, y: h * 0.75))

        // Return to baseline
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))

        // T wave
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.3),
            control: CGPoint(x: w * 0.58, y: h * 0.28)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.72, y: h * 0.5),
            control: CGPoint(x: w * 0.68, y: h * 0.6)
        )

        path.addLine(to: CGPoint(x: w, y: h * 0.5))

        return path
    }
}
```

---

## 4. Secondary Icon Elements

- **Menu bar icon:** Small (18×18pt): a tiny circle with a micro pulse line. Cyan on dark. Shows live status by color (green=healthy, amber=moderate, red=high load).
- **Tab/feature icons:** SF Symbols — `cpu`, `memorychip`, `externaldrive`, `network`, `chart.xyaxis.line`, `bell`
- **Usage rings:** Concentric circles with arc fills showing CPU/memory/disk/network usage
- **Alert states:** Pulsing red ring when critical

---

## 5. Spatial System

| Token | Value |
|-------|-------|
| Padding SM | 8pt |
| Padding MD | 16pt |
| Padding LG | 24pt |
| Corner Radius | 12pt |
| Corner Radius SM | 6pt |
