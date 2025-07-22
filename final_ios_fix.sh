#!/bin/bash
cd "/Users/J/aiko"

echo "Final batch fix for all remaining iOS type name violations..."

# Most critical/common iOS types to fix all at once
perl -pi -e 's/\biOSImageLoaderClientLive\b/IOSImageLoaderClientLive/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSBlurEffectServiceClient\b/IOSBlurEffectServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSNavigationServiceClient\b/IOSNavigationServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSScreenServiceClient\b/IOSScreenServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSDependencyRegistration\b/IOSDependencyRegistration/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSFontScalingServiceClient\b/IOSFontScalingServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSFontScalingServiceClientLive\b/IOSFontScalingServiceClientLive/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSAudioRecorder\b/IOSAudioRecorder/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSPlatformViewServiceClient\b/IOSPlatformViewServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSThemeServiceClient\b/IOSThemeServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSThemeServiceClientLive\b/IOSThemeServiceClientLive/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSShareServiceClient\b/IOSShareServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSAccessibilityServiceClient\b/IOSAccessibilityServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSHapticManagerClient\b/IOSHapticManagerClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSHapticManager\b/IOSHapticManager/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSKeyboardServiceClient\b/IOSKeyboardServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSKeyboardServiceClientLive\b/IOSKeyboardServiceClientLive/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSFileSystemClient\b/IOSFileSystemClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSDocumentScannerClient\b/IOSDocumentScannerClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSTextFieldServiceClient\b/IOSTextFieldServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSCameraClient\b/IOSCameraClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true
perl -pi -e 's/\biOSEmailServiceClient\b/IOSEmailServiceClient/g' Sources/**/*.swift Tests/**/*.swift 2>/dev/null || true

echo "iOS type name fixes completed with perl."