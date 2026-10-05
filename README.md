# Pulse

A system monitor for macOS — battery, disk, network, with anomaly detection.

## What it does

- Process list
- history
- battery
- disk
- network
- remote monitoring
- anomaly alerts

## Targets

- macOS with widgets

## Structure

Key types:

- ``AnomalyDetectionEngine``
- ``BatteryService``
- ``DiskService``
- ``NetworkService``
- ``RemoteMonitoringService``
- ``AlertNotificationService``
- ``WidgetGalleryView``

The anomaly detection is what lifts it above a standard Activity Monitor clone.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
