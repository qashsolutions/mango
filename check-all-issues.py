#!/usr/bin/env python3
import os
import re
import json
from pathlib import Path
from collections import defaultdict

def analyze_swift_files():
    root_path = Path("/Users/cvr/Documents/Project/MedicationManager")
    issues = defaultdict(list)
    
    # Get all Swift files
    swift_files = list(root_path.rglob("*.swift"))
    
    for file_path in swift_files:
        if "MedicationManager" in str(file_path) and not any(skip in str(file_path) for skip in ["Test", "Preview", ".build"]):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    lines = content.split('\n')
                
                relative_path = str(file_path.relative_to(root_path))
                
                # 1. Force Unwrapping - More precise check
                for i, line in enumerate(lines, 1):
                    # Skip comments
                    if '//' in line:
                        line = line[:line.index('//')]
                    
                    # Check for force unwrap patterns
                    if re.search(r'[a-zA-Z0-9_\]\)]\s*!\s*[^\s!=]', line):
                        if not any(exclude in line for exclude in ['!=', '!!', 'try!', 'as!']):
                            issues["force_unwrapping"].append({
                                "file": relative_path,
                                "line": i,
                                "code": line.strip(),
                                "severity": "High"
                            })
                    
                    # Check for force cast
                    if re.search(r'as!\s+\w+', line):
                        issues["force_cast"].append({
                            "file": relative_path,
                            "line": i,
                            "code": line.strip(),
                            "severity": "High"
                        })
                    
                    # Check for try!
                    if re.search(r'try!\s+', line):
                        issues["force_try"].append({
                            "file": relative_path,
                            "line": i,
                            "code": line.strip(),
                            "severity": "High"
                        })
                
                # 2. Hardcoded Strings (excluding config files)
                if not any(config in relative_path for config in ["AppStrings", "Configuration", "AppTheme", "CommonStrings"]):
                    for i, line in enumerate(lines, 1):
                        # Skip imports and certain patterns
                        if line.strip().startswith(('import ', '@', 'case ', '#if', '#else', '#endif')):
                            continue
                        
                        # Find quoted strings
                        strings = re.findall(r'"([^"]+)"', line)
                        for string in strings:
                            # Check if it's a user-facing string
                            if (len(string) > 3 and 
                                (' ' in string or string.endswith((':',  '?', '!', '.'))) and
                                not re.match(r'^[a-zA-Z0-9_\-\.]+$', string) and
                                not string.startswith(('http', 'com.', '+1'))):
                                
                                issues["hardcoded_string"].append({
                                    "file": relative_path,
                                    "line": i,
                                    "string": string,
                                    "code": line.strip(),
                                    "severity": "Medium"
                                })
                
                # 3. UIApplication without UIKit import
                if 'UIApplication' in content and 'import UIKit' not in content:
                    issues["missing_import"].append({
                        "file": relative_path,
                        "line": 0,
                        "missing": "import UIKit",
                        "severity": "High"
                    })
                
                # 4. Navigation pattern check for DetailViews
                if 'DetailView' in relative_path:
                    # Check for object-based navigation
                    object_match = re.search(r'let\s+\w+:\s*(Medication|Doctor|Supplement|MedicationConflict)(?!\w)', content)
                    id_match = re.search(r'let\s+\w+Id:\s*String', content)
                    
                    if object_match and not id_match:
                        for i, line in enumerate(lines, 1):
                            if object_match.group() in line:
                                issues["navigation_pattern"].append({
                                    "file": relative_path,
                                    "line": i,
                                    "issue": "Detail view uses object-based navigation instead of ID-based",
                                    "severity": "High"
                                })
                                break
                
                # 5. Hardcoded colors/fonts/spacing
                for i, line in enumerate(lines, 1):
                    # Hardcoded colors
                    if re.search(r'Color\((red:|green:|blue:|"#|\.\w+)', line) and 'AppTheme' not in relative_path:
                        issues["hardcoded_style"].append({
                            "file": relative_path,
                            "line": i,
                            "type": "color",
                            "code": line.strip(),
                            "severity": "Medium"
                        })
                    
                    # Hardcoded fonts
                    if re.search(r'\.font\(.system\(size:\s*\d+', line) and 'AppTheme' not in relative_path:
                        issues["hardcoded_style"].append({
                            "file": relative_path,
                            "line": i,
                            "type": "font",
                            "code": line.strip(),
                            "severity": "Medium"
                        })
                    
                    # Hardcoded spacing
                    if re.search(r'\.(padding|spacing)\(\d+\.?\d*\)', line) and 'AppTheme' not in relative_path:
                        issues["hardcoded_style"].append({
                            "file": relative_path,
                            "line": i,
                            "type": "spacing",
                            "code": line.strip(),
                            "severity": "Low"
                        })
                
            except Exception as e:
                issues["file_errors"].append({
                    "file": relative_path,
                    "error": str(e),
                    "severity": "Critical"
                })
    
    return issues

