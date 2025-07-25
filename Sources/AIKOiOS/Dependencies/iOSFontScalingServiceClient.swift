#if os(iOS)
    import AppCore
    @preconcurrency import SwiftUI
    import UIKit

    /// iOS Font Scaling Service Client using SimpleServiceTemplate
    public final class IOSFontScalingServiceClient: SimpleServiceTemplate {
        @MainActor
        lazy var service = IOSFontScalingService()

        override public init() {
            super.init()
        }

        public func scaledFontSize(for baseSize: CGFloat, textStyle: SwiftUI.Font.TextStyle, sizeCategory: SwiftUI.ContentSizeCategory) async -> CGFloat {
            await executeMainActorOperation {
                self.service.scaledFontSize(for: baseSize, textStyle: textStyle, sizeCategory: sizeCategory)
            }
        }

        public func supportsUIFontMetrics() async -> Bool {
            await executeMainActorOperation {
                self.service.supportsUIFontMetrics()
            }
        }
    }

    public extension FontScalingServiceClient {
        @MainActor
        static var iOS: Self {
            let client = IOSFontScalingServiceClient()

            return Self(
                _scaledFontSize: { baseSize, sendableTextStyle, sendableSizeCategory in
                    // Run synchronously on MainActor since we need to return immediately
                    MainActor.assumeIsolated {
                        client.service.scaledFontSize(
                            for: baseSize,
                            textStyle: sendableTextStyle.textStyle,
                            sizeCategory: sendableSizeCategory.sizeCategory
                        )
                    }
                },
                _supportsUIFontMetrics: {
                    // Run synchronously on MainActor since we need to return immediately
                    MainActor.assumeIsolated {
                        client.service.supportsUIFontMetrics()
                    }
                }
            )
        }
    }

    // Convenience static accessor
    public enum IOSFontScalingServiceClientLive {
        @MainActor
        public static var live: FontScalingServiceClient {
            FontScalingServiceClient.iOS
        }
    }
#endif
