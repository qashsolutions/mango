#!/usr/bin/env python3
import os
import re
import json
from pathlib import Path
from collections import defaultdict

class SwiftAnalyzer:
    def __init__(self, root_path):
        self.root_path = Path(root_path)
        self.issues = defaultdict(list)
        
    def analyze_all_files(self):
        """Analyze all Swift files in the project"""
        swift_files = list(self.root_path.rglob("*.swift"))
        print(f"Found {len(swift_files)} Swift files to analyze")
        
        for file_path in swift_files:
            if "MedicationManager" in str(file_path):
                self.analyze_file(file_path)
                
        return self.issues
    
    def analyze_file(self, file_path):
        """Analyze a single Swift file for various issues"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            relative_path = str(file_path.relative_to(self.root_path))
            
            # Skip test files for certain checks
            is_test_file = 'Test' in str(file_path) or 'Mock' in str(file_path)
            
            # 1. Force Unwrapping
            self.check_force_unwrapping(content, lines, relative_path)
            
            # 2. Hardcoded Values
            if not is_test_file:
                self.check_hardcoded_values(content, lines, relative_path)
            
            # 3. Method Calls
            self.check_method_calls(content, lines, relative_path)
            
            # 4. Navigation Patterns
            self.check_navigation_patterns(content, lines, relative_path)
            
            # 5. Missing Imports
            self.check_missing_imports(content, lines, relative_path)
            
            # 6. Deprecated APIs
            self.check_deprecated_apis(content, lines, relative_path)
            
            # 7. Empty Files
            self.check_empty_files(content, relative_path)
            
            # 8. Type Mismatches
            self.check_type_issues(content, lines, relative_path)
            
        except Exception as e:
            self.issues["file_errors"].append({
                "file": relative_path,
                "error": str(e),
                "severity": "Critical"
            })
    
    def check_force_unwrapping(self, content, lines, file_path):
        """Check for force unwrapping (!), excluding legitimate uses"""
        for i, line in enumerate(lines, 1):
            # Skip comments and strings
            if '//' in line:
                line = line[:line.index('//')]
            
            # Common patterns for force unwrap
            patterns = [
                r'[^!]![^=!]',  # Force unwrap (exclude != and !!)
                r'as!\s+\w+',   # Force cast
                r'try!\s+',     # Force try
            ]
            
            for pattern in patterns:
                matches = re.finditer(pattern, line)
                for match in matches:
                    # Filter out legitimate uses
                    context = line[max(0, match.start()-10):match.end()+10]
                    
                    # Skip if it's part of != or !!
                    if '!=' in context or '!!' in context:
                        continue
                        
                    # Skip if it's in a string
                    if '"' in line:
                        in_string = False
                        for j, char in enumerate(line):
                            if char == '"' and (j == 0 or line[j-1] != '\\'):
                                in_string = not in_string
                            if j == match.start() and in_string:
                                break
                        else:
                            if not in_string:
                                self.add_issue("force_unwrapping", file_path, i, 
                                             f"Force unwrapping found: {line.strip()}", "High")
                    else:
                        self.add_issue("force_unwrapping", file_path, i, 
                                     f"Force unwrapping found: {line.strip()}", "High")
    
    def check_hardcoded_values(self, content, lines, file_path):
        """Check for hardcoded strings, numbers, colors"""
        for i, line in enumerate(lines, 1):
            # Skip comments
            if '//' in line:
                comment_start = line.index('//')
                line_to_check = line[:comment_start]
            else:
                line_to_check = line
                
            # Skip imports and certain declarations
            if line_to_check.strip().startswith(('import ', '@', 'case ', 'enum ', '#if')):
                continue
                
            # Check for hardcoded strings (exclude certain patterns)
            string_pattern = r'"([^"]+)"'
            strings = re.findall(string_pattern, line_to_check)
            for string in strings:
                # Allow certain strings
                allowed_patterns = [
                    r'^[a-zA-Z0-9_]+$',  # Simple identifiers
                    r'^\s*$',  # Empty/whitespace
                    r'^com\.',  # Bundle identifiers
                    r'^https?://',  # URLs
                    r'^\+\d+$',  # Phone numbers in DEBUG
                    r'^\d{6}$',  # Verification codes in DEBUG
                ]
                
                if not any(re.match(pattern, string) for pattern in allowed_patterns):
                    # Check if it's likely a user-facing string
                    if (len(string) > 3 and ' ' in string) or string.endswith(':') or string.endswith('?'):
                        # Check if it's in a configuration file
                        if 'AppStrings' not in file_path and 'Configuration' not in file_path:
                            self.add_issue("hardcoded_string", file_path, i,
                                         f'Hardcoded string: "{string}"', "Medium")
            
            # Check for hardcoded colors
            color_pattern = r'Color\((red:|green:|blue:|"#|\.)'
            if re.search(color_pattern, line_to_check):
                if 'AppTheme' not in file_path:
                    self.add_issue("hardcoded_color", file_path, i,
                                 f"Hardcoded color: {line_to_check.strip()}", "Medium")
            
            # Check for hardcoded font sizes
            font_pattern = r'\.font\(.system\(size:\s*\d+'
            if re.search(font_pattern, line_to_check):
                if 'AppTheme' not in file_path:
                    self.add_issue("hardcoded_font", file_path, i,
                                 f"Hardcoded font size: {line_to_check.strip()}", "Medium")
            
            # Check for hardcoded padding/spacing
            spacing_pattern = r'\.(padding|spacing)\([\d\.]+\)'
            if re.search(spacing_pattern, line_to_check):
                if 'AppTheme' not in file_path:
                    self.add_issue("hardcoded_spacing", file_path, i,
                                 f"Hardcoded spacing: {line_to_check.strip()}", "Low")
    
    def check_method_calls(self, content, lines, file_path):
        """Check for potentially incorrect method calls"""
        # Check for specific known issues
        method_patterns = [
            (r'updateMedication\([^)]*\)', "Check updateMedication parameters"),
            (r'deleteMedication\([^)]*\)', "Check deleteMedication parameters"),
            (r'\.navigationDestination\(for:\s*\w+\.self\)', "Check navigation destination binding"),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, message in method_patterns:
                if re.search(pattern, line):
                    self.add_issue("method_call", file_path, i,
                                 f"{message}: {line.strip()}", "Medium")
    
    def check_navigation_patterns(self, content, lines, file_path):
        """Check for navigation pattern consistency"""
        # Check if file is a detail view
        if 'DetailView' in file_path:
            # Look for ID-based vs object-based parameters
            id_pattern = r'let\s+\w+Id:\s*String'
            object_pattern = r'let\s+\w+:\s*(Medication|Doctor|Supplement|MedicationConflict)(?!\w)'
            
            has_id = bool(re.search(id_pattern, content))
            has_object = bool(re.search(object_pattern, content))
            
            if has_object and not has_id:
                for i, line in enumerate(lines, 1):
                    if re.search(object_pattern, line):
                        self.add_issue("navigation_pattern", file_path, i,
                                     "Detail view uses object-based navigation instead of ID-based", "High")
    
    def check_missing_imports(self, content, lines, file_path):
        """Check for missing imports based on usage"""
        # Check for UIKit usage without import
        if 'UIApplication' in content and 'import UIKit' not in content:
            self.add_issue("missing_import", file_path, 0,
                         "Uses UIApplication but missing 'import UIKit'", "High")
        
        # Check for Combine usage without import
        if any(term in content for term in ['@Published', 'PassthroughSubject', 'CurrentValueSubject']):
            if 'import Combine' not in content:
                self.add_issue("missing_import", file_path, 0,
                             "Uses Combine features but missing 'import Combine'", "High")
    
    def check_deprecated_apis(self, content, lines, file_path):
        """Check for deprecated APIs"""
        deprecated_patterns = [
            (r'NavigationView\s*{', "NavigationView is deprecated, use NavigationStack"),
            (r'\.alert\(isPresented:[^}]+\)\s*{[^}]+Text\(', "Old alert API, use modern .alert with actions"),
            (r'\.sheet\(isPresented:[^}]+\)\s*{[^}]+\(\)', "Check sheet usage for modern patterns"),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, message in deprecated_patterns:
                if re.search(pattern, line):
                    self.add_issue("deprecated_api", file_path, i,
                                 f"{message}: {line.strip()}", "Medium")
    
    def check_empty_files(self, content, file_path):
        """Check for empty or stub files"""
        # Remove comments and whitespace
        code_content = re.sub(r'//.*', '', content)
        code_content = re.sub(r'/\*.*?\*/', '', code_content, flags=re.DOTALL)
        code_content = code_content.strip()
        
        # Check if file only has imports and basic structure
        if len(code_content) < 100:  # Arbitrary threshold
            lines_of_code = len([l for l in code_content.split('\n') if l.strip()])
            if lines_of_code < 5:
                self.add_issue("empty_file", file_path, 0,
                             "File appears to be empty or contains minimal implementation", "Low")
    
    def check_type_issues(self, content, lines, file_path):
        """Check for potential type mismatches"""
        # Check for common type issues
        type_patterns = [
            (r'as\?\s+\w+', "Optional cast - verify type safety"),
            (r'Any(?:\s|,|\))', "Usage of Any type - consider more specific types"),
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, message in type_patterns:
                if re.search(pattern, line):
                    self.add_issue("type_issue", file_path, i,
                                 f"{message}: {line.strip()}", "Low")
    
    def add_issue(self, issue_type, file_path, line_number, description, severity):
        """Add an issue to the collection"""
        self.issues[issue_type].append({
            "file": file_path,
            "line": line_number,
            "description": description,
            "severity": severity
        })
    
    def generate_report(self):
        """Generate a comprehensive report"""
        report = {
            "summary": {
                "total_issues": sum(len(issues) for issues in self.issues.values()),
                "by_type": {k: len(v) for k, v in self.issues.items()},
                "by_severity": defaultdict(int)
            },
            "issues": self.issues
        }
        
        # Count by severity
        for issue_list in self.issues.values():
            for issue in issue_list:
                report["summary"]["by_severity"][issue["severity"]] += 1
        
        return report

def main():
    analyzer = SwiftAnalyzer("/Users/cvr/Documents/Project/MedicationManager")
    analyzer.analyze_all_files()
    report = analyzer.generate_report()
    
    # Save detailed report
    with open("comprehensive-analysis-report.json", "w") as f:
        json.dump(report, f, indent=2)
    
    # Print summary
    print("\n=== COMPREHENSIVE ANALYSIS REPORT ===")
    print(f"\nTotal Issues Found: {report['summary']['total_issues']}")
    print("\nIssues by Type:")
    for issue_type, count in report['summary']['by_type'].items():
        print(f"  - {issue_type}: {count}")
    
    print("\nIssues by Severity:")
    for severity in ['Critical', 'High', 'Medium', 'Low']:
        count = report['summary']['by_severity'].get(severity, 0)
        print(f"  - {severity}: {count}")
    
    # Print critical and high severity issues
    print("\n=== CRITICAL AND HIGH SEVERITY ISSUES ===")
    for issue_type, issues in report['issues'].items():
        critical_high = [i for i in issues if i['severity'] in ['Critical', 'High']]
        if critical_high:
            print(f"\n{issue_type.upper()}:")
            for issue in critical_high[:10]:  # Show first 10
                print(f"  File: {issue['file']}")
                print(f"  Line: {issue['line']}")
                print(f"  Issue: {issue['description']}")
                print(f"  Severity: {issue['severity']}")
                print()

if __name__ == "__main__":
    main()