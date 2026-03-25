# Pulse — Onboarding Guide

Pulse's onboarding is **fast, visual, and to the point**. It should feel like looking at a well-designed dashboard for the first time — "I immediately understand what I'm seeing." The flow consists of 4 screens.

**Tone:** Confident, precise, technical but accessible. "You now have x-ray vision for your Mac."

---

## Screen 1 — "Pulse Is Watching"

**Concept illustration:** A dark-themed scene showing the Pulse icon (circular monitor with ECG line) at center. Four small data panels float around it — CPU, Memory, Disk, Network — each showing a live-updating ring or chart. The whole scene pulses subtly.

**Headline:** "Your Mac's vital signs"

**Body:** "Pulse monitors CPU, memory, disk, and network in real time. Know exactly what's happening under the hood — at a glance."

**Primary CTA:** "Let's Go →"

**Secondary:** "Skip"

**Visual elements:**
- Dark background (`#1E1E2E`)
- Electric cyan (`#6C9EFF`) as primary accent
- Live-updating gauge rings around the central Pulse icon
- Green/amber/red status colors visible on the data panels

---

## Screen 2 — "Always Watching, Never in the Way"

**Concept illustration:** The Pulse icon visible in the macOS menu bar (top right). A small dropdown panel shows a compact summary — CPU %, memory %, network arrows. The panel is sleek and dark, matching macOS styling.

**Headline:** "One glance from your menu bar"

**Body:** "Pulse lives in your menu bar. No dock icon, no clutter — just a quiet indicator that updates in real time. Click anytime for the full dashboard."

**Key points:**
- 🍎 "Look for Pulse in your menu bar"
- 📊 "CPU, memory, and network at a glance"
- ⚡ "Zero performance impact — ultra-lightweight"

**Primary CTA:** "Continue →"

---

## Screen 3 — "When Something Needs Attention"

**Concept illustration:** A notification-style card showing a Pulse alert — e.g., "CPU at 95%" with a red ring. A small settings/preferences panel shows alert thresholds being configured.

**Headline:** "Alerts you actually care about"

**Body:** "Set custom thresholds for CPU, memory, disk, and network. Pulse notifies you only when something genuinely needs attention — no noise."

**Key points:**
- 🔔 "Smart alerts — only when it matters"
- ⚙️ "Customize thresholds per metric"
- 📋 "Alert history in the app"

**Primary CTA:** "Continue →"

---

## Screen 4 — "Your Mac, Demystified"

**Concept illustration:** A full Pulse dashboard view showing all four metrics (CPU, Memory, Disk, Network) with live rings and small sparkline charts. The dark theme is fully on display — premium and data-dense but organized.

**Headline:** "You're now in the know"

**Body:** "Pulse is running. The dashboard shows your Mac's vitals in real time. Explore the process list, historical charts, and widgets."

**Key callouts:**
- 📊 "Dashboard: all four metrics at once"
- 📈 "History: see trends over time"
- 🧩 "Widgets: pin metrics to your desktop"

**Primary CTA:** "Open Pulse"

---

## Implementation Notes

- Show onboarding only on first launch (`UserDefaults` flag `hasSeenOnboarding`)
- Dark theme (`#1E1E2E` background) for all onboarding screens — matches Pulse's aesthetic
- Use a `TabView` with page dots or a `VStack` walkthrough
- All colors from `Theme.swift` — no hardcoded hex in UI code
- Illustrations are SwiftUI `Shape` + `ZStack` compositions (no external assets needed)
