#!/bin/bash

# MedicationManager Project Validation Script
# This script performs comprehensive checks on all project files

echo "🔍 MedicationManager Project Validation"
echo "======================================"
echo "Started at: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_COUNT=0

# Arrays to store issues
declare -a SYNTAX_ERRORS
declare -a HARDCODED_VALUES
declare -a MISSING_IMPORTS
declare -a APPTHEME_VIOLATIONS
declare -a TODO_ITEMS

# Function to increment counters
check_passed() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

check_failed() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

check_warning() {
    WARNING_COUNT=$((WARNING_COUNT + 1))
}

# Function to check Swift syntax
check_swift_syntax() {
    local file=$1
    echo -n "  Checking syntax: "
    
    # Use swiftc to check syntax (dry run)
    if swiftc -parse -target arm64-apple-ios17.0 "$file" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        check_passed
    else
        echo -e "${RED}✗${NC}"
        SYNTAX_ERRORS+=("$file")
        check_failed
    fi
}

# Function to check for hardcoded values
check_hardcoded_values() {
    local file=$1
    local violations=0
    
    # Skip protected files
    if [[ "$file" == *"PhoneAuthView.swift" ]] || [[ "$file" == *"FirebaseManager.swift" ]]; then
        return 0
    fi
    
    # Check for hardcoded strings (not in AppStrings)
    if grep -E '\"[A-Za-z ]{3,}\"' "$file" | grep -v "AppStrings\." | grep -v "#if DEBUG" | grep -v "print(" | grep -v "Logger(" | grep -v "category:" | grep -v "subsystem:" &>/dev/null; then
        violations=$((violations + 1))
    fi
    
    # Check for hardcoded colors
    if grep -E '\.(red|blue|green|yellow|orange|purple|pink|gray|black|white)\b' "$file" | grep -v "AppTheme\.Colors" &>/dev/null; then
        violations=$((violations + 1))
    fi
    
    # Check for hardcoded fonts
    if grep -E '\.font\(\.system' "$file" | grep -v "AppTheme\.Typography" &>/dev/null; then
        violations=$((violations + 1))
    fi
    
    # Check for hardcoded padding/spacing
    if grep -E '\.(padding|spacing)\([0-9]+\)' "$file" | grep -v "AppTheme\.Spacing" &>/dev/null; then
        violations=$((violations + 1))
    fi
    
    # Check for hardcoded corner radius
    if grep -E '\.cornerRadius\([0-9]+\)' "$file" | grep -v "AppTheme\.CornerRadius" &>/dev/null; then
        violations=$((violations + 1))
    fi
    
    if [ $violations -gt 0 ]; then
        HARDCODED_VALUES+=("$file ($violations violations)")
        check_warning
    fi
}

# Function to check imports
check_imports() {
    local file=$1
    local missing_imports=0
    
    # Check if file uses AppTheme but doesn't import it
    if grep -E "AppTheme\." "$file" &>/dev/null; then
        if ! grep -E "^import.*AppTheme" "$file" &>/dev/null; then
            # AppTheme might be in the same module, so this is just a warning
            missing_imports=$((missing_imports + 1))
        fi
    fi
    
    # Check if file uses Firebase but doesn't import it
    if grep -E "Firebase|Auth\." "$file" &>/dev/null; then
        if ! grep -E "^import Firebase" "$file" &>/dev/null; then
            missing_imports=$((missing_imports + 1))
        fi
    fi
    
    if [ $missing_imports -gt 0 ]; then
        MISSING_IMPORTS+=("$file ($missing_imports potential missing imports)")
        check_warning
    fi
}

# Function to check AppTheme usage
check_apptheme_usage() {
    local file=$1
    
    # Skip non-UI files
    if [[ "$file" == *"Model"* ]] || [[ "$file" == *"Manager"* ]] || [[ "$file" == *"Error"* ]]; then
        return 0
    fi
    
    # Check if View files use AppTheme
    if [[ "$file" == *"View.swift" ]]; then
        if ! grep -E "AppTheme\." "$file" &>/dev/null; then
            APPTHEME_VIOLATIONS+=("$file (No AppTheme usage in View file)")
            check_warning
        fi
    fi
}

