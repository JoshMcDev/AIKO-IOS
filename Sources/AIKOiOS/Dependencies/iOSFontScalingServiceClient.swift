#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    /// iOS Font Scaling Service Client using SimpleServiceTemplate
    public final class iOSFontScalingServiceClient: SimpleServiceTemplate {
        private let service = iOSFontScalingService()

        override public init() {
            super.init()
        }

        public func scaledFontSize(for baseSize: CGFloat, textStyle: Font.TextStyle, sizeCategory: ContentSizeCategory) async -> CGFloat {
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
            let client = iOSFontScalingServiceClient()

            return Self(
                _scaledFontSize: { baseSize, textStyle, sizeCategory in
                    await client.scaledFontSize(for: baseSize, textStyle: textStyle, sizeCategory: sizeCategory)
                },
                _supportsUIFontMetrics: {
                    await client.supportsUIFontMetrics()
                }
            )
        }
    }

    // Convenience static accessor
    public enum iOSFontScalingServiceClient {
        public static let live = FontScalingServiceClient.iOS
    }
#endif
