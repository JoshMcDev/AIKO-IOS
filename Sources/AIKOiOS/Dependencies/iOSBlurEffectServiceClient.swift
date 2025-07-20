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

        public func recommendedBlurStyle() async -> Material {
            await executeMainActorOperation {
                self.service.recommendedBlurStyle()
            }
        }
    }

    public extension BlurEffectServiceClient {
        static let iOS: Self = {
            let service = iOSBlurEffectService()
            return Self(
                _createBlurredBackground: { radius in
                    service.createBlurredBackground(radius: radius)
                },
                _supportsNativeBlur: {
                    service.supportsNativeBlur()
                },
                _recommendedBlurStyle: {
                    service.recommendedBlurStyle()
                }
            )
        }()
    }
#endif
