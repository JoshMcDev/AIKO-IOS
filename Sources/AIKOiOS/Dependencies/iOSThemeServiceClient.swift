#if os(iOS)
    import AppCore
    import ComposableArchitecture
    import SwiftUI

    /// iOS Theme Service Client using SimpleServiceTemplate
    public final class iOSThemeServiceClient: SimpleServiceTemplate {
        private let service = iOSThemeService()

        override public init() {
            super.init()
        }

        public func backgroundColor() async -> Color {
            await executeMainActorOperation {
                self.service.backgroundColor()
            }
        }

        public func cardColor() async -> Color {
            await executeMainActorOperation {
                self.service.cardColor()
            }
        }

        public func secondaryColor() async -> Color {
            await executeMainActorOperation {
                self.service.secondaryColor()
            }
        }

        public func tertiaryColor() async -> Color {
            await executeMainActorOperation {
                self.service.tertiaryColor()
            }
        }

        public func groupedBackground() async -> Color {
            await executeMainActorOperation {
                self.service.groupedBackground()
            }
        }

        public func groupedSecondaryBackground() async -> Color {
            await executeMainActorOperation {
                self.service.groupedSecondaryBackground()
            }
        }

        public func groupedTertiaryBackground() async -> Color {
            await executeMainActorOperation {
                self.service.groupedTertiaryBackground()
            }
        }

        public func applyNavigationBarHidden(to view: AnyView) async -> AnyView {
            await executeMainActorOperation {
                self.service.applyNavigationBarHidden(to: view)
            }
        }

        public func applyDarkNavigationBar(to view: AnyView) async -> AnyView {
            await executeMainActorOperation {
                self.service.applyDarkNavigationBar(to: view)
            }
        }

        public func applySheet(to view: AnyView) async -> AnyView {
            await executeMainActorOperation {
                self.service.applySheet(to: view)
            }
        }
    }

    public extension ThemeServiceClient {
        static let iOS: Self = {
            let service = iOSThemeService()
            return Self(
                _backgroundColor: {
                    service.backgroundColor()
                },
                _cardColor: {
                    service.cardColor()
                },
                _secondaryColor: {
                    service.secondaryColor()
                },
                _tertiaryColor: {
                    service.tertiaryColor()
                },
                _groupedBackground: {
                    service.groupedBackground()
                },
                _groupedSecondaryBackground: {
                    service.groupedSecondaryBackground()
                },
                _groupedTertiaryBackground: {
                    service.groupedTertiaryBackground()
                },
                _applyNavigationBarHidden: { view in
                    service.applyNavigationBarHidden(to: view)
                },
                _applyDarkNavigationBar: { view in
                    service.applyDarkNavigationBar(to: view)
                },
                _applySheet: { view in
                    service.applySheet(to: view)
                }
            )
        }()
    }

    // Convenience static accessor
    public enum iOSThemeServiceClientLive {
        public static let live = ThemeServiceClient.iOS
    }
#endif
