#!/usr/bin/env python3

"""
Runtime simulation checker for MedicationManager
Simulates runtime scenarios to detect potential issues
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

class RuntimeSimulationChecker:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.potential_crashes = []
        self.memory_issues = []
        self.performance_issues = []
        self.concurrency_issues = []
        self.api_issues = []
        
    def simulate(self):
        """Run all simulation checks"""
        print("🔮 Runtime Simulation Analysis")
        print("=" * 60)
        
        self.check_force_unwrap_scenarios()
        self.check_array_bounds()
        self.check_optional_chaining()
        self.check_async_await_issues()
        self.check_memory_retain_cycles()
        self.check_api_error_handling()
        self.check_concurrency_safety()
        self.check_performance_bottlenecks()
        
        self.generate_simulation_report()
    
    def check_force_unwrap_scenarios(self):
        """Simulate force unwrap crash scenarios"""
        print("\n💥 Checking Force Unwrap Scenarios...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                
                for i, line in enumerate(lines):
                    # Force unwrap after optional chain
                    if '?.' in line and '!' in line:
                        self.potential_crashes.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': i + 1,
                            'code': line.strip(),
                            'issue': 'Force unwrap after optional chain',
                            'severity': 'high'
                        })
                    
                    # Force unwrap dictionary/array access
                    if re.search(r'\[.+\]!', line):
                        self.potential_crashes.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': i + 1,
                            'code': line.strip(),
                            'issue': 'Force unwrap collection access',
                            'severity': 'critical'
                        })
                    
                    # as! force cast
                    if ' as! ' in line:
                        self.potential_crashes.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'line': i + 1,
                            'code': line.strip(),
                            'issue': 'Force cast',
                            'severity': 'high'
                        })
            except:
                pass
    
    def check_array_bounds(self):
        """Check for potential array index out of bounds"""
        print("\n📊 Checking Array Bounds...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Direct index access without bounds check
                index_accesses = re.findall(r'(\w+)\[(\d+)\]', content)
                for var_name, index in index_accesses:
                    if int(index) > 0:  # Non-zero index
                        self.potential_crashes.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'issue': f'Hard-coded array index [{index}] without bounds check',
                            'variable': var_name,
                            'severity': 'medium'
                        })
                
                # .first! or .last! usage
                if '.first!' in content or '.last!' in content:
                    self.potential_crashes.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Force unwrapping first/last on collection',
                        'severity': 'high'
                    })
            except:
                pass
    
    def check_optional_chaining(self):
        """Check optional handling patterns"""
        print("\n❓ Checking Optional Handling...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Multiple optional chains
                long_chains = re.findall(r'(\w+\?\.(?:\w+\?\.){2,})', content)
                for chain in long_chains:
                    self.potential_crashes.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Long optional chain',
                        'chain': chain,
                        'severity': 'low'
                    })
            except:
                pass
    
    def check_async_await_issues(self):
        """Check async/await usage patterns"""
        print("\n⏳ Checking Async/Await Patterns...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Async function without error handling
                async_funcs = re.findall(r'func\s+(\w+).*async\s*(?:throws\s*)?->', content)
                for func in async_funcs:
                    if f'try await {func}' not in content and f'await {func}' in content:
                        self.concurrency_issues.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'function': func,
                            'issue': 'Async function called without try',
                            'severity': 'medium'
                        })
                
                # Task without error handling
                if 'Task {' in content and 'try' not in content:
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if 'Task {' in line:
                            # Check next 10 lines for try
                            task_block = '\n'.join(lines[i:i+10])
                            if 'try' not in task_block:
                                self.concurrency_issues.append({
                                    'file': str(file_path.relative_to(self.project_root)),
                                    'line': i + 1,
                                    'issue': 'Task without error handling',
                                    'severity': 'medium'
                                })
            except:
                pass
    
    def check_memory_retain_cycles(self):
        """Check for potential retain cycles"""
        print("\n💾 Checking Memory Retain Cycles...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Closure without weak self
                closure_patterns = [
                    r'{\s*\n\s*self\.',
                    r'{\s*self\.',
                    r'Timer\.scheduledTimer.*{\s*self',
                    r'DispatchQueue.*{\s*self'
                ]
                
                for pattern in closure_patterns:
                    if re.search(pattern, content) and '[weak self]' not in content:
                        self.memory_issues.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'issue': 'Potential retain cycle in closure',
                            'pattern': pattern,
                            'severity': 'high'
                        })
                
                # Delegate not weak
                if 'delegate:' in content and 'weak var delegate' not in content:
                    self.memory_issues.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Delegate should be weak',
                        'severity': 'high'
                    })
            except:
                pass
    
    def check_api_error_handling(self):
        """Check API error handling"""
        print("\n🌐 Checking API Error Handling...")
        
        api_patterns = [
            'URLSession.shared',
            'Firebase',
            'ClaudeAIClient',
            'CoreDataManager'
        ]
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                for api in api_patterns:
                    if api in content:
                        # Check for proper error handling
                        if 'catch' not in content and 'Result<' not in content:
                            self.api_issues.append({
                                'file': str(file_path.relative_to(self.project_root)),
                                'api': api,
                                'issue': 'API usage without error handling',
                                'severity': 'high'
                            })
                        
                        # Check for error logging
                        if 'catch' in content and 'logger' not in content.lower():
                            self.api_issues.append({
                                'file': str(file_path.relative_to(self.project_root)),
                                'api': api,
                                'issue': 'Error caught but not logged',
                                'severity': 'medium'
                            })
            except:
                pass
    
    def check_concurrency_safety(self):
        """Check concurrency safety issues"""
        print("\n🔒 Checking Concurrency Safety...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # @Published without @MainActor
                if '@Published' in content and 'ViewModel' in str(file_path):
                    if '@MainActor' not in content:
                        self.concurrency_issues.append({
                            'file': str(file_path.relative_to(self.project_root)),
                            'issue': '@Published properties need @MainActor',
                            'severity': 'high'
                        })
                
                # UI updates not on main thread
                ui_updates = ['self.', '.text =', '.isHidden =', '.alpha =']
                for update in ui_updates:
                    if update in content and 'Task { @MainActor' not in content:
                        # Check if it's in an async context
                        if 'async' in content:
                            self.concurrency_issues.append({
                                'file': str(file_path.relative_to(self.project_root)),
                                'issue': 'Potential UI update off main thread',
                                'pattern': update,
                                'severity': 'critical'
                            })
            except:
                pass
    
    def check_performance_bottlenecks(self):
        """Check for performance issues"""
        print("\n⚡ Checking Performance Bottlenecks...")
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Nested loops
                if re.search(r'for.*{.*for.*{', content, re.DOTALL):
                    self.performance_issues.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Nested loops detected',
                        'severity': 'medium'
                    })
                
                # Multiple filter/map chains
                if content.count('.filter') + content.count('.map') > 3:
                    self.performance_issues.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Multiple filter/map operations',
                        'severity': 'low'
                    })
                
                # Large data in memory
                if 'Data(' in content and '.count > 1000000' in content:
                    self.performance_issues.append({
                        'file': str(file_path.relative_to(self.project_root)),
                        'issue': 'Large data operation',
                        'severity': 'high'
                    })
            except:
                pass
    
    def collect_swift_files(self):
        """Collect all Swift files"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git'}
        
        for root, dirs, files in os.walk(self.project_root / 'MedicationManager'):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def generate_simulation_report(self):
        """Generate simulation report"""
        print("\n" + "=" * 60)
        print("📊 RUNTIME SIMULATION REPORT")
        print("=" * 60)
        
        all_issues = {
            'Potential Crashes': self.potential_crashes,
            'Memory Issues': self.memory_issues,
            'Concurrency Issues': self.concurrency_issues,
            'API Issues': self.api_issues,
            'Performance Issues': self.performance_issues
        }
        
        total_issues = sum(len(issues) for issues in all_issues.values())
        
        if total_issues == 0:
            print("\n✅ No potential runtime issues detected!")
        else:
            print(f"\n⚠️  Found {total_issues} potential runtime issues:\n")
            
            # Group by severity
            severity_counts = defaultdict(int)
            for category, issues in all_issues.items():
                for issue in issues:
                    severity_counts[issue.get('severity', 'unknown')] += 1
            
            print("By Severity:")
            for severity in ['critical', 'high', 'medium', 'low']:
                if severity in severity_counts:
                    print(f"  {severity.upper()}: {severity_counts[severity]}")
            
            # Show top issues by category
            print("\nTop Issues by Category:")
            for category, issues in all_issues.items():
                if issues:
                    print(f"\n{category} ({len(issues)} issues):")
                    # Show up to 3 critical/high severity issues
                    shown = 0
                    for issue in sorted(issues, key=lambda x: {'critical': 0, 'high': 1, 'medium': 2, 'low': 3}.get(x.get('severity', 'low'), 4)):
                        if shown < 3:
                            print(f"  [{issue.get('severity', 'unknown').upper()}] {issue.get('file', 'Unknown')}")
                            print(f"    Issue: {issue.get('issue', 'Unknown issue')}")
                            if 'line' in issue:
                                print(f"    Line {issue['line']}: {issue.get('code', '')}")
                            shown += 1
        
        # Save detailed report
        report = {
            'summary': {
                'total_issues': total_issues,
                'severity_breakdown': dict(severity_counts)
            },
            'issues': all_issues
        }
        
        with open('runtime-simulation-report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        print("\n💾 Detailed report saved to runtime-simulation-report.json")
        
        # Recommendations
        print("\n💡 Recommendations:")
        if severity_counts.get('critical', 0) > 0:
            print("  🚨 Fix CRITICAL issues immediately - these will likely crash the app")
        if severity_counts.get('high', 0) > 0:
            print("  ⚠️  Address HIGH severity issues before release")
        print("  📱 Test thoroughly on device with various data scenarios")
        print("  🔍 Use Xcode's Thread Sanitizer and Address Sanitizer")
        print("  📊 Profile with Instruments for memory and performance")

def main():
    checker = RuntimeSimulationChecker('.')
    checker.simulate()

if __name__ == '__main__':
    main()