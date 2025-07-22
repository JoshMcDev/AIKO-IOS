#!/bin/bash

# Batch rename script for iOS type names
cd "/Users/J/aiko"

echo "Starting batch iOS type name fixes..."

# Define the rename mappings for iOS types
declare -A ios_renames=(
    ["iOSAccessibilityService"]="IOSAccessibilityService"
    ["iOSFontScalingService"]="IOSFontScalingService"
    ["iOSTextFieldService"]="IOSTextFieldService"
    ["iOSScreenService"]="IOSScreenService"
    ["iOSClipboardService"]="IOSClipboardService"
    ["iOSBlurEffectService"]="IOSBlurEffectService"
    ["iOSShareService"]="IOSShareService"
    ["iOSImageLoader"]="IOSImageLoader"
    ["iOSPlatformViewService"]="IOSPlatformViewService"
    ["iOSThemeService"]="IOSThemeService"
    ["iOSEmailService"]="IOSEmailService"
    ["iOSKeyboardService"]="IOSKeyboardService"
    ["iOSNavigationService"]="IOSNavigationService"
    ["iOSVoiceRecordingClient"]="IOSVoiceRecordingClient"
    ["iOSAudioRecorder"]="IOSAudioRecorder"
    ["iOSEmailServiceClient"]="IOSEmailServiceClient"
    ["iOSNavigationServiceClient"]="IOSNavigationServiceClient"
    ["iOSScreenServiceClient"]="IOSScreenServiceClient"
    ["iOSBlurEffectServiceClient"]="IOSBlurEffectServiceClient"
    ["iOSFontScalingServiceClient"]="IOSFontScalingServiceClient"
    ["iOSFontScalingServiceClientLive"]="IOSFontScalingServiceClientLive"
    ["iOSPlatformViewServiceClient"]="IOSPlatformViewServiceClient"
    ["iOSThemeServiceClient"]="IOSThemeServiceClient"
    ["iOSThemeServiceClientLive"]="IOSThemeServiceClientLive"
    ["iOSShareServiceClient"]="IOSShareServiceClient"
    ["iOSDependencyRegistration"]="IOSDependencyRegistration"
    ["iOSAccessibilityServiceClient"]="IOSAccessibilityServiceClient"
    ["iOSHapticManagerClient"]="IOSHapticManagerClient"
    ["iOSHapticManager"]="IOSHapticManager"
    ["iOSKeyboardServiceClient"]="IOSKeyboardServiceClient"
    ["iOSKeyboardServiceClientLive"]="IOSKeyboardServiceClientLive"
    ["iOSFileSystemClient"]="IOSFileSystemClient"
    ["iOSDocumentScannerClient"]="IOSDocumentScannerClient"
    ["iOSTextFieldServiceClient"]="IOSTextFieldServiceClient"
    ["iOSCameraClient"]="IOSCameraClient"
    ["iOSImageLoaderClient"]="IOSImageLoaderClient"
    ["iOSImageLoaderClientLive"]="IOSImageLoaderClientLive"
)

# Define view renames
declare -A view_renames=(
    ["iOSImagePicker"]="IOSImagePicker"
    ["iOSDocumentScanner"]="IOSDocumentScanner"
    ["iOSImagePickerView"]="IOSImagePickerView"
    ["iOSNavigationStack"]="IOSNavigationStack"
    ["iOSNavigationBarStyleModifier"]="IOSNavigationBarStyleModifier"
    ["iOSTabView"]="IOSTabView"
    ["iOSTabBarStyleModifier"]="IOSTabBarStyleModifier"
    ["iOSShareSheet"]="IOSShareSheet"
    ["iOSShareButton"]="IOSShareButton"
    ["iOSShareView"]="IOSShareView"
    ["iOSActivityItemProvider"]="IOSActivityItemProvider"
    ["iOSDocumentPicker"]="IOSDocumentPicker"
    ["iOSDocumentPickerView"]="IOSDocumentPickerView"
    ["iOSMenuView"]="IOSMenuView"
    ["iOSProfileImagePicker"]="IOSProfileImagePicker"
    ["iOSAppView"]="IOSAppView"
    ["iOSAppViewServices"]="IOSAppViewServices"
    ["iOSCameraImagePicker"]="IOSCameraImagePicker"
)

# Define test class renames
declare -A test_renames=(
    ["iOSHapticManagerClientTests"]="IOSHapticManagerClientTests"
    ["iOSThemeServiceClientTests"]="IOSThemeServiceClientTests"
    ["iOSBlurEffectServiceClientTests"]="IOSBlurEffectServiceClientTests"
    ["iOSKeyboardServiceClientTests"]="IOSKeyboardServiceClientTests"
    ["iOSAccessibilityServiceClientTests"]="IOSAccessibilityServiceClientTests"
    ["iOSPlatformViewServiceClientTests"]="IOSPlatformViewServiceClientTests"
    ["iOSNavigationServiceClientTests"]="IOSNavigationServiceClientTests"
    ["iOSTextFieldServiceClientTests"]="IOSTextFieldServiceClientTests"
    ["iOSShareServiceClientTests"]="IOSShareServiceClientTests"
    ["iOSScreenServiceClientTests"]="IOSScreenServiceClientTests"
    ["iOSClipboardServiceClientTests"]="IOSClipboardServiceClientTests"
    ["iOSImageLoaderClientTests"]="IOSImageLoaderClientTests"
    ["iOSFontScalingServiceClientTests"]="IOSFontScalingServiceClientTests"
)

# Function to perform the rename
perform_rename() {
    local old_name="$1"
    local new_name="$2"
    echo "Renaming $old_name -> $new_name"
    
    # Use sed to replace in all Swift files, being careful with word boundaries
    find . -name "*.swift" -type f -exec sed -i '' "s/\b${old_name}\b/${new_name}/g" {} \;
}

# Perform all iOS renames
for old_name in "${!ios_renames[@]}"; do
    new_name="${ios_renames[$old_name]}"
    perform_rename "$old_name" "$new_name"
done

# Perform view renames
for old_name in "${!view_renames[@]}"; do
    new_name="${view_renames[$old_name]}"
    perform_rename "$old_name" "$new_name"
done

# Perform test renames
for old_name in "${!test_renames[@]}"; do
    new_name="${test_renames[$old_name]}"
    perform_rename "$old_name" "$new_name"
done

echo "iOS type name fixes completed."