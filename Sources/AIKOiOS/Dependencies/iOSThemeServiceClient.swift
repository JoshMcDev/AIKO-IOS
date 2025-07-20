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
            let client = iOSThemeServiceClient()
            return Self(
                _backgroundColor: {
                    await client.backgroundColor()
                },
                _cardColor: {
                    await client.cardColor()
                },
                _secondaryColor: {
                    await client.secondaryColor()
                },
                _tertiaryColor: {
                    await client.tertiaryColor()
                },
                _groupedBackground: {
                    await client.groupedBackground()
                },
                _groupedSecondaryBackground: {
                    await client.groupedSecondaryBackground()
                },
                _groupedTertiaryBackground: {
                    await client.groupedTertiaryBackground()
                },
                _applyNavigationBarHidden: { view in
                    await client.applyNavigationBarHidden(to: view)
                },
                _applyDarkNavigationBar: { view in
                    await client.applyDarkNavigationBar(to: view)
                },
                _applySheet: { view in
                    await client.applySheet(to: view)
                }
            )
        }()
    }
#endif
