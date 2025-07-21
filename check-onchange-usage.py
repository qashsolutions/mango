#!/usr/bin/env python3
"""Check for deprecated .onChange usage in Swift files."""

import os
import re
from pathlib import Path

def check_onchange_usage(file_path):
    """Check if a file uses deprecated onChange pattern."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    deprecated_pattern = re.compile(r'\.onChange\s*\(\s*of:\s*[^)]+\)\s*\{\s*(?:newValue|value|_)\s*in')
    modern_pattern = re.compile(r'\.onChange\s*\(\s*of:\s*[^)]+\)\s*\{\s*(?:oldValue|_)\s*,\s*(?:newValue|_)\s*in')
    
    results = []
    
    for i, line in enumerate(lines, 1):
        if '.onChange' in line:
            # Check if it's the modern pattern (with two parameters)
            if modern_pattern.search(line):
                results.append((i, line.strip(), 'modern'))
            # Check if it's the deprecated pattern (single parameter)
            elif deprecated_pattern.search(line):
                results.append((i, line.strip(), 'deprecated'))
            # If it contains onChange but doesn't match either pattern, flag for manual review
            elif '.onChange' in line:
                # Look ahead to see the closure pattern
                closure_start = i
                closure_content = []
                for j in range(i, min(i+5, len(lines))):
                    closure_content.append(lines[j-1])
                
                full_text = '\n'.join(closure_content)
                if modern_pattern.search(full_text):
                    results.append((i, line.strip(), 'modern'))
                elif deprecated_pattern.search(full_text):
                    results.append((i, line.strip(), 'deprecated'))
                else:
                    results.append((i, line.strip(), 'unknown'))
    
    return results

def main():
    project_root = Path('/Users/cvr/Documents/Project/MedicationManager')
    swift_files = list(project_root.rglob('*.swift'))
    
    deprecated_files = []
    modern_files = []
    unknown_files = []
    
    for swift_file in swift_files:
        if '.build' in str(swift_file) or 'DerivedData' in str(swift_file):
            continue
            
        results = check_onchange_usage(swift_file)
        if results:
            has_deprecated = any(r[2] == 'deprecated' for r in results)
            has_unknown = any(r[2] == 'unknown' for r in results)
            
            if has_deprecated:
                deprecated_files.append((swift_file, results))
            elif has_unknown:
                unknown_files.append((swift_file, results))
            else:
                modern_files.append((swift_file, results))
    
    # Print results
    print(f"Total Swift files scanned: {len(swift_files)}")
    print(f"Files with .onChange: {len(deprecated_files) + len(modern_files) + len(unknown_files)}")
    print()
    
    if deprecated_files:
        print("❌ FILES USING DEPRECATED .onChange PATTERN (single parameter):")
        print("=" * 80)
        for file_path, results in deprecated_files:
            print(f"\n{file_path.relative_to(project_root)}:")
            for line_num, line, pattern_type in results:
                if pattern_type == 'deprecated':
                    print(f"  Line {line_num}: {line}")
    else:
        print("✅ No files found using deprecated .onChange pattern!")
    
    print()
    
    if unknown_files:
        print("⚠️  FILES WITH UNKNOWN .onChange PATTERN (manual review needed):")
        print("=" * 80)
        for file_path, results in unknown_files:
            print(f"\n{file_path.relative_to(project_root)}:")
            for line_num, line, pattern_type in results:
                if pattern_type == 'unknown':
                    print(f"  Line {line_num}: {line}")
    
    print()
    
    if modern_files:
        print("✅ FILES USING MODERN .onChange PATTERN (two parameters):")
        print("=" * 80)
        for file_path, results in modern_files:
            print(f"\n{file_path.relative_to(project_root)}:")
            for line_num, line, pattern_type in results:
                print(f"  Line {line_num}: {line}")

if __name__ == '__main__':
    main()