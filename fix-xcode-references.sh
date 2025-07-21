#!/bin/bash

# Fix Xcode Stale References Script
# This helps identify and remove stale file references from Xcode project

echo "🔍 Searching for stale Intent references in Xcode project..."

# Find references to the nested Intents directory in the project file
PROJECT_FILE="/Users/cvr/Documents/Project/MedicationManager/MedicationManager.xcodeproj/project.pbxproj"

if [ -f "$PROJECT_FILE" ]; then
    echo "📋 Found references to nested Intents directory:"
    grep -n "Intents/Intents" "$PROJECT_FILE" | head -20
    
    echo -e "\n⚠️  These references need to be removed from Xcode"
    echo -e "\n📝 Steps to fix:"
    echo "1. Open MedicationManager.xcodeproj in Xcode"
    echo "2. In the Project Navigator, look for red (missing) files:"
    echo "   - AskMedicalQuestionIntent.swift"
    echo "   - SetMedicationReminderIntent.swift"
    echo "   - Any other files under a nested Intents/Intents folder"
    echo "3. Right-click each red file and select 'Delete' → 'Remove Reference'"
    echo "4. Clean Build Folder: Product → Clean Build Folder (⇧⌘K)"
    echo "5. Build: Product → Build (⌘B)"
    
    echo -e "\n✅ The correct Intent files are already in:"
    echo "   /MedicationManager/Intents/MedicationIntentsImplementation.swift"
    echo "   /MedicationManager/Intents/Entities/"
    echo "   /MedicationManager/Intents/Shortcuts/"
else
    echo "❌ Could not find Xcode project file"
fi

echo -e "\n🔧 Code fixes already applied:"
echo "✅ Changed 'static var' to 'static let' for openAppWhenRun"
echo "✅ Fixed KeychainManager.retrieveAPIKey() to use hasAPIKey(for: .claudeAPI)"
echo -e "\n💡 After removing stale references, the project should build successfully."