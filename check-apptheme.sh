#!/bin/bash

# AppTheme Completeness and Usage Checker
# This script verifies that AppTheme is properly defined and consistently used

echo "🎨 AppTheme Completeness and Usage Check"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if AppTheme files exist
echo "1. Checking AppTheme Configuration Files"
echo "---------------------------------------"

check_file_exists() {
    local file=$1
    local name=$2
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $name found"
        return 0
    else
        echo -e "${RED}✗${NC} $name NOT FOUND"
        return 1
    fi
}

# Check core configuration files
check_file_exists "MedicationManager/Core/Configuration/AppTheme.swift" "AppTheme.swift"
APPTHEME_EXISTS=$?

check_file_exists "MedicationManager/Core/Configuration/AppStrings.swift" "AppStrings.swift"
check_file_exists "MedicationManager/Core/Configuration/AppIcons.swift" "AppIcons.swift"
check_file_exists "MedicationManager/Core/Configuration/Configuration.swift" "Configuration.swift"

echo ""

# If AppTheme exists, check its completeness
if [ $APPTHEME_EXISTS -eq 0 ]; then
    echo "2. Checking AppTheme Components"
    echo "------------------------------"
    
    APPTHEME_FILE="MedicationManager/Core/Configuration/AppTheme.swift"
    
    # Check for required components
    components=(
        "struct Colors"
        "struct Typography"
        "struct Spacing"
        "struct CornerRadius"
        "struct Animation"
        "struct Shadow"
        "struct Opacity"
    )
    
    for component in "${components[@]}"; do
        if grep -q "$component" "$APPTHEME_FILE"; then
            echo -e "${GREEN}✓${NC} $component defined"
            
            # Check specific items within each component
            case "$component" in
                "struct Colors")
                    echo "  Checking color definitions:"
                    for color in "primary" "secondary" "background" "surface" "error" "success" "warning" "onPrimary" "onBackground" "onSurface"; do
                        if grep -q "static let $color" "$APPTHEME_FILE"; then
                            echo -e "    ${GREEN}✓${NC} $color"
                        else
                            echo -e "    ${RED}✗${NC} $color missing"
                        fi
                    done
                    ;;
                "struct Typography")
                    echo "  Checking typography definitions:"
                    for type in "largeTitle" "title" "headline" "body" "callout" "subheadline" "footnote" "caption"; do
                        if grep -q "static let $type" "$APPTHEME_FILE"; then
                            echo -e "    ${GREEN}✓${NC} $type"
                        else
                            echo -e "    ${RED}✗${NC} $type missing"
                        fi
                    done
                    ;;
                "struct Spacing")
                    echo "  Checking spacing definitions:"
                    for space in "tiny" "small" "medium" "large" "extraLarge"; do
                        if grep -q "static let $space" "$APPTHEME_FILE"; then
                            echo -e "    ${GREEN}✓${NC} $space"
                        else
                            echo -e "    ${RED}✗${NC} $space missing"
                        fi
                    done
                    ;;
            esac
        else
            echo -e "${RED}✗${NC} $component NOT DEFINED"
        fi
    done
fi

echo ""
echo "3. Checking AppTheme Usage in Views"
echo "----------------------------------"

# Find all View files
view_files=$(find MedicationManager -name "*View.swift" -not -path "*/\.*" 2>/dev/null)
total_views=$(echo "$view_files" | wc -l | tr -d ' ')

echo "Found $total_views View files"
echo ""

# Check usage in each view
views_using_apptheme=0
views_with_violations=0

for file in $view_files; do
    filename=$(basename "$file")
    
    # Skip certain files
    if [[ "$filename" == "ContentView.swift" ]] || [[ "$filename" == "EmptyStateView.swift" ]]; then
        continue
    fi
    
    # Check if file uses AppTheme
    if grep -q "AppTheme\." "$file" 2>/dev/null; then
        views_using_apptheme=$((views_using_apptheme + 1))
        
        # Check for violations
        violations=0
        
        # Check for hardcoded colors
        if grep -E '\.(red|blue|green|yellow|orange|purple|pink|gray|black|white)\b' "$file" | grep -v "AppTheme\.Colors" | grep -v "Color\.clear" &>/dev/null; then
            violations=$((violations + 1))
        fi
        
        # Check for hardcoded fonts
        if grep -E '\.font\(\.system' "$file" | grep -v "AppTheme\.Typography" &>/dev/null; then
            violations=$((violations + 1))
        fi
        
        # Check for hardcoded padding
        if grep -E '\.(padding|spacing)\([0-9]+\)' "$file" | grep -v "AppTheme\.Spacing" &>/dev/null; then
            violations=$((violations + 1))
        fi
        
        if [ $violations -gt 0 ]; then
            echo -e "${YELLOW}⚠️${NC}  $filename uses AppTheme but has $violations violations"
            views_with_violations=$((views_with_violations + 1))
        fi
    else
        echo -e "${RED}✗${NC} $filename does NOT use AppTheme"
    fi