# Function to check for TODOs
check_todos() {
    local file=$1
    
    if grep -E "// TODO:|// FIXME:|// HACK:" "$file" &>/dev/null; then
        local count=$(grep -c -E "// TODO:|// FIXME:|// HACK:" "$file")
        TODO_ITEMS+=("$file ($count items)")
    fi
}

echo "1. Checking Swift Files"
echo "======================="

# Find all Swift files
swift_files=$(find . -name "*.swift" -not -path "./DerivedData/*" -not -path "./.build/*" -not -path "./Pods/*")
total_swift_files=$(echo "$swift_files" | wc -l | tr -d ' ')

echo "Found $total_swift_files Swift files"
echo ""

# Process each Swift file
file_count=0
for file in $swift_files; do
    file_count=$((file_count + 1))
    echo "[$file_count/$total_swift_files] $(basename "$file")"
    
    # Run all checks
    check_swift_syntax "$file"
    check_hardcoded_values "$file"
    check_imports "$file"
    check_apptheme_usage "$file"
    check_todos "$file"
done

echo ""
echo "2. Checking Configuration Files"
echo "==============================="

# Check AppStrings.swift
echo -n "AppStrings.swift: "
if [ -f "MedicationManager/Core/Configuration/AppStrings.swift" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
    
    # Check for proper structure
    if grep -E "struct AppStrings" "MedicationManager/Core/Configuration/AppStrings.swift" &>/dev/null; then
        echo "  - Structure: ${GREEN}✓${NC}"
        check_passed
    else
        echo "  - Structure: ${RED}✗${NC}"
        check_failed
    fi
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

# Check AppTheme.swift
echo -n "AppTheme.swift: "
if [ -f "MedicationManager/Core/Configuration/AppTheme.swift" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
    
    # Check for required components
    for component in "Colors" "Typography" "Spacing" "CornerRadius" "Animation"; do
        if grep -E "struct $component" "MedicationManager/Core/Configuration/AppTheme.swift" &>/dev/null; then
            echo "  - $component: ${GREEN}✓${NC}"
            check_passed
        else
            echo "  - $component: ${RED}✗${NC}"
            check_failed
        fi
    done
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

# Check AppIcons.swift
echo -n "AppIcons.swift: "
if [ -f "MedicationManager/Core/Configuration/AppIcons.swift" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

# Check Configuration.swift
echo -n "Configuration.swift: "
if [ -f "MedicationManager/Core/Configuration/Configuration.swift" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
    
    # Check for Extensions configuration
    if grep -E "struct Extensions" "MedicationManager/Core/Configuration/Configuration.swift" &>/dev/null; then
        echo "  - Extensions config: ${GREEN}✓${NC}"
        check_passed
    else
        echo "  - Extensions config: ${RED}✗${NC}"
        check_failed
    fi
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

echo ""
echo "3. Checking Project Structure"
echo "============================="

# Check required directories
directories=(
    "MedicationManager/App"
    "MedicationManager/Core"
    "MedicationManager/Features"
    "MedicationManager/Resources"
    "MedicationManagerKit"
    "MedicationIntents"
)

for dir in "${directories[@]}"; do
    echo -n "$dir: "
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC}"
        check_passed
    else
        echo -e "${RED}✗${NC}"
        check_failed
    fi
done

echo ""
echo "4. Checking Entitlements and Info.plist"
echo "======================================="

# Check entitlements
echo -n "MedicationManager.entitlements: "
if [ -f "MedicationManager/MedicationManager.entitlements" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
    
    # Check for Siri capability
    if grep -E "com.apple.developer.siri" "MedicationManager/MedicationManager.entitlements" &>/dev/null; then
        echo "  - Siri capability: ${GREEN}✓${NC}"
        check_passed
    else
        echo "  - Siri capability: ${RED}✗${NC}"
        check_failed
    fi
    
    # Check for App Groups
    if grep -E "com.apple.security.application-groups" "MedicationManager/MedicationManager.entitlements" &>/dev/null; then
        echo "  - App Groups: ${GREEN}✓${NC}"
        check_passed
    else
        echo "  - App Groups: ${RED}✗${NC}"
        check_failed
    fi
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

# Check Info.plist
echo -n "Info.plist: "
if [ -f "MedicationManager/Info.plist" ]; then
    echo -e "${GREEN}✓ Found${NC}"
    check_passed
    
    # Check for Siri usage description
    if grep -E "NSSiriUsageDescription" "MedicationManager/Info.plist" &>/dev/null; then
        echo "  - Siri usage description: ${GREEN}✓${NC}"
        check_passed
    else
        echo "  - Siri usage description: ${RED}✗${NC}"
        check_failed
    fi
else
    echo -e "${RED}✗ Not found${NC}"
    check_failed
fi

echo ""
echo "5. Checking Core Managers"
echo "========================"

# Check for required managers
managers=(
    "FirebaseManager.swift"
    "CoreDataManager.swift"
    "KeychainManager.swift"
    "AnalyticsManager.swift"
    "DataSyncManager.swift"
    "ConflictDetectionManager.swift"
    "VoiceInteractionManager.swift"
    "SiriIntentsManager.swift"
)

for manager in "${managers[@]}"; do
    echo -n "$manager: "
    if find . -name "$manager" -not -path "./DerivedData/*" | grep -q .; then
        echo -e "${GREEN}✓${NC}"
        check_passed
    else
        echo -e "${RED}✗${NC}"
        check_failed
    fi
done

echo ""
echo "======================================"
echo "VALIDATION SUMMARY"
echo "======================================"
echo -e "Total checks performed: $TOTAL_CHECKS"
echo -e "${GREEN}Passed checks: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed checks: $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
echo ""

# Report issues
if [ ${#SYNTAX_ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}Files with syntax errors:${NC}"
    for file in "${SYNTAX_ERRORS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

if [ ${#HARDCODED_VALUES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Files with hardcoded values:${NC}"
    for file in "${HARDCODED_VALUES[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

if [ ${#MISSING_IMPORTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Files with potential missing imports:${NC}"
    for file in "${MISSING_IMPORTS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

if [ ${#APPTHEME_VIOLATIONS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Files not using AppTheme:${NC}"
    for file in "${APPTHEME_VIOLATIONS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

if [ ${#TODO_ITEMS[@]} -gt 0 ]; then
    echo -e "${BLUE}Files with TODO/FIXME items:${NC}"
    for file in "${TODO_ITEMS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

# Generate detailed report
echo "======================================"
echo "GENERATING DETAILED REPORT"
echo "======================================"

report_file="validation-report-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "MedicationManager Project Validation Report"
    echo "Generated: $(date)"
    echo ""
    echo "Summary:"
    echo "- Total checks: $TOTAL_CHECKS"
    echo "- Passed: $PASSED_CHECKS"
    echo "- Failed: $FAILED_CHECKS"
    echo "- Warnings: $WARNING_COUNT"
    echo ""
    
    if [ ${#HARDCODED_VALUES[@]} -gt 0 ]; then
        echo "Hardcoded Values Found:"
        for file in "${HARDCODED_VALUES[@]}"; do
            echo ""
            echo "File: $file"
            # Show specific violations
            if [[ ! "$file" == *"PhoneAuthView.swift" ]] && [[ ! "$file" == *"FirebaseManager.swift" ]]; then
                grep -n -E '\"[A-Za-z ]{3,}\"' "$file" | grep -v "AppStrings\." | grep -v "#if DEBUG" | head -5
            fi
        done
    fi
    
} > "$report_file"

echo "Detailed report saved to: $report_file"
echo ""

# Overall status
if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ Project validation PASSED!${NC}"
    exit 0
elif [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Project validation passed with warnings${NC}"
    exit 0
else
    echo -e "${RED}❌ Project validation FAILED${NC}"
    exit 1
fi