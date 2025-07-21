#!/usr/bin/env python3
"""
Check for force unwrapping issues in Swift files
"""

import os
import re
from pathlib import Path

def find_force_unwraps(file_path):
    """Find force unwrap patterns in a Swift file"""
    issues = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for line_num, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith('//') or line.strip().startswith('///'):
            continue
            
        # Check for force unwrap patterns
        # Look for ! that's not part of != or !!
        if re.search(r'(?<![!=])!(?![=!])', line):
            # Check if it's an implicitly unwrapped optional declaration
            if re.search(r':\s*\w+!', line):
                issues.append({
                    'line': line_num,
                    'type': 'implicitly_unwrapped_optional',
                    'content': line.strip()
                })
            # Check for force unwrap usage
            elif re.search(r'\w+![\.\[\(]|!$', line):
                issues.append({
                    'line': line_num,
                    'type': 'force_unwrap',
                    'content': line.strip()
                })
        
        # Check for force cast (as!)
        if ' as! ' in line:
            issues.append({
                'line': line_num,
                'type': 'force_cast',
                'content': line.strip()
            })
            
        # Check for force try (try!)
        if 'try!' in line:
            issues.append({
                'line': line_num,
                'type': 'force_try',
                'content': line.strip()
            })
    
    return issues

def scan_project(root_dir):
    """Scan all Swift files in the project"""
    all_issues = {}
    
    for root, dirs, files in os.walk(root_dir):
        # Skip certain directories
        if any(skip in root for skip in ['.build', 'DerivedData', '.git', 'Pods']):
            continue
            
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                issues = find_force_unwraps(file_path)
                if issues:
                    all_issues[file_path] = issues
    
    return all_issues

def main():
    # Get the MedicationManager directory
    project_dir = "/Users/cvr/Documents/Project/MedicationManager/MedicationManager"
    
    print("Scanning for force unwrapping issues...")
    issues = scan_project(project_dir)
    
    # Group by type
    force_unwrap_count = 0
    implicitly_unwrapped_count = 0
    force_cast_count = 0
    force_try_count = 0
    
    print("\n" + "="*80)
    print("FORCE UNWRAPPING ISSUES REPORT")
    print("="*80)
    
    # Files we already fixed
    fixed_files = {
        "DoctorListViewModel.swift": [344, 345],
        "MedicationCard.swift": [271],
        "SyncTestRunner.swift": [212]
    }
    
    for file_path, file_issues in sorted(issues.items()):
        file_name = os.path.basename(file_path)
        print(f"\n{file_path}")
        print("-" * len(file_path))
        
        for issue in file_issues:
            # Check if this issue was already fixed
            is_fixed = False
            if file_name in fixed_files:
                if issue['line'] in fixed_files[file_name]:
                    is_fixed = True
            
            status = " [FIXED]" if is_fixed else ""
            print(f"  Line {issue['line']}: {issue['type']}{status}")
            print(f"    {issue['content']}")
            
            if not is_fixed:
                if issue['type'] == 'force_unwrap':
                    force_unwrap_count += 1
                elif issue['type'] == 'implicitly_unwrapped_optional':
                    implicitly_unwrapped_count += 1
                elif issue['type'] == 'force_cast':
                    force_cast_count += 1
                elif issue['type'] == 'force_try':
                    force_try_count += 1
    
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    print(f"Force unwraps (!): {force_unwrap_count}")
    print(f"Implicitly unwrapped optionals (Type!): {implicitly_unwrapped_count}")
    print(f"Force casts (as!): {force_cast_count}")
    print(f"Force try (try!): {force_try_count}")
    print(f"Total issues: {force_unwrap_count + implicitly_unwrapped_count + force_cast_count + force_try_count}")
    
    # Critical files to check
    print("\n" + "="*80)
    print("CRITICAL FILES STATUS")
    print("="*80)
    
    critical_files = [
        "CoreDataManager.swift",
        "FirebaseManager.swift",
        "PhoneAuthView.swift"
    ]
    
    for critical in critical_files:
        found = False
        for file_path in issues.keys():
            if critical in file_path:
                found = True
                break
        
        if found:
            print(f"✗ {critical} - HAS FORCE UNWRAP ISSUES")
        else:
            print(f"✓ {critical} - No force unwrap issues found")

if __name__ == "__main__":
    main()