#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    /// iOS Blur Effect Service Client using SimpleServiceTemplate
    public final class iOSBlurEffectServiceClient: SimpleServiceTemplate {
        private let service = iOSBlurEffectService()

        override public init() {
            super.init()
        }

        public func createBlurredBackground(radius: CGFloat) async -> AnyView {
            await executeMainActorOperation {
                self.service.createBlurredBackground(radius: radius)
            }
        }

        public func supportsNativeBlur() async -> Bool {
            await executeMainActorOperation {
                self.service.supportsNativeBlur()
            }
        }

        public func recommendedBlurStyle() async -> UIBlurEffect.Style {
            await executeMainActorOperation {
                self.service.recommendedBlurStyle()
            }
        }
    }

    public extension BlurEffectServiceClient {
        static let iOS: Self = {
            let client = iOSBlurEffectServiceClient()
            return Self(
                _createBlurredBackground: { radius in
                    await client.createBlurredBackground(radius: radius)
                },
                _supportsNativeBlur: {
                    await client.supportsNativeBlur()
                },
                _recommendedBlurStyle: {
                    await client.recommendedBlurStyle()
                }
            )
        }()
    }
#endif