done

echo ""
echo "Summary:"
echo "- Views using AppTheme: $views_using_apptheme/$total_views"
echo "- Views with violations: $views_with_violations"

echo ""
echo "4. Checking for Hardcoded Values"
echo "--------------------------------"

# Search for common hardcoded patterns
echo "Searching for hardcoded values in all Swift files..."

# Count different types of violations
string_violations=$(grep -r '"[A-Za-z ]\{3,\}"' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppStrings\." | grep -v "#if DEBUG" | grep -v "print(" | wc -l | tr -d ' ')
color_violations=$(grep -r '\.\(red\|blue\|green\|yellow\|orange\|purple\|pink\|gray\|black\|white\)' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Colors" | wc -l | tr -d ' ')
font_violations=$(grep -r '\.font(\.system' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Typography" | wc -l | tr -d ' ')
padding_violations=$(grep -r '\.\(padding\|spacing\)([0-9]\+)' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Spacing" | wc -l | tr -d ' ')

echo "Found violations:"
echo "- Hardcoded strings: $string_violations"
echo "- Hardcoded colors: $color_violations"
echo "- Hardcoded fonts: $font_violations"
echo "- Hardcoded padding: $padding_violations"

echo ""
echo "5. AppStrings Usage Check"
echo "------------------------"

if [ -f "MedicationManager/Core/Configuration/AppStrings.swift" ]; then
    # Check AppStrings structure
    echo "Checking AppStrings structure:"
    
    sections=(
        "struct Common"
        "struct Authentication"
        "struct Medications"
        "struct Conflicts"
        "struct ErrorMessages"
        "struct Voice"
        "struct Siri"
    )
    
    for section in "${sections[@]}"; do
        if grep -q "$section" "MedicationManager/Core/Configuration/AppStrings.swift"; then
            echo -e "${GREEN}✓${NC} $section defined"
        else
            echo -e "${YELLOW}⚠️${NC} $section might be missing"
        fi
    done
fi

echo ""
echo "6. Generating Violation Report"
echo "-----------------------------"

# Generate a detailed report of files with violations
report_file="apptheme-violations-$(date +%Y%m%d-%H%M%S).txt"

{
    echo "AppTheme Violation Report"
    echo "Generated: $(date)"
    echo ""
    echo "Files with hardcoded colors:"
    grep -r '\.\(red\|blue\|green\|yellow\|orange\|purple\|pink\|gray\|black\|white\)' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Colors" | grep -v "FirebaseManager\|PhoneAuthView" | head -20
    
    echo ""
    echo "Files with hardcoded fonts:"
    grep -r '\.font(\.system' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Typography" | grep -v "FirebaseManager\|PhoneAuthView" | head -20
    
    echo ""
    echo "Files with hardcoded padding:"
    grep -r '\.\(padding\|spacing\)([0-9]\+)' --include="*.swift" MedicationManager 2>/dev/null | grep -v "AppTheme\.Spacing" | grep -v "FirebaseManager\|PhoneAuthView" | head -20
    
} > "$report_file"

echo "Detailed violation report saved to: $report_file"

echo ""
echo "========================================"
echo "RECOMMENDATIONS"
echo "========================================"

if [ $string_violations -gt 0 ]; then
    echo "1. Replace hardcoded strings with AppStrings entries"
fi

if [ $color_violations -gt 0 ]; then
    echo "2. Replace hardcoded colors with AppTheme.Colors"
fi

if [ $font_violations -gt 0 ]; then
    echo "3. Replace system fonts with AppTheme.Typography"
fi

if [ $padding_violations -gt 0 ]; then
    echo "4. Replace hardcoded padding with AppTheme.Spacing"
fi

echo ""
echo "AppTheme check completed!"