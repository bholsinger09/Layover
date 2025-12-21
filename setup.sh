#!/bin/bash

# Layover Project Setup Script
# This script helps set up the Xcode project for multi-platform development

set -e

echo "🎮 Setting up Layover Project..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create necessary directories
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p Sources/{Models,Views,ViewModels,Services}
mkdir -p Tests/{Models,Services,ViewModels}
mkdir -p Resources

# Generate Xcode project from Swift Package
echo -e "${BLUE}Generating Xcode project...${NC}"
swift package generate-xcodeproj || true

echo -e "${GREEN}✅ Project structure created${NC}"

# Display next steps
echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Layover Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "1. Open Package.swift in Xcode 15+"
echo "2. Select your target device (iOS, macOS, tvOS, or visionOS)"
echo "3. Configure Signing & Capabilities:"
echo "   - Add App Groups: group.com.layover.app"
echo "   - Enable Group Activities (SharePlay)"
echo "   - Enable MusicKit"
echo "4. Run tests with ⌘U"
echo "5. Build and run with ⌘R"
echo ""
echo "📚 See DEVELOPMENT.md for detailed documentation"
echo ""
echo -e "${BLUE}Note: SharePlay requires physical devices and an active FaceTime call${NC}"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  Warning: Xcode command line tools not found"
    echo "   Install from: https://developer.apple.com/xcode/"
fi

# Check Swift version
SWIFT_VERSION=$(swift --version | head -n 1)
echo "Swift version: $SWIFT_VERSION"

echo ""
echo "🚀 Ready to build Layover!"
