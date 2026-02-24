import ProjectDescription

let project = Project(
    name: "Transly",
    targets: [
        .target(
            name: "Transly",
            destinations: .macOS,
            product: .app,
            bundleId: "com.icuxika.Transly",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "NSAppTransportSecurity": [
                    "NSAllowsArbitraryLoads": true
                ],
                "NSHumanReadableCopyright": "Copyright © 2024 icuxika. All rights reserved.",
                "LSMinimumSystemVersion": "14.0",
                "NSAppleEventsUsageDescription": "Transly needs access to send Apple Events for text selection monitoring.",
                "NSSystemAdministrationUsageDescription": "Transly needs accessibility permissions to monitor text selections and provide instant translations.",
                "NSScreenCaptureUsageDescription": "Transly needs screen recording permission to capture screenshots for OCR text recognition."
            ]),
            buildableFolders: [
                "Transly/Sources",
                "Transly/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "TranslyTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.icuxika.TranslyTests",
            infoPlist: .default,
            buildableFolders: [
                "Transly/Tests"
            ],
            dependencies: [.target(name: "Transly")]
        ),
    ]
)
