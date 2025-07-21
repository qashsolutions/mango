#!/usr/bin/env python3

import os
import re
from collections import defaultdict
import json

def extract_class_info(file_path):
    """Extract class name and its dependencies from a Swift file."""
    class_name = None
    dependencies = set()
    imports = set()
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Find class declaration
            class_pattern = r'(?:@\w+\s+)*(?:public\s+|private\s+|internal\s+|open\s+|final\s+)*class\s+(\w+)'
            class_match = re.search(class_pattern, content)
            if class_match:
                class_name = class_match.group(1)
            
            # Find struct declaration if no class found
            if not class_name:
                struct_pattern = r'(?:@\w+\s+)*(?:public\s+|private\s+|internal\s+)?struct\s+(\w+)'
                struct_match = re.search(struct_pattern, content)
                if struct_match:
                    class_name = struct_match.group(1)
            
            # Extract imports
            import_pattern = r'import\s+(\w+)'
            for match in re.finditer(import_pattern, content):
                imports.add(match.group(1))
            
            # Look for singleton patterns (shared instances)
            singleton_pattern = r'(\w+)\.shared'
            for match in re.finditer(singleton_pattern, content):
                dep = match.group(1)
                if dep != class_name and dep[0].isupper():
                    dependencies.add(dep)
            
            # Look for property declarations with manager types
            property_pattern = r'(?:private\s+)?(?:let|var)\s+\w+\s*[:=]\s*(\w+)(?:\.shared|\(\))?'
            for match in re.finditer(property_pattern, content):
                dep = match.group(1)
                if dep != class_name and dep[0].isupper() and 'Manager' in dep:
                    dependencies.add(dep)
            
            # Look for type annotations
            type_pattern = r':\s*(\w+Manager)'
            for match in re.finditer(type_pattern, content):
                dep = match.group(1)
                if dep != class_name:
                    dependencies.add(dep)
            
            # Look for NavigationManager usage
            if 'NavigationManager' in content and class_name != 'NavigationManager':
                dependencies.add('NavigationManager')
            
            # Look for specific manager references
            managers = ['FirebaseManager', 'CoreDataManager', 'DataSyncManager', 
                       'AnalyticsManager', 'NavigationManager', 'SpeechManager',
                       'ConflictDetectionManager', 'UserModeManager', 'VoiceInteractionManager']
            for manager in managers:
                if manager in content and class_name != manager:
                    dependencies.add(manager)
                    
    except Exception as e:
        print(f"Error analyzing {file_path}: {e}")
    
    return class_name, dependencies, imports

def find_manager_circular_dependencies(root_dir):
    """Find circular dependencies specifically focusing on Manager classes."""
    manager_files = {}
    dependencies = defaultdict(set)
    
    # First pass: find all manager files
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.swift') and 'Manager' in filename:
                file_path = os.path.join(dirpath, filename)
                class_name, deps, imports = extract_class_info(file_path)
                if class_name:
                    manager_files[class_name] = file_path
                    dependencies[class_name] = deps
    
    # Also check ViewModels
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('ViewModel.swift'):
                file_path = os.path.join(dirpath, filename)
                class_name, deps, imports = extract_class_info(file_path)
                if class_name:
                    manager_files[class_name] = file_path
                    dependencies[class_name] = deps
    
    # Find circular dependencies
    circular_deps = []
    checked = set()
    
    def find_cycles(start, current, path, visited):
        if current in visited and current == start and len(path) > 1:
            return [path]
        if current in visited or len(path) > 10:
            return []
        
        cycles = []
        visited.add(current)
        
        for dep in dependencies.get(current, []):
            if dep in manager_files:  # Only follow dependencies we have files for
                cycles.extend(find_cycles(start, dep, path + [dep], visited.copy()))
        
        return cycles
    
    for manager in manager_files:
        cycles = find_cycles(manager, manager, [manager], set())
        for cycle in cycles:
            cycle_key = tuple(sorted(set(cycle[:-1])))  # Remove duplicate and sort
            if cycle_key not in checked:
                checked.add(cycle_key)
                circular_deps.append({
                    'cycle': cycle,
                    'files': [manager_files.get(m, 'Unknown') for m in cycle[:-1]]
                })
    
    return {
        'managers': manager_files,
        'dependencies': {k: list(v) for k, v in dependencies.items()},
        'circular_dependencies': circular_deps
    }

def analyze_navigation_patterns(root_dir):
    """Analyze navigation-specific patterns that might cause issues."""
    navigation_issues = []
    
    # Look for views that might have circular navigation dependencies
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('View.swift'):
                file_path = os.path.join(dirpath, filename)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                        # Check if view references NavigationManager
                        if 'NavigationManager' in content:
                            # Check if it also has navigation destination
                            if '.navigationDestination' in content or 'NavigationLink' in content:
                                navigation_issues.append({
                                    'file': file_path,
                                    'issue': 'View uses NavigationManager and has navigation destinations'
                                })
                                
                except Exception as e:
                    print(f"Error analyzing {file_path}: {e}")
    
    return navigation_issues

def main():
    root_dir = '/Users/cvr/Documents/Project/MedicationManager/MedicationManager'
    
    print("=== Advanced Circular Dependency Analysis ===\n")
    
    # Analyze manager dependencies
    manager_results = find_manager_circular_dependencies(root_dir)
    
    print(f"Found {len(manager_results['managers'])} Manager/ViewModel classes\n")
    
    if manager_results['circular_dependencies']:
        print(f"⚠️  Found {len(manager_results['circular_dependencies'])} circular dependency chains:\n")
        for i, dep in enumerate(manager_results['circular_dependencies'], 1):
            print(f"{i}. Circular dependency chain:")
            print(f"   {' -> '.join(dep['cycle'])}")
            print(f"   Files involved:")
            for file in dep['files']:
                print(f"   - {file}")
            print()
    else:
        print("✅ No circular dependencies found among Manager/ViewModel classes\n")
    
    # Show dependency graph for key managers
    print("\n=== Key Manager Dependencies ===\n")
    key_managers = ['NavigationManager', 'FirebaseManager', 'CoreDataManager', 
                   'DataSyncManager', 'ConflictDetectionManager']
    
    for manager in key_managers:
        if manager in manager_results['dependencies']:
            deps = manager_results['dependencies'][manager]
            if deps:
                print(f"{manager} depends on:")
                for dep in deps:
                    print(f"  - {dep}")
                print()
    
    # Analyze navigation patterns
    nav_issues = analyze_navigation_patterns(root_dir)
    if nav_issues:
        print(f"\n⚠️  Found {len(nav_issues)} potential navigation issues:")
        for issue in nav_issues[:5]:  # Show first 5
            print(f"  - {issue['file']}")
            print(f"    Issue: {issue['issue']}")
    
    # Save detailed results
    with open('/Users/cvr/Documents/Project/MedicationManager/dependency_analysis_detailed.json', 'w') as f:
        json.dump({
            'manager_analysis': manager_results,
            'navigation_issues': nav_issues
        }, f, indent=2)
    
    print("\n\nDetailed results saved to dependency_analysis_detailed.json")

if __name__ == "__main__":
    main()