#!/usr/bin/env python3

"""
Analyze hardcoded strings in MedicationManager project
Identifies duplicates and unique strings for consolidation
"""

import os
import re
from collections import defaultdict, Counter
from pathlib import Path
import json

class StringAnalyzer:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.strings = defaultdict(list)  # string -> [(file, line_num)]
        self.string_counts = Counter()
        self.excluded_files = {
            'FirebaseManager.swift',
            'PhoneAuthView.swift',
            'AppStrings.swift',
            'AppTheme.swift',
            'AppIcons.swift'
        }
        
    def analyze_project(self):
        """Main analysis entry point"""
        print("🔍 Analyzing hardcoded strings in MedicationManager...")
        print("=" * 60)
        
        # Collect Swift files
        swift_files = self.collect_swift_files()
        print(f"Found {len(swift_files)} Swift files to analyze\n")
        
        # Extract strings from each file
        for file_path in swift_files:
            self.extract_strings(file_path)
            
        # Analyze results
        self.analyze_results()
        
    def collect_swift_files(self):
        """Collect all Swift files excluding protected ones"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git'}
        
        for root, dirs, files in os.walk(self.project_root):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift') and file not in self.excluded_files:
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def extract_strings(self, file_path):
        """Extract hardcoded strings from a Swift file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            relative_path = file_path.relative_to(self.project_root)
            
            # Pattern to match quoted strings
            string_pattern = r'"([^"]+)"'
            
            for i, line in enumerate(lines, 1):
                # Skip comments and specific patterns
                if (line.strip().startswith('//') or 
                    'AppStrings.' in line or
                    '#if DEBUG' in line or
                    'print(' in line or
                    'Logger(' in line or
                    'category:' in line or
                    'subsystem:' in line or
                    'identifier:' in line or
                    'forKey:' in line or
                    'NSLocalizedString' in line):
                    continue
                
                # Find all strings in the line
                matches = re.findall(string_pattern, line)
                for match in matches:
                    # Filter out non-UI strings
                    if (len(match) >= 2 and  # At least 2 chars
                        not match.startswith('_') and  # Not internal
                        not match.isupper() and  # Not constants
                        not match.startswith('com.') and  # Not bundle IDs
                        not match.startswith('http') and  # Not URLs
                        not match.endswith('.swift') and  # Not filenames
                        not match.endswith('.json') and  # Not filenames
                        not match.count('.') > 2 and  # Not key paths
                        not re.match(r'^[0-9]+$', match)):  # Not just numbers
                        
                        self.strings[match].append((str(relative_path), i))
                        self.string_counts[match] += 1
                        
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    def analyze_results(self):
        """Analyze and report on collected strings"""
        # Sort strings by frequency
        sorted_strings = sorted(self.string_counts.items(), key=lambda x: x[1], reverse=True)
        
        # Categorize strings
        duplicates = [(s, c) for s, c in sorted_strings if c > 1]
        unique = [(s, c) for s, c in sorted_strings if c == 1]
        
        print(f"📊 String Analysis Results:")
        print(f"Total unique strings: {len(self.string_counts)}")
        print(f"Duplicate strings: {len(duplicates)}")
        print(f"Single-use strings: {len(unique)}")
        print(f"Total string occurrences: {sum(self.string_counts.values())}")
        print()
        
        # Show top duplicates
        print("🔄 Top 20 Duplicate Strings:")
        print("-" * 60)
        for string, count in duplicates[:20]:
            print(f"{count:3d}x | {string[:50]}")
        
        # Analyze patterns
        self.analyze_patterns(sorted_strings)
        
        # Generate consolidation report
        self.generate_consolidation_report(duplicates, unique)
        
    def analyze_patterns(self, sorted_strings):
        """Analyze patterns in strings for smart consolidation"""
        print("\n📋 String Patterns Found:")
        print("-" * 60)
        
        # Common prefixes
        prefixes = defaultdict(list)
        for string, _ in sorted_strings:
            words = string.split()
            if len(words) >= 2:
                prefix = words[0]
                if len(prefix) > 2:
                    prefixes[prefix].append(string)
        
        # Show patterns that could use interpolation
        interpolation_candidates = []
        for prefix, strings in prefixes.items():
            if len(strings) >= 3:
                interpolation_candidates.append((prefix, strings))
        
        print("Candidates for string interpolation:")
        for prefix, strings in sorted(interpolation_candidates, key=lambda x: len(x[1]), reverse=True)[:10]:
            print(f"\n'{prefix}' pattern ({len(strings)} variations):")
            for s in strings[:3]:
                print(f"  - {s}")
            if len(strings) > 3:
                print(f"  ... and {len(strings) - 3} more")
        
    def generate_consolidation_report(self, duplicates, unique):
        """Generate a detailed report for string consolidation"""
        report = {
            'summary': {
                'total_unique_strings': len(self.string_counts),
                'duplicate_strings': len(duplicates),
                'single_use_strings': len(unique),
                'total_occurrences': sum(self.string_counts.values())
            },
            'duplicates': {},
            'consolidation_suggestions': {},
            'files_with_most_strings': {}
        }
        
        # Add duplicate details
        for string, count in duplicates[:50]:  # Top 50 duplicates
            locations = self.strings[string][:5]  # First 5 locations
            report['duplicates'][string] = {
                'count': count,
                'sample_locations': locations
            }
        
        # Files with most strings
        file_string_counts = Counter()
        for locations in self.strings.values():
            for file, _ in locations:
                file_string_counts[file] += 1
        
        for file, count in file_string_counts.most_common(20):
            report['files_with_most_strings'][file] = count
        
        # Save report
        with open('string-analysis-report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Detailed report saved to: string-analysis-report.json")
        
        # Generate string consolidation suggestions
        self.generate_consolidation_suggestions()
        
    def generate_consolidation_suggestions(self):
        """Generate specific suggestions for string consolidation"""
        print("\n🎯 String Consolidation Suggestions:")
        print("=" * 60)
        
        suggestions = []
        
        # 1. Error messages
        error_strings = [s for s in self.string_counts.keys() if 'error' in s.lower() or 'failed' in s.lower()]
        if error_strings:
            suggestions.append(("Error Messages", error_strings[:10]))
        
        # 2. Button titles
        button_strings = [s for s in self.string_counts.keys() if any(word in s.lower() for word in ['add', 'save', 'delete', 'cancel', 'ok', 'done', 'edit', 'update'])]
        if button_strings:
            suggestions.append(("Button Titles", button_strings[:10]))
        
        # 3. Loading/Status messages
        status_strings = [s for s in self.string_counts.keys() if any(word in s.lower() for word in ['loading', 'saving', 'updating', 'fetching', 'syncing'])]
        if status_strings:
            suggestions.append(("Status Messages", status_strings[:10]))
        
        # 4. Empty state messages
        empty_strings = [s for s in self.string_counts.keys() if any(word in s.lower() for word in ['no ', 'empty', 'none', 'not found'])]
        if empty_strings:
            suggestions.append(("Empty States", empty_strings[:10]))
        
        for category, strings in suggestions:
            print(f"\n{category}:")
            for s in strings:
                print(f"  - {s}")

def main():
    analyzer = StringAnalyzer('.')
    analyzer.analyze_project()

if __name__ == '__main__':
    main()