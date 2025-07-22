#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    /// iOS Blur Effect Service Client using SimpleServiceTemplate
    public final class IOSBlurEffectServiceClient: SimpleServiceTemplate {
        private let service = IOSBlurEffectService()

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
            let service = IOSBlurEffectService()
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
