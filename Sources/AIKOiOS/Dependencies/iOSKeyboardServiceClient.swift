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
                let client = iOSKeyboardServiceClient()
                return await client.defaultKeyboardType()
            },
            emailKeyboardType: {
                let client = iOSKeyboardServiceClient()
                return await client.emailKeyboardType()
            },
            numberKeyboardType: {
                let client = iOSKeyboardServiceClient()
                return await client.numberKeyboardType()
            },
            phoneKeyboardType: {
                let client = iOSKeyboardServiceClient()
                return await client.phoneKeyboardType()
            },
            urlKeyboardType: {
                let client = iOSKeyboardServiceClient()
                return await client.urlKeyboardType()
            },
            supportsKeyboardTypes: {
                let client = iOSKeyboardServiceClient()
                return await client.supportsKeyboardTypes()
            }
        )
    }

    // Convenience static accessor
    public enum iOSKeyboardServiceClient {
        public static let live = KeyboardServiceClient.iOSLive
    }
#endif
