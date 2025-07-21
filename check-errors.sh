#!/bin/bash

# Comprehensive Error Checker for MedicationManager
# Checks for syntax errors, crashes, and other issues

echo "🔍 MedicationManager Comprehensive Error Check"
echo "============================================="
echo "Started at: $(date)"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Arrays to track different types of errors
declare -a SYNTAX_ERRORS
declare -a FORCE_UNWRAP_ERRORS
declare -a IMPLICITLY_UNWRAPPED_OPTIONALS
declare -a FATAL_ERRORS
declare -a MEMORY_LEAKS
declare -a DEPRECATED_APIS
declare -a MISSING_ERROR_HANDLING

error_count=0
warning_count=0

echo "1. Checking Swift Syntax Errors"
echo "------------------------------"

# Find all Swift files (excluding protected files)
swift_files=$(find MedicationManager -name "*.swift" -not -path "*/\.*" 2>/dev/null | grep -v "FirebaseManager.swift" | grep -v "PhoneAuthView.swift")

for file in $swift_files; do
    # Check basic syntax with swiftc
    if ! swiftc -parse -suppress-warnings "$file" &>/dev/null; then
        SYNTAX_ERRORS+=("$file")
        echo -e "${RED}✗${NC} $(basename "$file") - Syntax error"
        error_count=$((error_count + 1))
    fi
done

