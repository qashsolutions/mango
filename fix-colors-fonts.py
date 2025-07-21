#!/usr/bin/env python3

"""
Fix hardcoded colors and fonts in MedicationManager project
"""

import os
import re
from pathlib import Path
from collections import defaultdict

class ColorFontFixer:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.color_replacements = {}
        self.font_replacements = {}
        self.files_updated = 0
        
        # Protected files
        self.protected_files = {
            'FirebaseManager.swift',
            'PhoneAuthView.swift',
            'LoginView.swift', 
            'MedicationManagerApp.swift'
        }
        
        # Define color mappings
        self.color_mappings = {
            '.red': 'AppTheme.Colors.error',
            '.green': 'AppTheme.Colors.success',
            '.blue': 'AppTheme.Colors.primary',
            '.orange': 'AppTheme.Colors.warning',
            '.yellow': 'AppTheme.Colors.warning',
            '.gray': 'AppTheme.Colors.onSurface.opacity(0.6)',
            '.black': 'AppTheme.Colors.onBackground',
            '.white': 'AppTheme.Colors.background',
            '.purple': 'AppTheme.Colors.secondary',
            '.pink': 'AppTheme.Colors.accent',
            'Color.red': 'AppTheme.Colors.error',
            'Color.green': 'AppTheme.Colors.success',
            'Color.blue': 'AppTheme.Colors.primary',
            'Color.orange': 'AppTheme.Colors.warning',
            'Color.yellow': 'AppTheme.Colors.warning',
            'Color.gray': 'AppTheme.Colors.onSurface.opacity(0.6)',
            'Color.black': 'AppTheme.Colors.onBackground',
            'Color.white': 'AppTheme.Colors.background',
            'Color.purple': 'AppTheme.Colors.secondary',
            'Color.pink': 'AppTheme.Colors.accent',
            '.primary': 'AppTheme.Colors.primary',
            '.secondary': 'AppTheme.Colors.onSurface.opacity(0.6)',
            'Color.primary': 'AppTheme.Colors.primary',
            'Color.secondary': 'AppTheme.Colors.onSurface.opacity(0.6)',
        }
        
        # Define font mappings
        self.font_patterns = [
            (r'\.font\(\.system\(size:\s*(\d+)\)\)', self.map_font_size),
            (r'\.font\(\.system\(size:\s*(\d+),\s*weight:\s*\.(\w+)\)\)', self.map_font_size_weight),
            (r'\.font\(\.largeTitle\)', '.font(AppTheme.Typography.largeTitle)'),
            (r'\.font\(\.title\)', '.font(AppTheme.Typography.title)'),
            (r'\.font\(\.title2\)', '.font(AppTheme.Typography.title)'),
            (r'\.font\(\.title3\)', '.font(AppTheme.Typography.title)'),
            (r'\.font\(\.headline\)', '.font(AppTheme.Typography.headline)'),
            (r'\.font\(\.body\)', '.font(AppTheme.Typography.body)'),
            (r'\.font\(\.callout\)', '.font(AppTheme.Typography.callout)'),
            (r'\.font\(\.subheadline\)', '.font(AppTheme.Typography.subheadline)'),
            (r'\.font\(\.footnote\)', '.font(AppTheme.Typography.footnote)'),
            (r'\.font\(\.caption\)', '.font(AppTheme.Typography.caption)'),
            (r'\.font\(\.caption2\)', '.font(AppTheme.Typography.caption)'),
        ]
        
        # Padding/spacing mappings
        self.spacing_mappings = {
            '4': 'AppTheme.Spacing.tiny',
            '8': 'AppTheme.Spacing.small',
            '12': 'AppTheme.Spacing.small',
            '16': 'AppTheme.Spacing.medium',
            '20': 'AppTheme.Spacing.medium',
            '24': 'AppTheme.Spacing.large',
            '32': 'AppTheme.Spacing.extraLarge',
            '40': 'AppTheme.Spacing.extraLarge',
            '48': 'AppTheme.Spacing.huge',
            '0': '0',  # Keep 0 as is
        }
        
    def fix_all(self):
        """Main entry point to fix all colors and fonts"""
        print("🎨 Fixing Hardcoded Colors and Fonts...")
        print("=" * 60)
        
        # Collect Swift files
        swift_files = self.collect_swift_files()
        print(f"Found {len(swift_files)} Swift files to process\n")
        
        # Process each file
        for file_path in swift_files:
            self.process_file(file_path)
            
        print(f"\n✅ Updated {self.files_updated} files")
        self.generate_report()
        
    def collect_swift_files(self):
        """Collect all Swift files excluding protected ones"""
        swift_files = []
        exclude_dirs = {'DerivedData', '.build', 'Pods', '.git'}
        
        for root, dirs, files in os.walk(self.project_root / 'MedicationManager'):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file.endswith('.swift') and file not in self.protected_files:
                    swift_files.append(Path(root) / file)
                    
        return sorted(swift_files)
    
    def process_file(self, file_path):
        """Process a single Swift file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix colors
            content = self.fix_colors(content, file_path)
            
            # Fix fonts
            content = self.fix_fonts(content, file_path)
            
            # Fix padding/spacing
            content = self.fix_spacing(content, file_path)
            
            # Fix corner radius
            content = self.fix_corner_radius(content, file_path)
            
            # If content changed, write it back
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                self.files_updated += 1
                print(f"✅ Updated: {file_path.relative_to(self.project_root)}")
                
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")
    
    def fix_colors(self, content, file_path):
        """Fix hardcoded colors"""
        for old_color, new_color in self.color_mappings.items():
            # Skip if already using AppTheme
            if 'AppTheme.Colors' in content:
                # Only replace if not already preceded by AppTheme
                pattern = rf'(?<!AppTheme\.Colors){re.escape(old_color)}\b'
                content = re.sub(pattern, new_color, content)
            else:
                content = content.replace(old_color, new_color)
        
        # Fix foregroundColor
        content = re.sub(r'\.foregroundColor\(\.(\w+)\)', 
                        lambda m: f'.foregroundStyle(AppTheme.Colors.{self.map_color_name(m.group(1))})', 
                        content)
        
        # Fix background colors
        content = re.sub(r'\.background\(Color\.(\w+)\)', 
                        lambda m: f'.background(AppTheme.Colors.{self.map_color_name(m.group(1))})', 
                        content)
        
        return content
    
    def map_color_name(self, color_name):
        """Map color names to AppTheme color names"""
        color_map = {
            'red': 'error',
            'green': 'success',
            'blue': 'primary',
            'orange': 'warning',
            'yellow': 'warning',
            'gray': 'onSurface.opacity(0.6)',
            'black': 'onBackground',
            'white': 'background',
            'purple': 'secondary',
            'pink': 'accent',
            'clear': 'clear'
        }
        return color_map.get(color_name, color_name)
    
    def fix_fonts(self, content, file_path):
        """Fix hardcoded fonts"""
        for pattern, replacement in self.font_patterns:
            if callable(replacement):
                content = re.sub(pattern, replacement, content)
            else:
                content = re.sub(pattern, replacement, content)
        
        return content
    
    def map_font_size(self, match):
        """Map font size to typography"""
        size = int(match.group(1))
        
        if size <= 12:
            return '.font(AppTheme.Typography.caption)'
        elif size <= 14:
            return '.font(AppTheme.Typography.footnote)'
        elif size <= 16:
            return '.font(AppTheme.Typography.body)'
        elif size <= 18:
            return '.font(AppTheme.Typography.callout)'
        elif size <= 20:
            return '.font(AppTheme.Typography.headline)'
        elif size <= 24:
            return '.font(AppTheme.Typography.title)'
        else:
            return '.font(AppTheme.Typography.largeTitle)'
    
    def map_font_size_weight(self, match):
        """Map font with size and weight to typography"""
        size = int(match.group(1))
        weight = match.group(2)
        
        if weight in ['bold', 'semibold', 'heavy']:
            if size <= 16:
                return '.font(AppTheme.Typography.headline)'
            elif size <= 20:
                return '.font(AppTheme.Typography.title)'
            else:
                return '.font(AppTheme.Typography.largeTitle)'
        else:
            return self.map_font_size(match)
    
    def fix_spacing(self, content, file_path):
        """Fix hardcoded padding and spacing"""
        # Fix padding
        for value, spacing in self.spacing_mappings.items():
            content = re.sub(rf'\.padding\({value}\)', f'.padding({spacing})', content)
            content = re.sub(rf'\.padding\(\.all,\s*{value}\)', f'.padding(.all, {spacing})', content)
            content = re.sub(rf'\.padding\(\.horizontal,\s*{value}\)', f'.padding(.horizontal, {spacing})', content)
            content = re.sub(rf'\.padding\(\.vertical,\s*{value}\)', f'.padding(.vertical, {spacing})', content)
            content = re.sub(rf'\.padding\(\.top,\s*{value}\)', f'.padding(.top, {spacing})', content)
            content = re.sub(rf'\.padding\(\.bottom,\s*{value}\)', f'.padding(.bottom, {spacing})', content)
            content = re.sub(rf'\.padding\(\.leading,\s*{value}\)', f'.padding(.leading, {spacing})', content)
            content = re.sub(rf'\.padding\(\.trailing,\s*{value}\)', f'.padding(.trailing, {spacing})', content)
        
        # Fix spacing in VStack/HStack
        for value, spacing in self.spacing_mappings.items():
            content = re.sub(rf'spacing:\s*{value}', f'spacing: {spacing}', content)
        
        return content
    
    def fix_corner_radius(self, content, file_path):
        """Fix hardcoded corner radius"""
        corner_radius_map = {
            '4': 'AppTheme.CornerRadius.small',
            '8': 'AppTheme.CornerRadius.medium',
            '12': 'AppTheme.CornerRadius.large',
            '16': 'AppTheme.CornerRadius.extraLarge',
            '20': 'AppTheme.CornerRadius.extraLarge',
            '24': 'AppTheme.CornerRadius.huge',
            '0': '0',  # Keep 0 as is
        }
        
        for value, radius in corner_radius_map.items():
            content = re.sub(rf'\.cornerRadius\({value}\)', f'.cornerRadius({radius})', content)
        
        return content
    
    def generate_report(self):
        """Generate a report of changes"""
        print("\n📊 Fix Summary:")
        print("=" * 60)
        print(f"Files updated: {self.files_updated}")
        print("\nRecommendations:")
        print("1. Review the changes to ensure they look correct")
        print("2. Build and test the app thoroughly")
        print("3. Check that all UI elements still appear as expected")
        print("4. Consider adding any missing color/font definitions to AppTheme")

def main():
    fixer = ColorFontFixer('.')
    fixer.fix_all()

if __name__ == '__main__':
    main()