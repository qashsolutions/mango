#!/bin/bash

# Find force unwrapping in Swift files
echo "Searching for force unwrapping patterns in Swift files..."
echo "=================================================="

# Count total Swift files
total_files=$(find . -name "*.swift" -type f | grep -v ".build" | grep -v "DerivedData" | wc -l)
echo "Total Swift files: $total_files"
echo ""

# Search for different force unwrapping patterns
echo "Force unwrapping patterns found:"
echo "--------------------------------"

# Pattern 1: Variable!
echo "1. Variable! pattern:"
grep -r "![^=!]" --include="*.swift" . 2>/dev/null | grep -v "//" | grep -v ".build" | grep -v "DerivedData" | head -10

echo ""
echo "2. !.property pattern:"
grep -r "!\." --include="*.swift" . 2>/dev/null | grep -v "//" | head -10

echo ""
echo "3. as! cast pattern:"
grep -r "as! " --include="*.swift" . 2>/dev/null | grep -v "//" | head -10

echo ""
echo "4. try! pattern:"
grep -r "try! " --include="*.swift" . 2>/dev/null | grep -v "//" | head -10

echo ""
echo "5. ]! pattern:"
grep -r "\]!" --include="*.swift" . 2>/dev/null | grep -v "//" | head -10

echo ""
echo "6. )! pattern:"
grep -r ")!" --include="*.swift" . 2>/dev/null | grep -v "//" | head -10

echo ""
echo "Summary of files with force unwrapping:"
echo "--------------------------------------"
grep -r "![^=!]" --include="*.swift" . 2>/dev/null | grep -v "//" | cut -d: -f1 | sort | uniq -c | sort -nr | head -20