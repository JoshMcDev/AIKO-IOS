#!/bin/bash
cd "/Users/J/aiko"

echo "Fixing remaining iOS type names..."

# Core types that need to be fixed
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSImageLoaderClientLive\b/IOSImageLoaderClientLive/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSBlurEffectServiceClient\b/IOSBlurEffectServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSNavigationServiceClient\b/IOSNavigationServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSEmailServiceClient\b/IOSEmailServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSDependencyRegistration\b/IOSDependencyRegistration/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSScreenServiceClient\b/IOSScreenServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSPlatformViewServiceClient\b/IOSPlatformViewServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAudioRecorder\b/IOSAudioRecorder/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSFontScalingServiceClient\b/IOSFontScalingServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSFontScalingServiceClientLive\b/IOSFontScalingServiceClientLive/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSThemeServiceClient\b/IOSThemeServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSThemeServiceClientLive\b/IOSThemeServiceClientLive/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareServiceClient\b/IOSShareServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAccessibilityServiceClient\b/IOSAccessibilityServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSHapticManagerClient\b/IOSHapticManagerClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSHapticManager\b/IOSHapticManager/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSKeyboardServiceClient\b/IOSKeyboardServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSKeyboardServiceClientLive\b/IOSKeyboardServiceClientLive/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSFileSystemClient\b/IOSFileSystemClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSDocumentScannerClient\b/IOSDocumentScannerClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSTextFieldServiceClient\b/IOSTextFieldServiceClient/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSCameraClient\b/IOSCameraClient/g' {} \;

# Views
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSImagePicker\b/IOSImagePicker/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSDocumentScanner\b/IOSDocumentScanner/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSImagePickerView\b/IOSImagePickerView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSNavigationStack\b/IOSNavigationStack/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSNavigationBarStyleModifier\b/IOSNavigationBarStyleModifier/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSTabView\b/IOSTabView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSTabBarStyleModifier\b/IOSTabBarStyleModifier/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareSheet\b/IOSShareSheet/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareButton\b/IOSShareButton/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareView\b/IOSShareView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSActivityItemProvider\b/IOSActivityItemProvider/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSDocumentPicker\b/IOSDocumentPicker/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSDocumentPickerView\b/IOSDocumentPickerView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSMenuView\b/IOSMenuView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSProfileImagePicker\b/IOSProfileImagePicker/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAppView\b/IOSAppView/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAppViewServices\b/IOSAppViewServices/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSCameraImagePicker\b/IOSCameraImagePicker/g' {} \;

# Services
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAccessibilityService\b/IOSAccessibilityService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSFontScalingService\b/IOSFontScalingService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSTextFieldService\b/IOSTextFieldService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSScreenService\b/IOSScreenService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSClipboardService\b/IOSClipboardService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSBlurEffectService\b/IOSBlurEffectService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareService\b/IOSShareService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSImageLoader\b/IOSImageLoader/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSPlatformViewService\b/IOSPlatformViewService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSThemeService\b/IOSThemeService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSEmailService\b/IOSEmailService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSKeyboardService\b/IOSKeyboardService/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSNavigationService\b/IOSNavigationService/g' {} \;

# Test classes  
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSHapticManagerClientTests\b/IOSHapticManagerClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSThemeServiceClientTests\b/IOSThemeServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSBlurEffectServiceClientTests\b/IOSBlurEffectServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSKeyboardServiceClientTests\b/IOSKeyboardServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSAccessibilityServiceClientTests\b/IOSAccessibilityServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSPlatformViewServiceClientTests\b/IOSPlatformViewServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSNavigationServiceClientTests\b/IOSNavigationServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSTextFieldServiceClientTests\b/IOSTextFieldServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSShareServiceClientTests\b/IOSShareServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSScreenServiceClientTests\b/IOSScreenServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSClipboardServiceClientTests\b/IOSClipboardServiceClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSImageLoaderClientTests\b/IOSImageLoaderClientTests/g' {} \;
find . -name "*.swift" -type f -exec sed -i '' 's/\biOSFontScalingServiceClientTests\b/IOSFontScalingServiceClientTests/g' {} \;

echo "iOS type name fixes completed."