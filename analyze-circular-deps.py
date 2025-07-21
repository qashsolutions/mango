#!/usr/bin/env python3

import os
import re
from pathlib import Path
from collections import defaultdict

def analyze_dependencies():
    """Analyze Swift file dependencies to find circular imports"""
    
    project_root = Path('/Users/cvr/Documents/Project/MedicationManager/MedicationManager')
    dependencies = defaultdict(set)
    file_locations = {}
    
    # Key managers and their locations
    key_files = {
        'NavigationManager': 'Core/Navigation',
        'FirebaseManager': 'Core/Networking', 
        'CoreDataManager': 'Core/Utilities',
        'DataSyncManager': 'Core/Utilities',
        'AnalyticsManager': 'Core/Utilities',
        'VoiceInteractionContext': 'Core/Models',
        'MedicationConflict': 'Core/Models'
    }
    
    # Collect all Swift files
    for root, dirs, files in os.walk(project_root):
        # Skip test and build directories
        if any(skip in root for skip in ['Tests', 'Build', '.build', 'DerivedData']):
            continue
            
        for file in files:
            if file.endswith('.swift'):
                file_path = Path(root) / file
                relative_path = file_path.relative_to(project_root)
                file_name = file_path.stem
                
                # Determine layer (Core, Features, App)
                parts = str(relative_path).split('/')
                layer = parts[0] if parts else 'Unknown'
                
                file_locations[file_name] = {
                    'path': str(relative_path),
                    'layer': layer,
                    'full_path': str(file_path)
                }
                
                # Read file and find dependencies
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Find imports and usages
                    for key_file in key_files:
                        # Direct usage patterns
                        patterns = [
                            rf'{key_file}\.shared',
                            rf'@State.*{key_file}',
                            rf'@StateObject.*{key_file}',
                            rf'let.*{key_file}',
                            rf'var.*{key_file}',
                            rf':\s*{key_file}',
                            rf'NavigationDestination.*{key_file}',
                            rf'SheetDestination.*{key_file}'
                        ]
                        
                        for pattern in patterns:
                            if re.search(pattern, content):
                                dependencies[file_name].add(key_file)
                                break
                    
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
    
    # Analyze circular dependencies
    print("=" * 80)
    print("DEPENDENCY ANALYSIS REPORT")
    print("=" * 80)
    
    # 1. Check for Features -> Core dependencies (violations)
    print("\n🚫 ARCHITECTURAL VIOLATIONS (Features -> Core):")
    violations_found = False
    for file_name, deps in dependencies.items():
        if file_name in file_locations:
            file_info = file_locations[file_name]
            if file_info['layer'] == 'Features':
                core_deps = [d for d in deps if d in file_locations and file_locations[d]['layer'] == 'Core']
                if core_deps:
                    violations_found = True
                    print(f"\n  ❌ {file_name} (Features) depends on:")
                    for dep in core_deps:
                        print(f"     - {dep} (Core)")
    
    if not violations_found:
        print("  ✅ No architectural violations found")
    
    # 2. Analyze key manager dependencies
    print("\n\n📊 KEY MANAGER DEPENDENCIES:")
    for manager in ['NavigationManager', 'FirebaseManager', 'CoreDataManager']:
        if manager in file_locations:
            print(f"\n{manager}:")
            print(f"  Location: {file_locations[manager]['path']}")
            
            # Who depends on this manager
            dependents = []
            for file_name, deps in dependencies.items():
                if manager in deps and file_name != manager:
                    if file_name in file_locations:
                        layer = file_locations[file_name]['layer']
                        dependents.append((file_name, layer))
            
            if dependents:
                print(f"  Used by {len(dependents)} files:")
                # Group by layer
                by_layer = defaultdict(list)
                for name, layer in dependents:
                    by_layer[layer].append(name)
                
                for layer in ['App', 'Core', 'Features']:
                    if layer in by_layer:
                        print(f"    {layer}: {len(by_layer[layer])} files")
                        for file in sorted(by_layer[layer])[:5]:  # Show first 5
                            print(f"      - {file}")
                        if len(by_layer[layer]) > 5:
                            print(f"      ... and {len(by_layer[layer]) - 5} more")
    
    # 3. Check for circular dependencies
    print("\n\n🔄 CIRCULAR DEPENDENCY CHECK:")
    cycles_found = False
    
    # Simple cycle detection (A -> B -> A)
    for file_a, deps_a in dependencies.items():
        for file_b in deps_a:
            if file_b in dependencies and file_a in dependencies[file_b]:
                if file_a < file_b:  # Avoid duplicate reporting
                    cycles_found = True
                    print(f"  ⚠️  {file_a} <-> {file_b}")
    
    if not cycles_found:
        print("  ✅ No direct circular dependencies found")
    
    # 4. Specific issue analysis
    print("\n\n🔍 SPECIFIC ISSUE ANALYSIS:")
    
    # Check ConflictDetailView
    if 'ConflictDetailView' in dependencies:
        print(f"\nConflictDetailView dependencies:")
        for dep in dependencies['ConflictDetailView']:
            if dep in file_locations:
                print(f"  - {dep} ({file_locations[dep]['layer']})")
    
    # Check VoiceInteractionContext usage
    voice_users = []
    for file_name, deps in dependencies.items():
        if 'VoiceInteractionContext' in deps:
            if file_name in file_locations:
                voice_users.append((file_name, file_locations[file_name]['layer']))
    
    if voice_users:
        print(f"\nVoiceInteractionContext is used by {len(voice_users)} files:")
        for user, layer in sorted(voice_users):
            print(f"  - {user} ({layer})")
    
    # 5. Navigation pattern analysis
    print("\n\n🧭 NAVIGATION PATTERN ANALYSIS:")
    nav_pattern_files = []
    
    for file_name in file_locations:
        if 'DetailView' in file_name or 'Detail' in file_name:
            nav_pattern_files.append(file_name)
    
    print(f"Found {len(nav_pattern_files)} detail views")
    print("Checking navigation patterns...")
    
    # Check if they use ID-based or object-based navigation
    for detail_view in nav_pattern_files[:5]:  # Check first 5
        if detail_view in file_locations:
            try:
                with open(file_locations[detail_view]['full_path'], 'r') as f:
                    content = f.read()
                
                # Check for ID-based pattern
                id_pattern = re.search(r'let\s+\w+Id:\s*String', content)
                object_pattern = re.search(r'let\s+\w+:\s*(?:Medication|Doctor|Supplement|MedicationConflict)\b', content)
                
                if id_pattern:
                    print(f"  ✅ {detail_view}: Uses ID-based navigation")
                elif object_pattern:
                    print(f"  ❌ {detail_view}: Uses object-based navigation (INCONSISTENT)")
                
            except:
                pass

if __name__ == '__main__':
    analyze_dependencies()