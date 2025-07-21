#!/usr/bin/env python3

"""
MedicationManager Detailed Project Validator
This script performs deep analysis of Swift files for:
- Syntax correctness
- AppTheme compliance
- Code style violations
- Common Swift errors
"""

import os
import re
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple, Set

# ANSI color codes
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

class ProjectValidator:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.issues: Dict[str, List[Dict]] = {
            'syntax_errors': [],
            'hardcoded_values': [],
            'apptheme_violations': [],
            'import_issues': [],
            'naming_violations': [],
            'memory_issues': [],
            'async_issues': [],
            'todo_items': []
        }
        self.stats = {
            'total_files': 0,
            'files_checked': 0,
            'total_lines': 0,
            'issues_found': 0
        }
        
        # Protected files that should not be modified
        self.protected_files = {
            'FirebaseManager.swift',
            'PhoneAuthView.swift',
            'LoginView.swift',
            'MedicationManagerApp.swift'
        }
        
        # Required AppTheme patterns
        self.apptheme_patterns = {
            'colors': r'AppTheme\.Colors\.',
            'typography': r'AppTheme\.Typography\.',
            'spacing': r'AppTheme\.Spacing\.',
            'corner_radius': r'AppTheme\.CornerRadius\.',
            'animation': r'AppTheme\.Animation\.'
        }
        
        # Hardcoded value patterns to detect
        self.hardcoded_patterns = {
            'strings': (r'"[A-Za-z ]{3,}"', ['AppStrings.', '#if DEBUG', 'print(', 'Logger(', 'category:', 'subsystem:', 'identifier:', 'forKey:']),
            'colors': (r'\.(red|blue|green|yellow|orange|purple|pink|gray|black|white|primary|secondary)\b', ['AppTheme.Colors']),
            'fonts': (r'\.font\(\.system', ['AppTheme.Typography']),
            'padding': (r'\.(padding|spacing)\([0-9]+\)', ['AppTheme.Spacing']),
            'corner_radius': (r'\.cornerRadius\([0-9]+\)', ['AppTheme.CornerRadius']),
            'font_size': (r'size:\s*[0-9]+', ['AppTheme.Typography']),
            'opacity': (r'\.opacity\(0\.[0-9]+\)', ['AppTheme.Opacity']),
        }
        
    def validate_project(self):
        """Main validation entry point"""
        print(f"{Colors.BOLD}🔍 MedicationManager Detailed Project Validation{Colors.RESET}")
        print("=" * 60)
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Collect all Swift files
        swift_files = self.collect_swift_files()
        self.stats['total_files'] = len(swift_files)
        
        print(f"Found {Colors.CYAN}{len(swift_files)}{Colors.RESET} Swift files to analyze")
        print()
        
        # Validate each file
        for i, file_path in enumerate(swift_files, 1):
            self.validate_file(file_path, i, len(swift_files))
            
        # Generate report
        self.generate_report()
        
    def collect_swift_files(self) -> List[Path]:
        """Collect all Swift files in the project"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git'}
        
        for root, dirs, files in os.walk(self.project_root):
            # Remove excluded directories
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def validate_file(self, file_path: Path, index: int, total: int):
        """Validate a single Swift file"""
        relative_path = file_path.relative_to(self.project_root)
        print(f"[{index}/{total}] Checking: {relative_path}")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            self.stats['files_checked'] += 1
            self.stats['total_lines'] += len(lines)
            
            # Skip protected files for certain checks
            is_protected = any(protected in str(file_path) for protected in self.protected_files)
            
            # Run various checks
            self.check_syntax(file_path, content)
            
            if not is_protected:
                self.check_hardcoded_values(file_path, content, lines)
                
            self.check_apptheme_usage(file_path, content)
            self.check_imports(file_path, content)
            self.check_naming_conventions(file_path, content)
            self.check_memory_safety(file_path, content)
            self.check_async_await(file_path, content)
            self.check_todos(file_path, content, lines)
            
        except Exception as e:
            self.add_issue('syntax_errors', file_path, 0, f"Failed to read file: {e}")
    
    def check_syntax(self, file_path: Path, content: str):
        """Check for basic Swift syntax issues"""
        # Check for balanced braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            self.add_issue('syntax_errors', file_path, 0, 
                          f"Unbalanced braces: {open_braces} open, {close_braces} close")
        
        # Check for balanced parentheses
        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            self.add_issue('syntax_errors', file_path, 0,
                          f"Unbalanced parentheses: {open_parens} open, {close_parens} close")
        
        # Check for common syntax errors
        syntax_patterns = [
            (r';;', 'Double semicolon'),
            (r'^\s*}\s*else\s*{', 'Incorrect else placement'),
            (r'let\s+let\b', 'Double let declaration'),
            (r'var\s+var\b', 'Double var declaration'),
            (r'func\s+func\b', 'Double func declaration'),
        ]
        
        for pattern, description in syntax_patterns:
            matches = re.finditer(pattern, content, re.MULTILINE)
            for match in matches:
                line_num = content[:match.start()].count('\n') + 1
                self.add_issue('syntax_errors', file_path, line_num, description)
    
    def check_hardcoded_values(self, file_path: Path, content: str, lines: List[str]):
        """Check for hardcoded values that should use AppTheme/AppStrings"""
        for value_type, (pattern, exclusions) in self.hardcoded_patterns.items():
            for i, line in enumerate(lines, 1):
                # Skip comments and DEBUG blocks
                if line.strip().startswith('//') or '#if DEBUG' in line:
                    continue
                    
                # Check if line contains the pattern
                if re.search(pattern, line):
                    # Check if any exclusion is present
                    if not any(exclusion in line for exclusion in exclusions):
                        self.add_issue('hardcoded_values', file_path, i,
                                     f"Hardcoded {value_type}: {line.strip()}")
    
    def check_apptheme_usage(self, file_path: Path, content: str):
        """Check if UI files properly use AppTheme"""
        # Only check View files
        if 'View.swift' not in str(file_path):
            return
            
        # Skip model and non-UI files
        if any(skip in str(file_path) for skip in ['Model', 'Manager', 'Error', 'Test']):
            return
            
        # Check if file uses any AppTheme
        uses_apptheme = any(re.search(pattern, content) for pattern in self.apptheme_patterns.values())
        
        if not uses_apptheme:
            self.add_issue('apptheme_violations', file_path, 0,
                          "View file doesn't use AppTheme for styling")
        
        # Check for specific UI elements without AppTheme
        ui_patterns = [
            (r'\.foregroundColor\((?!AppTheme)', 'foregroundColor without AppTheme.Colors'),
            (r'\.background\(Color\.(?!clear)', 'background color without AppTheme.Colors'),
            (r'\.padding\(\d+\)', 'padding with hardcoded value'),
            (r'\.frame\(width:\s*\d+', 'frame with hardcoded width'),
            (r'\.frame\(height:\s*\d+', 'frame with hardcoded height'),
        ]
        
        for pattern, description in ui_patterns:
            matches = re.finditer(pattern, content)
            for match in matches:
                line_num = content[:match.start()].count('\n') + 1
                self.add_issue('apptheme_violations', file_path, line_num, description)
    
    def check_imports(self, file_path: Path, content: str):
        """Check for missing or unnecessary imports"""
        imports = re.findall(r'^import\s+(\w+)', content, re.MULTILINE)
        
        # Check for duplicate imports
        if len(imports) != len(set(imports)):
            duplicates = [imp for imp in imports if imports.count(imp) > 1]
            self.add_issue('import_issues', file_path, 0,
                          f"Duplicate imports: {', '.join(set(duplicates))}")
        
        # Check for missing SwiftUI import in View files
        if 'View.swift' in str(file_path) and 'SwiftUI' not in imports:
            self.add_issue('import_issues', file_path, 0,
                          "View file missing SwiftUI import")
        
        # Check for missing Foundation import if using common types
        foundation_types = ['Date', 'URL', 'UUID', 'Data', 'JSONEncoder', 'JSONDecoder']
        uses_foundation = any(re.search(rf'\b{ftype}\b', content) for ftype in foundation_types)
        if uses_foundation and 'Foundation' not in imports and 'SwiftUI' not in imports:
            self.add_issue('import_issues', file_path, 0,
                          "File uses Foundation types but missing import")
    
    def check_naming_conventions(self, file_path: Path, content: str):
        """Check Swift naming conventions"""
        # Check for non-camelCase variables
        var_pattern = r'(?:let|var)\s+([a-z_][a-zA-Z0-9_]*)'
        for match in re.finditer(var_pattern, content):
            var_name = match.group(1)
            if '_' in var_name and not var_name.startswith('_'):
                line_num = content[:match.start()].count('\n') + 1
                self.add_issue('naming_violations', file_path, line_num,
                              f"Variable '{var_name}' should use camelCase")
        
        # Check for non-PascalCase types
        type_pattern = r'(?:class|struct|enum|protocol)\s+([A-Za-z][a-zA-Z0-9]*)'
        for match in re.finditer(type_pattern, content):
            type_name = match.group(1)
            if not type_name[0].isupper():
                line_num = content[:match.start()].count('\n') + 1
                self.add_issue('naming_violations', file_path, line_num,
                              f"Type '{type_name}' should start with uppercase")
    
    def check_memory_safety(self, file_path: Path, content: str):
        """Check for potential memory issues"""
        # Check for retain cycles
        closure_self_pattern = r'{\s*\[weak self\]|{\s*\[unowned self\]|{\s*(?!\[)'
        closures = re.finditer(r'{\s*(?:\([^)]*\)\s*in)?', content)
        
        for closure in closures:
            closure_content = content[closure.end():content.find('}', closure.end())]
            if 'self.' in closure_content or 'self?' in closure_content:
                if not re.match(r'{\s*\[(weak|unowned)', content[closure.start():]):
                    line_num = content[:closure.start()].count('\n') + 1
                    self.add_issue('memory_issues', file_path, line_num,
                                  "Potential retain cycle: closure captures self without [weak self]")
        
        # Check for force unwrapping
        force_unwrap_pattern = r'[^!]=.*!(?![=!])'
        for match in re.finditer(force_unwrap_pattern, content):
            line_num = content[:match.start()].count('\n') + 1
            line_content = content.split('\n')[line_num - 1].strip()
            # Skip certain safe patterns
            if not any(safe in line_content for safe in ['IBOutlet', 'fatalError', 'precondition']):
                self.add_issue('memory_issues', file_path, line_num,
                              f"Force unwrapping detected: {line_content}")
    
    def check_async_await(self, file_path: Path, content: str):
        """Check for async/await issues"""
        # Check for missing async in function that uses await
        functions = re.finditer(r'func\s+\w+[^{]*{', content)
        for func in functions:
            func_content = content[func.start():content.find('}', func.end())]
            if 'await' in func_content and 'async' not in func.group():
                line_num = content[:func.start()].count('\n') + 1
                self.add_issue('async_issues', file_path, line_num,
                              "Function uses 'await' but is not marked 'async'")
        
        # Check for missing await
        async_calls = ['fetch', 'save', 'load', 'analyze', 'sync']
        for call in async_calls:
            pattern = rf'(?<!await\s)(?<!await\s\s){call}\w*\('
            for match in re.finditer(pattern, content):
                line_num = content[:match.start()].count('\n') + 1
                self.add_issue('async_issues', file_path, line_num,
                              f"Potential missing 'await' for async call: {match.group()}")
    
    def check_todos(self, file_path: Path, content: str, lines: List[str]):
        """Check for TODO, FIXME, and HACK comments"""
        todo_pattern = r'//\s*(TODO|FIXME|HACK):\s*(.+)'
        for i, line in enumerate(lines, 1):
            match = re.search(todo_pattern, line)
            if match:
                todo_type = match.group(1)
                todo_text = match.group(2).strip()
                self.add_issue('todo_items', file_path, i,
                              f"{todo_type}: {todo_text}")
    
    def add_issue(self, issue_type: str, file_path: Path, line_num: int, description: str):
        """Add an issue to the issues list"""
        self.issues[issue_type].append({
            'file': str(file_path.relative_to(self.project_root)),
            'line': line_num,
            'description': description
        })
        self.stats['issues_found'] += 1
    
    def generate_report(self):
        """Generate and display the validation report"""
        print()
        print(f"{Colors.BOLD}{'=' * 60}{Colors.RESET}")
        print(f"{Colors.BOLD}VALIDATION REPORT{Colors.RESET}")
        print(f"{Colors.BOLD}{'=' * 60}{Colors.RESET}")
        print()
        
        # Summary statistics
        print(f"{Colors.CYAN}Summary:{Colors.RESET}")
        print(f"  Files analyzed: {self.stats['files_checked']}/{self.stats['total_files']}")
        print(f"  Total lines of code: {self.stats['total_lines']:,}")
        print(f"  Total issues found: {self.stats['issues_found']}")
        print()
        
        # Detailed issues by category
        issue_colors = {
            'syntax_errors': Colors.RED,
            'hardcoded_values': Colors.YELLOW,
            'apptheme_violations': Colors.YELLOW,
            'import_issues': Colors.MAGENTA,
            'naming_violations': Colors.CYAN,
            'memory_issues': Colors.RED,
            'async_issues': Colors.YELLOW,
            'todo_items': Colors.BLUE
        }
        
        issue_titles = {
            'syntax_errors': '❌ Syntax Errors',
            'hardcoded_values': '⚠️  Hardcoded Values',
            'apptheme_violations': '🎨 AppTheme Violations',
            'import_issues': '📦 Import Issues',
            'naming_violations': '📝 Naming Convention Violations',
            'memory_issues': '💾 Memory Safety Issues',
            'async_issues': '⏳ Async/Await Issues',
            'todo_items': '📌 TODO Items'
        }
        
        for issue_type, issues in self.issues.items():
            if issues:
                color = issue_colors.get(issue_type, Colors.RESET)
                print(f"{color}{issue_titles.get(issue_type, issue_type)} ({len(issues)} found):{Colors.RESET}")
                
                # Group by file
                files = {}
                for issue in issues:
                    if issue['file'] not in files:
                        files[issue['file']] = []
                    files[issue['file']].append(issue)
                
                # Display up to 5 files per category
                for i, (file, file_issues) in enumerate(sorted(files.items())[:5]):
                    print(f"\n  {file}:")
                    # Display up to 3 issues per file
                    for issue in file_issues[:3]:
                        if issue['line'] > 0:
                            print(f"    Line {issue['line']}: {issue['description']}")
                        else:
                            print(f"    {issue['description']}")
                    
                    if len(file_issues) > 3:
                        print(f"    ... and {len(file_issues) - 3} more issues")
                
                if len(files) > 5:
                    print(f"\n  ... and {len(files) - 5} more files with issues")
                print()
        
        # Save detailed report to file
        self.save_detailed_report()
        
        # Overall status
        print(f"{Colors.BOLD}{'=' * 60}{Colors.RESET}")
        if self.stats['issues_found'] == 0:
            print(f"{Colors.GREEN}✅ No issues found! Project is clean.{Colors.RESET}")
        elif self.issues['syntax_errors'] or self.issues['memory_issues']:
            print(f"{Colors.RED}❌ Critical issues found. Please fix syntax and memory issues.{Colors.RESET}")
        else:
            print(f"{Colors.YELLOW}⚠️  Non-critical issues found. Review and fix as needed.{Colors.RESET}")
    
    def save_detailed_report(self):
        """Save a detailed report to a JSON file"""
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'summary': self.stats,
            'issues': self.issues
        }
        
        report_filename = f"validation-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_filename, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"\nDetailed report saved to: {Colors.GREEN}{report_filename}{Colors.RESET}")

def main():
    # Get project root (current directory or specified)
    project_root = sys.argv[1] if len(sys.argv) > 1 else '.'
    
    # Run validation
    validator = ProjectValidator(project_root)
    validator.validate_project()

if __name__ == '__main__':
    main()