if [ ${#SYNTAX_ERRORS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No syntax errors found"
fi

echo ""
echo "2. Checking for Force Unwrapping (!)"
echo "-----------------------------------"

for file in $swift_files; do
    # Count force unwraps (excluding IBOutlets and legitimate uses)
    force_unwraps=$(grep -n '![^=!]' "$file" | grep -v "IBOutlet" | grep -v "fatalError" | grep -v "precondition" | grep -v "assert" | wc -l | tr -d ' ')
    
    if [ $force_unwraps -gt 0 ]; then
        FORCE_UNWRAP_ERRORS+=("$file:$force_unwraps")
        echo -e "${YELLOW}⚠️${NC} $(basename "$file") - $force_unwraps force unwrap(s)"
        warning_count=$((warning_count + $force_unwraps))
    fi
done

if [ ${#FORCE_UNWRAP_ERRORS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No force unwrapping found"
fi

echo ""
echo "3. Checking for Implicitly Unwrapped Optionals (!)"
echo "-------------------------------------------------"

for file in $swift_files; do
    # Check for implicitly unwrapped optionals (Type!)
    impl_unwrapped=$(grep -c ': [A-Za-z]*!' "$file" | tr -d ' ')
    
    if [ $impl_unwrapped -gt 0 ]; then
        IMPLICITLY_UNWRAPPED_OPTIONALS+=("$file:$impl_unwrapped")
        echo -e "${YELLOW}⚠️${NC} $(basename "$file") - $impl_unwrapped implicitly unwrapped optional(s)"
        warning_count=$((warning_count + $impl_unwrapped))
    fi
done

if [ ${#IMPLICITLY_UNWRAPPED_OPTIONALS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No implicitly unwrapped optionals found"
fi

echo ""
echo "4. Checking for Fatal Errors and Crashes"
echo "---------------------------------------"

for file in $swift_files; do
    # Check for fatalError calls
    fatal_errors=$(grep -c "fatalError(" "$file" | tr -d ' ')
    
    if [ $fatal_errors -gt 0 ]; then
        FATAL_ERRORS+=("$file:$fatal_errors")
        echo -e "${RED}✗${NC} $(basename "$file") - $fatal_errors fatalError call(s)"
        error_count=$((error_count + $fatal_errors))
    fi
done

if [ ${#FATAL_ERRORS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No fatalError calls found"
fi

echo ""
echo "5. Checking for Memory Issues"
echo "----------------------------"

for file in $swift_files; do
    # Check for potential retain cycles (closures without weak self)
    if grep -q "{ *[^[].*self\." "$file"; then
        # Check if it's properly handled with [weak self] or [unowned self]
        retain_cycles=$(grep -B1 "self\." "$file" | grep -c "{ *$" | tr -d ' ')
        weak_refs=$(grep -c "\[weak self\]" "$file" | tr -d ' ')
        unowned_refs=$(grep -c "\[unowned self\]" "$file" | tr -d ' ')
        
        potential_cycles=$((retain_cycles - weak_refs - unowned_refs))
        if [ $potential_cycles -gt 0 ]; then
            MEMORY_LEAKS+=("$file:$potential_cycles")
            echo -e "${YELLOW}⚠️${NC} $(basename "$file") - $potential_cycles potential retain cycle(s)"
            warning_count=$((warning_count + $potential_cycles))
        fi
    fi
done

if [ ${#MEMORY_LEAKS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No obvious memory leaks found"
fi

echo ""
echo "6. Checking for Deprecated APIs"
echo "------------------------------"

deprecated_patterns=(
    "UIAlertView"
    "UIActionSheet"
    "UIWebView"
    "NSURLConnection"
    ".appearance()"
    "DispatchQueue.global().async"
)

for file in $swift_files; do
    for pattern in "${deprecated_patterns[@]}"; do
        if grep -q "$pattern" "$file"; then
            DEPRECATED_APIS+=("$file:$pattern")
            echo -e "${YELLOW}⚠️${NC} $(basename "$file") - Uses deprecated API: $pattern"
            warning_count=$((warning_count + 1))
        fi
    done
done

if [ ${#DEPRECATED_APIS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No deprecated APIs found"
fi

echo ""
echo "7. Checking Error Handling"
echo "-------------------------"

for file in $swift_files; do
    # Check for functions that throw but aren't handled
    throwing_funcs=$(grep -c "throws\s*->" "$file" | tr -d ' ')
    try_statements=$(grep -c "try\s" "$file" | tr -d ' ')
    
    # Check for unhandled errors (rough estimate)
    if [ $throwing_funcs -gt 0 ] && [ $try_statements -eq 0 ]; then
        MISSING_ERROR_HANDLING+=("$file")
        echo -e "${YELLOW}⚠️${NC} $(basename "$file") - Has throwing functions but no error handling"
        warning_count=$((warning_count + 1))
    fi
done

if [ ${#MISSING_ERROR_HANDLING[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Error handling appears adequate"
fi

echo ""
echo "8. Checking Async/Await Issues"
echo "-----------------------------"

for file in $swift_files; do
    # Check for missing await
    if grep -q "async\s" "$file"; then
        async_calls=$(grep -c "async\s" "$file" | tr -d ' ')
        await_calls=$(grep -c "await\s" "$file" | tr -d ' ')
        
        if [ $async_calls -gt $await_calls ]; then
            echo -e "${YELLOW}⚠️${NC} $(basename "$file") - Possible missing await statements"
            warning_count=$((warning_count + 1))
        fi
    fi
done

echo ""
echo "9. Checking Model Conformance"
echo "----------------------------"

# Check if models conform to required protocols
model_files=$(find MedicationManager -name "*Model*.swift" -not -path "*/\.*" 2>/dev/null)

for file in $model_files; do
    filename=$(basename "$file")
    
    # Check for Codable conformance
    if ! grep -q ": Codable" "$file" && ! grep -q ", Codable" "$file"; then
        echo -e "${YELLOW}⚠️${NC} $filename - Model might need Codable conformance"
        warning_count=$((warning_count + 1))
    fi
    
    # Check for Sendable conformance (Swift 6)
    if ! grep -q ": Sendable" "$file" && ! grep -q ", Sendable" "$file"; then
        echo -e "${BLUE}ℹ️${NC} $filename - Consider Sendable conformance for Swift 6"
    fi
done

echo ""
echo "10. Checking View Model Issues"
echo "-----------------------------"

# Check ViewModels for @MainActor
viewmodel_files=$(find MedicationManager -name "*ViewModel.swift" -not -path "*/\.*" 2>/dev/null)

for file in $viewmodel_files; do
    filename=$(basename "$file")
    
    # Check for @MainActor
    if ! grep -q "@MainActor" "$file"; then
        echo -e "${YELLOW}⚠️${NC} $filename - ViewModel should be marked with @MainActor"
        warning_count=$((warning_count + 1))
    fi
    
    # Check for @Published properties
    if ! grep -q "@Published" "$file"; then
        echo -e "${BLUE}ℹ️${NC} $filename - No @Published properties found"
    fi
done

echo ""
echo "============================================="
echo "ERROR CHECK SUMMARY"
echo "============================================="
echo -e "${RED}Errors found: $error_count${NC}"
echo -e "${YELLOW}Warnings found: $warning_count${NC}"
echo ""

# Detailed report
if [ ${#SYNTAX_ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}Files with syntax errors:${NC}"
    for file in "${SYNTAX_ERRORS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

if [ ${#FORCE_UNWRAP_ERRORS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Files with force unwrapping:${NC}"
    printf '%s\n' "${FORCE_UNWRAP_ERRORS[@]}" | sort -t: -k2 -nr | head -10
    echo ""
fi

if [ ${#FATAL_ERRORS[@]} -gt 0 ]; then
    echo -e "${RED}Files with fatalError calls:${NC}"
    for file in "${FATAL_ERRORS[@]}"; do
        echo "  - $file"
    done
    echo ""
fi

# Generate detailed error report
report_file="error-report-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "MedicationManager Error Report"
    echo "Generated: $(date)"
    echo ""
    echo "Summary:"
    echo "- Errors: $error_count"
    echo "- Warnings: $warning_count"
    echo ""
    
    if [ ${#SYNTAX_ERRORS[@]} -gt 0 ]; then
        echo "Syntax Errors:"
        for file in "${SYNTAX_ERRORS[@]}"; do
            echo "  $file"
            # Try to get specific error
            swiftc -parse "$file" 2>&1 | head -5
            echo ""
        done
    fi
    
    if [ ${#FORCE_UNWRAP_ERRORS[@]} -gt 0 ]; then
        echo "Force Unwrapping Locations:"
        for entry in "${FORCE_UNWRAP_ERRORS[@]}"; do
            file=$(echo "$entry" | cut -d: -f1)
            echo ""
            echo "File: $file"
            grep -n '![^=!]' "$file" | grep -v "IBOutlet" | head -5
        done
    fi
} > "$report_file"

echo "Detailed error report saved to: $report_file"
echo ""

# Overall assessment
if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
    echo -e "${GREEN}✅ No errors or warnings found! Code is clean.${NC}"
elif [ $error_count -eq 0 ]; then
    echo -e "${YELLOW}⚠️ No critical errors, but $warning_count warning(s) should be addressed.${NC}"
else
    echo -e "${RED}❌ Found $error_count critical error(s) that need immediate attention!${NC}"
fi

echo ""
echo "Recommendations:"
echo "1. Fix all syntax errors first"
echo "2. Replace force unwrapping with safe unwrapping (if let, guard let)"
echo "3. Add proper error handling for throwing functions"
echo "4. Use [weak self] in closures to prevent retain cycles"
echo "5. Mark ViewModels with @MainActor for thread safety"