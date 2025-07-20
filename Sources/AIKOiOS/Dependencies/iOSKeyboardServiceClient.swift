#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// iOS Keyboard Service Client using SimpleServiceTemplate
    public final class iOSKeyboardServiceClient: SimpleServiceTemplate {
        private let service = iOSKeyboardService()

        override public init() {
            super.init()
        }

        public func defaultKeyboardType() async -> PlatformKeyboardType {
            await executeMainActorOperation {
                .default
            }
        }

        public func emailKeyboardType() async -> PlatformKeyboardType {
            await executeMainActorOperation {
                .email
            }
        }

        public func numberKeyboardType() async -> PlatformKeyboardType {
            await executeMainActorOperation {
                .number
            }
        }

        public func phoneKeyboardType() async -> PlatformKeyboardType {
            await executeMainActorOperation {
                .phone
            }
        }

        public func urlKeyboardType() async -> PlatformKeyboardType {
            await executeMainActorOperation {
                .url
            }
        }

        public func supportsKeyboardTypes() async -> Bool {
            await executeMainActorOperation {
                self.service.supportsKeyboardTypes
            }
        }
    }

    public extension KeyboardServiceClient {
        static let iOSLive = Self(
            defaultKeyboardType: {
                return .default
            },
            emailKeyboardType: {
                return .email
            },
            numberKeyboardType: {
                return .number
            },
            phoneKeyboardType: {
                return .phone
            },
            urlKeyboardType: {
                return .url
            },
            supportsKeyboardTypes: {
                let service = iOSKeyboardService()
                return service.supportsKeyboardTypes
            }
        )
    }

    // Convenience static accessor
    public enum iOSKeyboardServiceClientLive {
        public static let live = KeyboardServiceClient.iOSLive
    }
#endif
