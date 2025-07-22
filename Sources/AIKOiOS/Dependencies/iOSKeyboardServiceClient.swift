#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import Foundation

    /// iOS Keyboard Service Client using SimpleServiceTemplate
    public final class IOSKeyboardServiceClient: SimpleServiceTemplate {
        private let service = IOSKeyboardService()

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
                .default
            },
            emailKeyboardType: {
                .email
            },
            numberKeyboardType: {
                .number
            },
            phoneKeyboardType: {
                .phone
            },
            urlKeyboardType: {
                .url
            },
            supportsKeyboardTypes: {
                let service = IOSKeyboardService()
                return service.supportsKeyboardTypes
            }
        )
    }

    // Convenience static accessor
    public enum IOSKeyboardServiceClientLive {
        public static let live = KeyboardServiceClient.iOSLive
    }
#endif
