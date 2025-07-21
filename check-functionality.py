#!/usr/bin/env python3

"""
Comprehensive functionality checker for MedicationManager project
Checks individual file correctness and cross-file dependencies
"""

import os
import re
import json
import ast
from pathlib import Path
from collections import defaultdict
from datetime import datetime

class FunctionalityChecker:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.results = {
            'syntax_errors': [],
            'import_errors': [],
            'undefined_references': [],
            'unused_imports': [],
            'missing_dependencies': [],
            'circular_dependencies': [],
            'protocol_conformance': [],
            'type_mismatches': [],
            'async_issues': [],
            'optional_handling': [],
            'api_consistency': [],
            'naming_violations': [],
            'architecture_violations': []
        }
        self.file_imports = {}
        self.file_exports = {}
        self.protocols = {}
        self.classes = {}
        self.structs = {}
        self.enums = {}
        self.functions = {}
        
    def check_all(self):
        """Main entry point for all checks"""
        print("🔍 MedicationManager Functionality Check")
        print("=" * 60)
        
        # Collect Swift files
        swift_files = self.collect_swift_files()
        print(f"Found {len(swift_files)} Swift files to analyze\n")
        
        # Phase 1: Syntax and basic checks
        print("Phase 1: Syntax and Import Analysis...")
        for file_path in swift_files:
            self.check_syntax(file_path)
            self.analyze_imports(file_path)
            self.extract_definitions(file_path)
        
        # Phase 2: Cross-file dependency checks
        print("\nPhase 2: Cross-File Dependency Analysis...")
        self.check_import_resolution()
        self.check_circular_dependencies()
        self.check_unused_imports()
        
        # Phase 3: Type and protocol checks
        print("\nPhase 3: Type and Protocol Analysis...")
        self.check_protocol_conformance()
        self.check_type_consistency()
        
        # Phase 4: Architecture and pattern checks
        print("\nPhase 4: Architecture and Pattern Analysis...")
        self.check_mvvm_compliance()
        self.check_naming_conventions()
        self.check_async_patterns()
        
        # Generate report
        self.generate_report()
        
    def collect_swift_files(self):
        """Collect all Swift files excluding certain directories"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git', 'build'}
        
        for root, dirs, files in os.walk(self.project_root / 'MedicationManager'):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def check_syntax(self, file_path):
        """Check Swift syntax using swiftc"""
        try:
            # Use swiftc syntax checking
            import subprocess
            result = subprocess.run(
                ['swiftc', '-parse', str(file_path)],
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                self.results['syntax_errors'].append({
                    'file': str(file_path.relative_to(self.project_root)),
                    'error': result.stderr
                })
        except Exception as e:
            # If swiftc not available, do basic syntax checks
            self.basic_syntax_check(file_path)
    
    def basic_syntax_check(self, file_path):
        """Basic syntax validation without compiler"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check for basic syntax issues
            issues = []
            
            # Balanced braces
            if content.count('{') != content.count('}'):
                issues.append("Unbalanced braces")
            
            # Balanced parentheses
            if content.count('(') != content.count(')'):
                issues.append("Unbalanced parentheses")
            
            # Balanced brackets
            if content.count('[') != content.count(']'):
                issues.append("Unbalanced brackets")
            
            # Check for @MainActor on ViewModels
            if 'ViewModel' in file_path.name and '@MainActor' not in content:
                issues.append("ViewModel missing @MainActor annotation")
            
            if issues:
                self.results['syntax_errors'].append({
                    'file': str(file_path.relative_to(self.project_root)),
                    'issues': issues
                })
                
        except Exception as e:
            print(f"Error checking {file_path}: {e}")
    
    def analyze_imports(self, file_path):
        """Extract and analyze import statements"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            imports = re.findall(r'^import\s+(\S+)', content, re.MULTILINE)
            self.file_imports[str(file_path)] = imports
            
            # Check for required imports
            if 'View {' in content and 'import SwiftUI' not in content:
                self.results['import_errors'].append({
                    'file': str(file_path.relative_to(self.project_root)),
                    'missing': 'SwiftUI'
                })
            
            if 'Observable' in content and 'import Observation' not in content and '@Observable' in content:
                self.results['import_errors'].append({
                    'file': str(file_path.relative_to(self.project_root)),
                    'missing': 'Observation'
                })
                
        except Exception as e:
            print(f"Error analyzing imports in {file_path}: {e}")
    
    def extract_definitions(self, file_path):
        """Extract class, struct, enum, protocol definitions"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Extract protocols
            protocols = re.findall(r'protocol\s+(\w+)', content)
            for protocol in protocols:
                self.protocols[protocol] = str(file_path)
            
            # Extract classes
            classes = re.findall(r'class\s+(\w+)', content)
            for cls in classes:
                self.classes[cls] = str(file_path)
            
            # Extract structs
            structs = re.findall(r'struct\s+(\w+)', content)
            for struct in structs:
                self.structs[struct] = str(file_path)
            
            # Extract enums
            enums = re.findall(r'enum\s+(\w+)', content)
            for enum in enums:
                self.enums[enum] = str(file_path)
                
        except Exception as e:
            print(f"Error extracting definitions from {file_path}: {e}")
    
    def check_import_resolution(self):
        """Check if all imports can be resolved"""
        system_imports = {
            'SwiftUI', 'Foundation', 'Combine', 'UIKit', 'CoreData',
            'Firebase', 'FirebaseAuth', 'FirebaseFirestore', 'FirebaseAnalytics',
            'OSLog', 'Contacts', 'MessageUI', 'AuthenticationServices',
            'CryptoKit', 'Security', 'AVFoundation', 'Speech', 'Intents',
            'AppIntents', 'Observation'
        }
        
        for file_path, imports in self.file_imports.items():
            for imp in imports:
                if imp not in system_imports:
                    # Check if it's a local module
                    if not self.is_local_module(imp):
                        self.results['undefined_references'].append({
                            'file': str(Path(file_path).relative_to(self.project_root)),
                            'import': imp
                        })
    
    def is_local_module(self, module_name):
        """Check if module exists in project"""
        # For now, assume MedicationManagerKit is the only local module
        return module_name in ['MedicationManagerKit']
    
    def check_circular_dependencies(self):
        """Detect circular import dependencies"""
        # Build dependency graph
        dependencies = defaultdict(set)
        
        for file_path, imports in self.file_imports.items():
            file_name = Path(file_path).stem
            for imp in imports:
                if self.is_local_module(imp):
                    dependencies[file_name].add(imp)
        
        # Check for cycles using DFS
        def has_cycle(node, visited, rec_stack, graph):
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in graph.get(node, []):
                if neighbor not in visited:
                    if has_cycle(neighbor, visited, rec_stack, graph):
                        return True
                elif neighbor in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        visited = set()
        for node in dependencies:
            if node not in visited:
                if has_cycle(node, visited, set(), dependencies):
                    self.results['circular_dependencies'].append(node)
    
    def check_unused_imports(self):
        """Find potentially unused imports"""
        for file_path, imports in self.file_imports.items():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Remove import statements from content
                content_without_imports = re.sub(r'^import.*$', '', content, flags=re.MULTILINE)
                
                for imp in imports:
                    # Check if import is used (basic heuristic)
                    if imp not in ['Foundation', 'SwiftUI', 'Combine']:  # Always needed
                        if imp not in content_without_imports:
                            self.results['unused_imports'].append({
                                'file': str(Path(file_path).relative_to(self.project_root)),
                                'import': imp
                            })
            except:
                pass
    
    def check_protocol_conformance(self):
        """Check protocol conformance declarations"""
        for file_path in self.file_imports.keys():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find protocol conformances
                conformances = re.findall(r':\s*([^{]+)\s*{', content)
                
                for conformance in conformances:
                    protocols = [p.strip() for p in conformance.split(',')]
                    for protocol in protocols:
                        if 'View' in protocol and 'body' not in content:
                            self.results['protocol_conformance'].append({
                                'file': str(Path(file_path).relative_to(self.project_root)),
                                'issue': 'View protocol requires body property'
                            })
                        
                        if 'ObservableObject' in protocol and '@Published' not in content:
                            self.results['protocol_conformance'].append({
                                'file': str(Path(file_path).relative_to(self.project_root)),
                                'issue': 'ObservableObject typically needs @Published properties'
                            })
            except:
                pass
    
    def check_type_consistency(self):
        """Check for type consistency issues"""
        for file_path in self.file_imports.keys():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check for force unwrapping
                force_unwraps = len(re.findall(r'!\s*[^=]', content))
                if force_unwraps > 0:
                    self.results['optional_handling'].append({
                        'file': str(Path(file_path).relative_to(self.project_root)),
                        'count': force_unwraps,
                        'issue': 'Force unwrapping detected'
                    })
                
                # Check for proper async/await usage
                if 'async' in content:
                    if 'Task {' not in content and 'await' not in content:
                        self.results['async_issues'].append({
                            'file': str(Path(file_path).relative_to(self.project_root)),
                            'issue': 'Async function without proper await usage'
                        })
            except:
                pass
    
    def check_mvvm_compliance(self):
        """Check MVVM architecture compliance"""
        view_files = []
        viewmodel_files = []
        
        for file_path in self.file_imports.keys():
            if 'View.swift' in file_path and 'ViewModel' not in file_path:
                view_files.append(file_path)
            elif 'ViewModel.swift' in file_path:
                viewmodel_files.append(file_path)
        
        # Check ViewModels have @MainActor
        for vm_file in viewmodel_files:
            try:
                with open(vm_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if '@MainActor' not in content:
                    self.results['architecture_violations'].append({
                        'file': str(Path(vm_file).relative_to(self.project_root)),
                        'issue': 'ViewModel should have @MainActor annotation'
                    })
                
                # Check for business logic in ViewModel
                if 'NavigationLink' in content or 'Button {' in content:
                    self.results['architecture_violations'].append({
                        'file': str(Path(vm_file).relative_to(self.project_root)),
                        'issue': 'ViewModel contains UI code'
                    })
            except:
                pass
        
        # Check Views don't have business logic
        for view_file in view_files:
            try:
                with open(view_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if 'URLSession' in content or 'CoreDataManager' in content:
                    self.results['architecture_violations'].append({
                        'file': str(Path(view_file).relative_to(self.project_root)),
                        'issue': 'View contains direct data access'
                    })
            except:
                pass
    
    def check_naming_conventions(self):
        """Check Swift naming conventions"""
        for file_path in self.file_imports.keys():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check class/struct names (PascalCase)
                type_names = re.findall(r'(?:class|struct|enum|protocol)\s+(\w+)', content)
                for name in type_names:
                    if not name[0].isupper():
                        self.results['naming_violations'].append({
                            'file': str(Path(file_path).relative_to(self.project_root)),
                            'issue': f'Type {name} should be PascalCase'
                        })
                
                # Check function names (camelCase)
                func_names = re.findall(r'func\s+(\w+)', content)
                for name in func_names:
                    if name[0].isupper():
                        self.results['naming_violations'].append({
                            'file': str(Path(file_path).relative_to(self.project_root)),
                            'issue': f'Function {name} should be camelCase'
                        })
            except:
                pass
    
    def check_async_patterns(self):
        """Check for proper async/await patterns"""
        for file_path in self.file_imports.keys():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check for completion handlers that should be async
                if 'completion:' in content and 'async' not in content:
                    self.results['async_issues'].append({
                        'file': str(Path(file_path).relative_to(self.project_root)),
                        'issue': 'Consider converting completion handlers to async/await'
                    })
                
                # Check for proper MainActor usage
                if '@Published' in content and '@MainActor' not in content:
                    self.results['async_issues'].append({
                        'file': str(Path(file_path).relative_to(self.project_root)),
                        'issue': '@Published properties should be on @MainActor'
                    })
            except:
                pass
    
    def generate_report(self):
        """Generate comprehensive report"""
        print("\n" + "=" * 60)
        print("📊 FUNCTIONALITY CHECK REPORT")
        print("=" * 60)
        
        total_issues = sum(len(v) for v in self.results.values())
        
        if total_issues == 0:
            print("✅ No issues found! All checks passed.")
        else:
            print(f"⚠️  Found {total_issues} total issues:\n")
            
            for category, issues in self.results.items():
                if issues:
                    print(f"\n{category.replace('_', ' ').title()} ({len(issues)} issues):")
                    print("-" * 40)
                    
                    for issue in issues[:5]:  # Show first 5
                        if isinstance(issue, dict):
                            for key, value in issue.items():
                                print(f"  {key}: {value}")
                            print()
                        else:
                            print(f"  - {issue}")
                    
                    if len(issues) > 5:
                        print(f"  ... and {len(issues) - 5} more\n")
        
        # Save detailed report
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'total_files_checked': len(self.file_imports),
            'total_issues': total_issues,
            'results': self.results
        }
        
        with open('functionality-report.json', 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print("\n💾 Detailed report saved to functionality-report.json")
        
        # What we can check vs cannot check
        print("\n" + "=" * 60)
        print("📋 CAPABILITIES SUMMARY")
        print("=" * 60)
        print("\n✅ What This Script CAN Check:")
        print("  • Basic syntax errors (balanced braces, brackets)")
        print("  • Import statements and dependencies")
        print("  • Circular dependencies")
        print("  • Basic protocol conformance")
        print("  • MVVM architecture patterns")
        print("  • Naming conventions")
        print("  • Async/await patterns")
        print("  • Force unwrapping usage")
        print("  • Unused imports (basic heuristic)")
        
        print("\n❌ What This Script CANNOT Check:")
        print("  • Runtime errors")
        print("  • Logic errors")
        print("  • Type safety (without compiler)")
        print("  • Memory leaks")
        print("  • Performance issues")
        print("  • UI/UX correctness")
        print("  • Business logic correctness")
        print("  • API response handling")
        print("  • Core Data model integrity")
        print("  • Firebase configuration")
        
        print("\n💡 For Complete Verification:")
        print("  • Run 'swift build' for compilation")
        print("  • Run 'swift test' for unit tests")
        print("  • Use Xcode's Analyze feature")
        print("  • Test on device/simulator")

def main():
    checker = FunctionalityChecker('.')
    checker.check_all()

if __name__ == '__main__':
    main()