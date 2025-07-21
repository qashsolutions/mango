#!/usr/bin/env python3
import os
import re
from collections import defaultdict
import json

def find_force_unwrapping(file_path):
    """Find force unwrapping patterns in a Swift file."""
    patterns = []
    
    # Patterns to match force unwrapping
    force_unwrap_patterns = [
        (r'[a-zA-Z_]\w*!(?![\w=])', 'variable!'),
        (r'!\.[a-zA-Z_]', '!.property'),
        (r'!\[', '![index]'),
        (r'as!\s+\w+', 'as! cast'),
        (r'try!\s+', 'try!'),
        (r'\]!', ']!'),
        (r'\)!', ')!'),
    ]
    
    # Patterns to exclude (legitimate uses)
    exclude_patterns = [
        r'@IBOutlet',
        r'@State\s+\w+:',
        r'XCTAssert',
        r'fatalError',
        r'precondition',
        r'assert',
        r'//.*!',  # Comments
        r'"[^"]*![^"]*"',  # Inside strings
        r"'[^']*![^']*'",  # Inside single quotes
    ]
    
    violations = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for line_num, line in enumerate(lines, 1):
            # Skip if line contains exclude patterns
            if any(re.search(pattern, line) for pattern in exclude_patterns):
                continue
                
            # Check for force unwrapping patterns
            for pattern, pattern_type in force_unwrap_patterns:
                matches = re.finditer(pattern, line)
                for match in matches:
                    violations.append({
                        'line': line_num,
                        'type': pattern_type,
                        'code': line.strip(),
                        'match': match.group()
                    })
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        
    return violations

def analyze_project(root_dir):
    """Analyze all Swift files in the project."""
    results = defaultdict(list)
    file_count = 0
    total_violations = 0
    
    for root, dirs, files in os.walk(root_dir):
        # Skip build directories
        dirs[:] = [d for d in dirs if d not in ['.build', 'DerivedData', '.git']]
        
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                file_count += 1
                
                violations = find_force_unwrapping(file_path)
                if violations:
                    rel_path = os.path.relpath(file_path, root_dir)
                    results[rel_path] = violations
                    total_violations += len(violations)
    
    return results, file_count, total_violations

def main():
    root_dir = '/Users/cvr/Documents/Project/MedicationManager'
    print("Analyzing force unwrapping in Swift files...")
    
    results, file_count, total_violations = analyze_project(root_dir)
    
    # Sort by number of violations
    sorted_results = sorted(results.items(), key=lambda x: len(x[1]), reverse=True)
    
    print(f"\nAnalyzed {file_count} Swift files")
    print(f"Found {total_violations} force unwrapping instances in {len(results)} files")
    print(f"\nTop 20 files with most violations:\n")
    
    for i, (file_path, violations) in enumerate(sorted_results[:20]):
        print(f"{i+1}. {file_path}: {len(violations)} violations")
        
        # Group by type
        by_type = defaultdict(int)
        for v in violations:
            by_type[v['type']] += 1
        
        print(f"   Types: {dict(by_type)}")
        
        # Show first few examples
        for v in violations[:3]:
            print(f"   Line {v['line']}: {v['code'][:80]}...")
        print()
    
    # Summary by type
    print("\nSummary by violation type:")
    type_count = defaultdict(int)
    for violations in results.values():
        for v in violations:
            type_count[v['type']] += 1
    
    for vtype, count in sorted(type_count.items(), key=lambda x: x[1], reverse=True):
        print(f"  {vtype}: {count}")
    
    # Save detailed results
    with open('force-unwrapping-report.json', 'w') as f:
        json.dump({
            'summary': {
                'files_analyzed': file_count,
                'files_with_violations': len(results),
                'total_violations': total_violations,
                'violations_by_type': dict(type_count)
            },
            'files': dict(sorted_results)
        }, f, indent=2)
    
    print("\nDetailed report saved to force-unwrapping-report.json")

if __name__ == '__main__':
    main()