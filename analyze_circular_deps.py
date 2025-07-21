#!/usr/bin/env python3

import os
import re
from collections import defaultdict
import json

def extract_imports(file_path):
    """Extract import statements from a Swift file."""
    imports = set()
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Match import statements
            import_pattern = r'import\s+(\w+)'
            for match in re.finditer(import_pattern, content):
                imports.add(match.group(1))
            
            # Also look for @testable imports
            testable_pattern = r'@testable\s+import\s+(\w+)'
            for match in re.finditer(testable_pattern, content):
                imports.add(match.group(1))
                
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    
    return imports

def extract_type_references(file_path):
    """Extract type references that might indicate dependencies."""
    references = set()
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
            # Look for property declarations with specific types
            # e.g., @StateObject private var navigationManager = NavigationManager.shared
            property_pattern = r'(?:var|let)\s+\w+\s*[:=]\s*(\w+)(?:\.shared|\.init|\()?'
            for match in re.finditer(property_pattern, content):
                type_name = match.group(1)
                if type_name[0].isupper():  # Likely a type name
                    references.add(type_name)
            
            # Look for type annotations
            type_annotation_pattern = r':\s*(\w+)(?:<|>|\s|$)'
            for match in re.finditer(type_annotation_pattern, content):
                type_name = match.group(1)
                if type_name[0].isupper():
                    references.add(type_name)
            
            # Look for function parameters and return types
            func_pattern = r'func\s+\w+.*?(?:->|:)\s*(\w+)'
            for match in re.finditer(func_pattern, content):
                type_name = match.group(1)
                if type_name[0].isupper():
                    references.add(type_name)
                    
    except Exception as e:
        print(f"Error analyzing {file_path}: {e}")
    
    return references

def get_file_name_without_extension(path):
    """Get the file name without extension."""
    return os.path.splitext(os.path.basename(path))[0]

def find_circular_dependencies(root_dir):
    """Find circular dependencies in Swift files."""
    # First, build a map of all Swift files
    swift_files = []
    file_to_path = {}
    
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.swift') and not filename.startswith('.'):
                file_path = os.path.join(dirpath, filename)
                swift_files.append(file_path)
                file_name = get_file_name_without_extension(file_path)
                file_to_path[file_name] = file_path
    
    # Build dependency graph
    dependencies = defaultdict(set)
    imports_map = {}
    references_map = {}
    
    for file_path in swift_files:
        file_name = get_file_name_without_extension(file_path)
        imports = extract_imports(file_path)
        references = extract_type_references(file_path)
        
        imports_map[file_name] = imports
        references_map[file_name] = references
        
        # For each reference, check if it matches a file name
        for ref in references:
            if ref in file_to_path and ref != file_name:
                dependencies[file_name].add(ref)
    
    # Find circular dependencies
    circular_deps = []
    checked_pairs = set()
    
    for file_a, deps_a in dependencies.items():
        for file_b in deps_a:
            pair = tuple(sorted([file_a, file_b]))
            if pair not in checked_pairs:
                checked_pairs.add(pair)
                
                # Check if B also depends on A
                if file_a in dependencies.get(file_b, set()):
                    circular_deps.append({
                        'files': [file_a, file_b],
                        'paths': [file_to_path.get(file_a, 'Unknown'), file_to_path.get(file_b, 'Unknown')],
                        'references': {
                            file_a: list(references_map.get(file_a, set()) & {file_b}),
                            file_b: list(references_map.get(file_b, set()) & {file_a})
                        }
                    })
    
    # Find longer circular dependency chains
    def find_cycles_from(start, current, path, visited):
        if len(path) > 10:  # Prevent infinite loops
            return []
        
        cycles = []
        for next_node in dependencies.get(current, set()):
            if next_node == start and len(path) > 2:
                # Found a cycle
                cycles.append(path + [next_node])
            elif next_node not in visited:
                visited.add(next_node)
                cycles.extend(find_cycles_from(start, next_node, path + [next_node], visited.copy()))
        
        return cycles
    
    # Look for cycles of length > 2
    longer_cycles = []
    checked_cycles = set()
    
    for start_node in dependencies:
        cycles = find_cycles_from(start_node, start_node, [start_node], {start_node})
        for cycle in cycles:
            cycle_key = tuple(sorted(cycle[:-1]))  # Remove duplicate start node
            if cycle_key not in checked_cycles and len(cycle_key) > 2:
                checked_cycles.add(cycle_key)
                longer_cycles.append({
                    'files': list(cycle_key),
                    'cycle_path': cycle[:-1],
                    'paths': [file_to_path.get(f, 'Unknown') for f in cycle_key]
                })
    
    return {
        'circular_dependencies': circular_deps,
        'longer_cycles': longer_cycles,
        'dependency_graph': {k: list(v) for k, v in dependencies.items() if v},
        'total_files_analyzed': len(swift_files)
    }

def main():
    root_dir = '/Users/cvr/Documents/Project/MedicationManager/MedicationManager'
    results = find_circular_dependencies(root_dir)
    
    print("=== Circular Dependency Analysis ===\n")
    
    print(f"Total Swift files analyzed: {results['total_files_analyzed']}\n")
    
    if results['circular_dependencies']:
        print(f"Found {len(results['circular_dependencies'])} direct circular dependencies:\n")
        for i, dep in enumerate(results['circular_dependencies'], 1):
            print(f"{i}. {dep['files'][0]} <-> {dep['files'][1]}")
            print(f"   Paths:")
            for j, path in enumerate(dep['paths']):
                print(f"   - {path}")
            print(f"   References:")
            for file, refs in dep['references'].items():
                if refs:
                    print(f"   - {file} references: {', '.join(refs)}")
            print()
    else:
        print("No direct circular dependencies found.\n")
    
    if results['longer_cycles']:
        print(f"\nFound {len(results['longer_cycles'])} longer circular dependency chains:\n")
        for i, cycle in enumerate(results['longer_cycles'], 1):
            print(f"{i}. Cycle: {' -> '.join(cycle['cycle_path'])}")
            print()
    
    # Save detailed results
    with open('/Users/cvr/Documents/Project/MedicationManager/circular_deps_report.json', 'w') as f:
        json.dump(results, f, indent=2)
    
    print("\nDetailed results saved to circular_deps_report.json")

if __name__ == "__main__":
    main()