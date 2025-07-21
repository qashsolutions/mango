#!/usr/bin/env python3

"""
Fix style issues in MedicationManager project
- Fix naming conventions (PascalCase/camelCase)
- Remove unused imports
- Fix remaining hardcoded values
- Ensure AppTheme usage
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

class StyleFixer:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.files_updated = 0
        self.fixes_applied = defaultdict(int)
        
        # Protected files
        self.protected_files = {
            'FirebaseManager.swift',
            'PhoneAuthView.swift',
            'LoginView.swift', 
            'MedicationManagerApp.swift'
        }
        
        # System imports that are commonly used
        self.system_imports = {
            'SwiftUI', 'Foundation', 'Combine', 'UIKit', 'CoreData',
            'Firebase', 'FirebaseAuth', 'FirebaseFirestore', 'FirebaseAnalytics',
            'OSLog', 'Contacts', 'MessageUI', 'AuthenticationServices',
            'CryptoKit', 'Security', 'AVFoundation', 'Speech', 'Intents',
            'AppIntents', 'Observation', 'UserNotifications', 'GoogleSignIn',
            'Network', 'NaturalLanguage', 'IntentsUI'
        }
    
    def fix_all(self):
        """Main entry point to fix all style issues"""
        print("🎨 Fixing Style Issues...")
        print("=" * 60)
        
        # Collect Swift files
        swift_files = self.collect_swift_files()
        print(f"Found {len(swift_files)} Swift files to process\n")
        
        # Process each file
        for file_path in swift_files:
            if file_path.name not in self.protected_files:
                self.process_file(file_path)
        
        print(f"\n✅ Updated {self.files_updated} files")
        self.generate_report()
    
    def collect_swift_files(self):
        """Collect all Swift files excluding protected ones"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git', 'build'}
        
        for root, dirs, files in os.walk(self.project_root / 'MedicationManager'):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def process_file(self, file_path):
        """Process a single Swift file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Apply fixes in order
            content = self.fix_unused_imports(content, file_path)
            content = self.fix_naming_conventions(content, file_path)
            content = self.fix_remaining_hardcoded_values(content, file_path)
            content = self.fix_view_components(content, file_path)
            content = self.fix_spacing_in_code(content, file_path)
            
            # If content changed, write it back
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.files_updated += 1
                print(f"✅ Updated: {file_path.relative_to(self.project_root)}")
                
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")
    
    def fix_unused_imports(self, content, file_path):
        """Remove unused imports"""
        lines = content.split('\n')
        new_lines = []
        imports_removed = []
        
        for line in lines:
            if line.strip().startswith('import '):
                import_match = re.match(r'import\s+(\S+)', line)
                if import_match:
                    import_name = import_match.group(1)
                    
                    # Check if import is used in the file
                    # Remove the import line temporarily to check usage
                    content_without_import = '\n'.join([l for l in lines if l != line])
                    
                    # Keep system imports and those that are actually used
                    if (import_name in self.system_imports or 
                        import_name in content_without_import or
                        self.is_import_needed(import_name, content_without_import)):
                        new_lines.append(line)
                    else:
                        imports_removed.append(import_name)
                        self.fixes_applied['unused_imports_removed'] += 1
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        
        if imports_removed:
            print(f"  Removed unused imports: {', '.join(imports_removed)}")
        
        return '\n'.join(new_lines)
    
    def is_import_needed(self, import_name, content):
        """Check if an import is needed based on common patterns"""
        patterns = {
            'OSLog': ['Logger(', 'logger.'],
            'Observation': ['@Observable'],
            'FirebaseAuth': ['Auth.auth()', 'User', 'AuthCredential'],
            'FirebaseFirestore': ['Firestore.firestore()', 'DocumentSnapshot'],
            'UserNotifications': ['UNUserNotificationCenter', 'UNMutableNotificationContent'],
            'AVFoundation': ['AVAudioSession', 'AVAudioRecorder'],
            'Speech': ['SFSpeechRecognizer', 'SFSpeechRequest']
        }
        
        if import_name in patterns:
            return any(pattern in content for pattern in patterns[import_name])
        
        return False
    
    def fix_naming_conventions(self, content, file_path):
        """Fix function naming conventions"""
        # Fix ViewBuilder functions that should be camelCase
        viewbuilder_pattern = r'(@ViewBuilder\s+(?:private\s+)?func\s+)([A-Z]\w+)'
        
        def fix_viewbuilder_name(match):
            prefix = match.group(1)
            name = match.group(2)
            # Convert PascalCase to camelCase
            camel_case_name = name[0].lower() + name[1:]
            self.fixes_applied['naming_conventions_fixed'] += 1
            return prefix + camel_case_name
        
        content = re.sub(viewbuilder_pattern, fix_viewbuilder_name, content)
        
        # Fix computed property functions that look like views
        computed_pattern = r'(private\s+var\s+)([a-z]\w+):\s+some\s+View\s*{'
        
        def fix_computed_name(match):
            prefix = match.group(1)
            name = match.group(2)
            # These should stay camelCase
            return match.group(0)
        
        # Fix any remaining standalone function definitions
        func_pattern = r'(func\s+)([A-Z]\w+)(\s*\()'
        
        def fix_func_name(match):
            prefix = match.group(1)
            name = match.group(2)
            suffix = match.group(3)
            
            # Skip if it's a type name or protocol requirement
            if name in ['View', 'String', 'Int', 'Double', 'Bool']:
                return match.group(0)
            
            # Convert to camelCase
            camel_case_name = name[0].lower() + name[1:]
            self.fixes_applied['naming_conventions_fixed'] += 1
            return prefix + camel_case_name + suffix
        
        content = re.sub(func_pattern, fix_func_name, content)
        
        return content
    
    def fix_remaining_hardcoded_values(self, content, file_path):
        """Fix any remaining hardcoded values"""
        
        # Fix hardcoded opacity values
        opacity_pattern = r'\.opacity\(([0-9.]+)\)'
        
        def fix_opacity(match):
            value = float(match.group(1))
            if value == 0.0:
                return '.opacity(0)'
            elif value == 1.0:
                return '.opacity(1)'
            elif 0.1 <= value <= 0.3:
                return '.opacity(AppTheme.Opacity.low)'
            elif 0.4 <= value <= 0.6:
                return '.opacity(AppTheme.Opacity.medium)'
            elif 0.7 <= value <= 0.9:
                return '.opacity(AppTheme.Opacity.high)'
            else:
                self.fixes_applied['opacity_fixed'] += 1
                return f'.opacity({value})'  # Keep specific values
        
        content = re.sub(opacity_pattern, fix_opacity, content)
        
        # Fix hardcoded frame sizes
        frame_patterns = [
            (r'\.frame\(width:\s*(\d+),\s*height:\s*(\d+)\)', self.fix_frame_size),
            (r'\.frame\(maxWidth:\s*(\d+)\)', self.fix_max_width),
            (r'\.frame\(height:\s*(\d+)\)', self.fix_height),
        ]
        
        for pattern, fixer in frame_patterns:
            content = re.sub(pattern, fixer, content)
        
        # Fix hardcoded offsets
        offset_pattern = r'\.offset\(x:\s*(-?\d+),\s*y:\s*(-?\d+)\)'
        
        def fix_offset(match):
            x = int(match.group(1))
            y = int(match.group(2))
            
            if x == 0 and y == 0:
                return '.offset(x: 0, y: 0)'
            else:
                self.fixes_applied['offset_fixed'] += 1
                # Use spacing values for offsets
                x_val = self.map_to_spacing(abs(x))
                y_val = self.map_to_spacing(abs(y))
                x_str = f"-{x_val}" if x < 0 else x_val
                y_str = f"-{y_val}" if y < 0 else y_val
                return f'.offset(x: {x_str}, y: {y_str})'
        
        content = re.sub(offset_pattern, fix_offset, content)
        
        return content
    
    def fix_frame_size(self, match):
        """Fix frame with width and height"""
        width = int(match.group(1))
        height = int(match.group(2))
        
        # Common button/icon sizes
        if width == height:
            if width <= 24:
                self.fixes_applied['frame_fixed'] += 1
                return f'.frame(width: AppTheme.Sizing.iconSmall, height: AppTheme.Sizing.iconSmall)'
            elif width <= 44:
                self.fixes_applied['frame_fixed'] += 1
                return f'.frame(width: AppTheme.Sizing.iconMedium, height: AppTheme.Sizing.iconMedium)'
            elif width <= 64:
                self.fixes_applied['frame_fixed'] += 1
                return f'.frame(width: AppTheme.Sizing.iconLarge, height: AppTheme.Sizing.iconLarge)'
        
        return match.group(0)
    
    def fix_max_width(self, match):
        """Fix maxWidth values"""
        width = int(match.group(1))
        
        if width == 600:
            self.fixes_applied['frame_fixed'] += 1
            return '.frame(maxWidth: AppTheme.Layout.maxContentWidth)'
        elif width == 400:
            self.fixes_applied['frame_fixed'] += 1
            return '.frame(maxWidth: AppTheme.Layout.inputFieldMaxWidth)'
        
        return match.group(0)
    
    def fix_height(self, match):
        """Fix height values"""
        height = int(match.group(1))
        
        if 44 <= height <= 56:
            self.fixes_applied['frame_fixed'] += 1
            return '.frame(height: AppTheme.Layout.buttonHeight)'
        elif 60 <= height <= 80:
            self.fixes_applied['frame_fixed'] += 1
            return '.frame(height: AppTheme.Layout.navBarHeight)'
        
        return match.group(0)
    
    def map_to_spacing(self, value):
        """Map numeric value to AppTheme.Spacing"""
        if value <= 4:
            return 'AppTheme.Spacing.tiny'
        elif value <= 8:
            return 'AppTheme.Spacing.small'
        elif value <= 16:
            return 'AppTheme.Spacing.medium'
        elif value <= 24:
            return 'AppTheme.Spacing.large'
        elif value <= 32:
            return 'AppTheme.Spacing.extraLarge'
        else:
            return 'AppTheme.Spacing.huge'
    
    def fix_view_components(self, content, file_path):
        """Fix View component specific issues"""
        
        # Fix Text with hardcoded strings (only for non-debug code)
        if '#if DEBUG' not in content:
            text_pattern = r'Text\("([^"]+)"\)'
            
            def check_text(match):
                text = match.group(1)
                # Skip if it's already using AppStrings or is a format string
                if 'AppStrings' in text or '%' in text or '\\(' in text:
                    return match.group(0)
                
                # Skip single characters or numbers
                if len(text) <= 2 or text.isdigit():
                    return match.group(0)
                
                # Log for manual review
                print(f"  Found hardcoded text: \"{text}\" - needs manual AppStrings mapping")
                self.fixes_applied['hardcoded_text_found'] += 1
                return match.group(0)
            
            content = re.sub(text_pattern, check_text, content)
        
        return content
    
    def fix_spacing_in_code(self, content, file_path):
        """Fix spacing in VStack/HStack declarations"""
        
        # Fix VStack/HStack with numeric spacing
        stack_pattern = r'(VStack|HStack)\(spacing:\s*(\d+)'
        
        def fix_stack_spacing(match):
            stack_type = match.group(1)
            spacing = int(match.group(2))
            
            if spacing == 0:
                return f'{stack_type}(spacing: 0'
            else:
                spacing_val = self.map_to_spacing(spacing)
                self.fixes_applied['stack_spacing_fixed'] += 1
                return f'{stack_type}(spacing: {spacing_val}'
        
        content = re.sub(stack_pattern, fix_stack_spacing, content)
        
        return content
    
    def generate_report(self):
        """Generate a report of fixes applied"""
        print("\n📊 Style Fix Summary:")
        print("=" * 60)
        
        total_fixes = sum(self.fixes_applied.values())
        print(f"Total fixes applied: {total_fixes}")
        
        if self.fixes_applied:
            print("\nFixes by type:")
            for fix_type, count in sorted(self.fixes_applied.items()):
                print(f"  {fix_type.replace('_', ' ').title()}: {count}")
        
        print("\nRecommendations:")
        print("1. Review the changes to ensure they're correct")
        print("2. Build the project to verify no compilation errors")
        print("3. Add any missing hardcoded strings to AppStrings")
        print("4. Test UI to ensure spacing and sizing look correct")
        
        # Save report
        report = {
            'files_updated': self.files_updated,
            'total_fixes': total_fixes,
            'fixes_by_type': dict(self.fixes_applied)
        }
        
        with open('style-fixes-report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        print("\n💾 Detailed report saved to style-fixes-report.json")

def main():
    fixer = StyleFixer('.')
    fixer.fix_all()

if __name__ == '__main__':
    main()