def generate_markdown_report(issues):
    report = []
    report.append("# MedicationManager Comprehensive Code Analysis Report\n")
    report.append(f"Generated on: {Path().cwd()}\n")
    
    # Summary
    total_issues = sum(len(issue_list) for issue_list in issues.values())
    report.append("## Summary\n")
    report.append(f"- **Total Issues Found**: {total_issues}\n")
    report.append(f"- **Categories**: {len(issues)}\n")
    
    # Count by severity
    severity_counts = defaultdict(int)
    for issue_list in issues.values():
        for issue in issue_list:
            severity_counts[issue.get('severity', 'Unknown')] += 1
    
    report.append("\n### Issues by Severity\n")
    for severity in ['Critical', 'High', 'Medium', 'Low']:
        count = severity_counts.get(severity, 0)
        report.append(f"- **{severity}**: {count}\n")
    
    # Detailed issues by category
    report.append("\n## Detailed Issues\n")
    
    # Sort categories by severity
    category_order = [
        ("force_unwrapping", "Force Unwrapping Issues"),
        ("force_cast", "Force Cast Issues"),
        ("force_try", "Force Try Issues"),
        ("missing_import", "Missing Imports"),
        ("navigation_pattern", "Navigation Pattern Issues"),
        ("hardcoded_string", "Hardcoded Strings"),
        ("hardcoded_style", "Hardcoded Styles"),
        ("file_errors", "File Processing Errors")
    ]
    
    for category_key, category_name in category_order:
        if category_key in issues and issues[category_key]:
            report.append(f"\n### {category_name}\n")
            report.append(f"**Count**: {len(issues[category_key])}\n\n")
            
            # Group by file
            by_file = defaultdict(list)
            for issue in issues[category_key]:
                by_file[issue['file']].append(issue)
            
            for file_path, file_issues in sorted(by_file.items()):
                report.append(f"#### {file_path}\n")
                for issue in file_issues:
                    if 'line' in issue and issue['line'] > 0:
                        report.append(f"- Line {issue['line']}: ")
                    else:
                        report.append("- ")
                    
                    if 'code' in issue:
                        report.append(f"`{issue['code']}`")
                    elif 'string' in issue:
                        report.append(f'String: "{issue["string"]}"')
                    elif 'missing' in issue:
                        report.append(f"Missing: {issue['missing']}")
                    elif 'issue' in issue:
                        report.append(issue['issue'])
                    elif 'error' in issue:
                        report.append(f"Error: {issue['error']}")
                    
                    report.append(f" [**{issue.get('severity', 'Unknown')}**]\n")
                report.append("\n")
    
    # Recommendations
    report.append("\n## Recommendations\n")
    report.append("1. **Critical**: Address all force unwrapping issues immediately\n")
    report.append("2. **High Priority**: Fix missing imports and navigation pattern inconsistencies\n")
    report.append("3. **Medium Priority**: Replace hardcoded strings with AppStrings constants\n")
    report.append("4. **Low Priority**: Replace hardcoded styles with AppTheme constants\n")
    
    return ''.join(report)

def main():
    print("Analyzing Swift files...")
    issues = analyze_swift_files()
    
    # Generate reports
    with open("comprehensive-issues-report.json", "w") as f:
        json.dump(issues, f, indent=2)
    
    markdown_report = generate_markdown_report(issues)
    with open("comprehensive-issues-report.md", "w") as f:
        f.write(markdown_report)
    
    print(f"\nAnalysis complete!")
    print(f"Total issues found: {sum(len(v) for v in issues.values())}")
    print("\nReports generated:")
    print("- comprehensive-issues-report.json")
    print("- comprehensive-issues-report.md")

if __name__ == "__main__":
    main()