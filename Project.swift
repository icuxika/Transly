import ProjectDescription

let project = Project(
    name: "Transly",
    options: .options(
        defaultKnownRegions: ["en", "zh-Hans"],
        developmentRegion: "zh-Hans",
    ),
    targets: [
        .target(
            name: "Transly",
            destinations: .macOS,
            product: .app,
            bundleId: "com.icuxika.Transly",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                "LSUIElement": true,
                "NSScreenCaptureUsageDescription": "需要截取屏幕内容以识别图片中的文字并完成翻译。(Need to capture screen content to recognize text in images and complete translation.)",
                "SUPublicEDKey": "$(SPARKLE_PUBLIC_ED_KEY)",
                "SUFeedURL": "https://github.com/icuxika/Transly/releases/latest/download/appcast.xml"
            ]),
            buildableFolders: [
                "Transly/Sources",
                "Transly/Resources",
            ],
            dependencies: [
                .external(name: "Sparkle")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "$(TEST_CODE_SIGN_STYLE)",
                    "DEVELOPMENT_TEAM": "$(TEST_DEVELOPMENT_TEAM)",
                    "CODE_SIGN_IDENTITY": "$(TEST_CODE_SIGN_IDENTITY)",
                    "MARKETING_VERSION": "0.2.1",
                    "CURRENT_PROJECT_VERSION": "1"
                ],
                configurations: [
                    .debug(name: .debug, xcconfig: "Configurations/signing.xcconfig"),
                    .release(name: .release, xcconfig: "Configurations/signing.xcconfig")
                ]
            ),
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
