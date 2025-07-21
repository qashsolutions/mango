#!/bin/bash

# Siri Integration Verification Script for MedicationManager
# This script checks that all required files for Siri integration are in place

echo "🔍 Verifying Siri Integration Setup for MedicationManager"
echo "========================================================"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
FOUND_FILES=0
MISSING_FILES=0

# Function to check file existence
check_file() {
    local file_path=$1
    local description=$2
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅ FOUND${NC}: $description"
        echo "   Path: $file_path"
        FOUND_FILES=$((FOUND_FILES + 1))
    else
        echo -e "${RED}❌ MISSING${NC}: $description"
        echo "   Expected at: $file_path"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
    echo ""
}

# Function to check for specific content in a file
check_content() {
    local file_path=$1
    local search_string=$2
    local description=$3
    
    if [ -f "$file_path" ]; then
        if grep -q "$search_string" "$file_path"; then
            echo -e "${GREEN}✅ VERIFIED${NC}: $description"
        else
            echo -e "${YELLOW}⚠️  WARNING${NC}: $description not found in $file_path"
        fi
    fi
}

echo "1. Checking Main App Files"
echo "--------------------------"
check_file "MedicationManager/Info.plist" "Main App Info.plist"
check_content "MedicationManager/Info.plist" "NSSiriUsageDescription" "Siri usage description"
check_content "MedicationManager/Info.plist" "INIntentsSupported" "Supported intents list"

check_file "MedicationManager/MedicationManager.entitlements" "Main App Entitlements"
check_content "MedicationManager/MedicationManager.entitlements" "com.apple.developer.siri" "Siri capability"

check_file "MedicationManager/Core/Utilities/CoreDataManager.swift" "Core Data Manager"
check_content "MedicationManager/Core/Utilities/CoreDataManager.swift" "migrateToAppGroupIfNeeded" "App Group migration method"

check_file "MedicationManager/App/MedicationManagerApp.swift" "Main App File"
check_content "MedicationManager/App/MedicationManagerApp.swift" "setupSharedUserDefaults" "Shared UserDefaults setup"

echo ""
echo "2. Checking MedicationManagerKit Framework"
echo "------------------------------------------"
check_file "MedicationManagerKit/Info.plist" "Framework Info.plist"
check_file "MedicationManagerKit/ExtensionError.swift" "Extension Error Definitions"
check_file "MedicationManagerKit/ExtensionKeychain.swift" "Extension Keychain Manager"
check_file "MedicationManagerKit/SharedCoreDataManager.swift" "Shared Core Data Manager"
check_file "MedicationManagerKit/Models/SendableMedication.swift" "Sendable Medication Model"
check_file "MedicationManagerKit/Models/SendableSupplement.swift" "Sendable Supplement Model"
check_file "MedicationManagerKit/Models/SendableUser.swift" "Sendable User Model"
check_file "MedicationManagerKit/Managers/ExtensionClaudeAPIClient.swift" "Extension Claude API Client"
check_file "MedicationManagerKit/Managers/ExtensionAnalyticsManager.swift" "Extension Analytics Manager"

echo ""
echo "3. Checking MedicationIntents Extension"
echo "---------------------------------------"
check_file "MedicationIntents/Info.plist" "Extension Info.plist"
check_file "MedicationIntents/MedicationIntents.entitlements" "Extension Entitlements"
check_file "MedicationIntents/IntentHandler.swift" "Main Intent Handler"

echo ""
echo "4. Checking Intent Handlers"
echo "---------------------------"
check_file "MedicationIntents/Handlers/CheckConflictsIntentHandler.swift" "Check Conflicts Handler"
check_file "MedicationIntents/Handlers/ViewMedicationsIntentHandler.swift" "View Medications Handler"
check_file "MedicationIntents/Handlers/LogMedicationIntentHandler.swift" "Log Medication Handler"
check_file "MedicationIntents/Handlers/AddMedicationIntentHandler.swift" "Add Medication Handler"
check_file "MedicationIntents/Handlers/AskMedicalQuestionIntentHandler.swift" "Ask Medical Question Handler"
check_file "MedicationIntents/Handlers/SetReminderIntentHandler.swift" "Set Reminder Handler"

echo ""
echo "5. Checking Intent Definition File"
echo "----------------------------------"
check_file "MedicationManager.intentdefinition" "Intent Definition File (Required for Xcode)"

echo ""
echo "6. Checking Supporting Files"
echo "----------------------------"
check_file "MedicationManager/Intents/MedicationIntents.swift" "App Intents Definitions"
check_file "MedicationManager/Core/Managers/SiriIntentsManager.swift" "Siri Intents Manager"

echo ""
echo "========================================================"
echo "SUMMARY"
echo "========================================================"
echo -e "Total files checked: $TOTAL_FILES"
echo -e "${GREEN}Files found: $FOUND_FILES${NC}"
echo -e "${RED}Files missing: $MISSING_FILES${NC}"

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "\n${GREEN}✅ All required files are present!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Create MedicationManager.intentdefinition in Xcode"
    echo "2. Follow the specification in MedicationManager-IntentDefinition-Spec.md"
    echo "3. Build the project to generate intent classes"
    echo "4. Test Siri integration on a real device"
else
    echo -e "\n${RED}⚠️  Some files are missing. Please create them before proceeding.${NC}"
    
    if [ ! -f "MedicationManager.intentdefinition" ]; then
        echo ""
        echo -e "${YELLOW}IMPORTANT:${NC} The MedicationManager.intentdefinition file must be created in Xcode."
        echo "See MedicationManager-IntentDefinition-Spec.md for detailed instructions."
    fi
fi

echo ""
echo "========================================================"
echo "Additional Checks"
echo "========================================================"

# Check if Configuration has App Group
if [ -f "MedicationManager/Core/Configuration/Configuration.swift" ]; then
    if grep -q "appGroupIdentifier" "MedicationManager/Core/Configuration/Configuration.swift"; then
        echo -e "${GREEN}✅${NC} App Group identifier found in Configuration"
    else
        echo -e "${RED}❌${NC} App Group identifier not found in Configuration"
    fi
fi

# Check for potential issues
echo ""
echo "Potential Issues to Check:"
echo "- Ensure all files are added to correct targets in Xcode"
echo "- Verify App Groups are enabled in all targets"
echo "- Check that bundle identifiers match across targets"
echo "- Confirm Siri capability is enabled in Xcode"

echo ""
echo "Script completed."