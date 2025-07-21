#!/usr/bin/env python3

"""
Consolidate duplicate strings and update files with AppStrings references
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

class StringConsolidator:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.replacements = {}
        self.new_app_strings = defaultdict(dict)  # category -> {key: value}
        
        # Load analysis report
        with open('string-analysis-report.json', 'r') as f:
            self.analysis = json.load(f)
            
        # Protected files that should not be modified
        self.protected_files = {
            'FirebaseManager.swift',
            'PhoneAuthView.swift',
            'LoginView.swift',
            'MedicationManagerApp.swift'
        }
        
    def consolidate(self):
        """Main consolidation process"""
        print("🔄 Starting String Consolidation Process...")
        print("=" * 60)
        
        # 1. Process duplicates first
        self.process_duplicates()
        
        # 2. Process patterns for interpolation
        self.process_patterns()
        
        # 3. Create common strings
        self.create_common_strings()
        
        # 4. Generate AppStrings additions
        self.generate_app_strings()
        
        # 5. Update source files
        self.update_source_files()
        
    def process_duplicates(self):
        """Process duplicate strings"""
        print("\n📋 Processing Duplicate Strings...")
        
        duplicates = self.analysis['duplicates']
        
        # Common button/action strings
        button_mappings = {
            "Save": "AppStrings.Common.save",
            "Cancel": "AppStrings.Common.cancel",
            "Delete": "AppStrings.Common.delete",
            "OK": "AppStrings.Common.ok",
            "Done": "AppStrings.Common.done",
            "Edit": "AppStrings.Common.edit",
            "Add": "AppStrings.Common.add",
            "Update": "AppStrings.Common.update",
            "Close": "AppStrings.Common.close",
            "Continue": "AppStrings.Common.continue",
            "Back": "AppStrings.Common.back",
            "Next": "AppStrings.Common.next",
            "Submit": "AppStrings.Common.submit",
            "Confirm": "AppStrings.Common.confirm"
        }
        
        # Add to replacements
        for string, app_string in button_mappings.items():
            if string in duplicates or string.lower() in duplicates:
                self.replacements[f'"{string}"'] = app_string
                self.new_app_strings['Common'][string.lower()] = string
        
        # Common status messages
        status_mappings = {
            "Loading...": "AppStrings.Common.loading",
            "Saving...": "AppStrings.Common.saving",
            "Updating...": "AppStrings.Common.updating",
            "Syncing...": "AppStrings.Common.syncing",
            "Please wait...": "AppStrings.Common.pleaseWait",
            "Processing...": "AppStrings.Common.processing"
        }
        
        for string, app_string in status_mappings.items():
            if string in duplicates or string.replace("...", "") in duplicates:
                self.replacements[f'"{string}"'] = app_string
                self.new_app_strings['Common'][app_string.split('.')[-1]] = string
                
        print(f"Identified {len(self.replacements)} direct replacements")
        
    def process_patterns(self):
        """Process string patterns for interpolation"""
        print("\n🔧 Processing String Patterns for Interpolation...")
        
        # Error message patterns
        error_patterns = [
            (r'"Failed to (.+)"', 'AppStrings.ErrorMessages.failedTo(_:)'),
            (r'"Unable to (.+)"', 'AppStrings.ErrorMessages.unableTo(_:)'),
            (r'"An error occurred (.+)"', 'AppStrings.ErrorMessages.errorOccurred(_:)'),
            (r'"Please (.+)"', 'AppStrings.Common.please(_:)')
        ]
        
        # Empty state patterns
        empty_patterns = [
            (r'"No (.+) found"', 'AppStrings.EmptyStates.noItemsFound(_:)'),
            (r'"You have no (.+)"', 'AppStrings.EmptyStates.youHaveNo(_:)'),
        ]
        
        # Success message patterns
        success_patterns = [
            (r'"(.+) added successfully"', 'AppStrings.Success.itemAdded(_:)'),
            (r'"(.+) saved successfully"', 'AppStrings.Success.itemSaved(_:)'),
            (r'"(.+) deleted successfully"', 'AppStrings.Success.itemDeleted(_:)'),
        ]
        
        # Store pattern replacements for later
        self.patterns = error_patterns + empty_patterns + success_patterns
        
    def create_common_strings(self):
        """Create CommonStrings structure"""
        print("\n📝 Creating Common Strings Structure...")
        
        common_strings = {
            # Actions
            "save": "Save",
            "cancel": "Cancel",
            "delete": "Delete",
            "ok": "OK",
            "done": "Done",
            "edit": "Edit",
            "add": "Add",
            "update": "Update",
            "close": "Close",
            "continue": "Continue",
            "back": "Back",
            "next": "Next",
            "submit": "Submit",
            "confirm": "Confirm",
            "retry": "Retry",
            "refresh": "Refresh",
            
            # Status
            "loading": "Loading...",
            "saving": "Saving...",
            "updating": "Updating...",
            "syncing": "Syncing...",
            "pleaseWait": "Please wait...",
            "processing": "Processing...",
            
            # Common UI
            "yes": "Yes",
            "no": "No",
            "all": "All",
            "none": "None",
            "select": "Select",
            "selected": "Selected",
            "search": "Search",
            "filter": "Filter",
            "sort": "Sort",
            
            # Time
            "today": "Today",
            "yesterday": "Yesterday",
            "tomorrow": "Tomorrow",
            "daily": "Daily",
            "weekly": "Weekly",
            "monthly": "Monthly",
            
            # Measurements
            "mg": "mg",
            "mcg": "mcg",
            "ml": "ml",
            "tablets": "tablets",
            "capsules": "capsules",
            
            # Frequencies
            "asNeeded": "As needed",
            "onceDaily": "Once daily",
            "twiceDaily": "Twice daily",
            "threeTimesDaily": "Three times daily",
            "fourTimesDaily": "Four times daily"
        }
        
        self.new_app_strings['Common'].update(common_strings)
        
    def generate_app_strings(self):
        """Generate new AppStrings entries"""
        print("\n📄 Generating AppStrings additions...")
        
        # Create CommonStrings.swift
        common_strings_content = """import Foundation

// MARK: - Common Strings used across the app
extension AppStrings {
    struct Common {
"""
        
        # Add common strings
        for key, value in sorted(self.new_app_strings['Common'].items()):
            common_strings_content += f'        static let {key} = NSLocalizedString("common.{key}", value: "{value}", comment: "{value}")\n'
        
        # Add interpolated string functions
        common_strings_content += """
        
        // MARK: - Interpolated Strings
        static func please(_ action: String) -> String {
            String(format: NSLocalizedString("common.please", value: "Please %@", comment: "Please do something"), action)
        }
    }
    
    struct EmptyStates {
        static func noItemsFound(_ items: String) -> String {
            String(format: NSLocalizedString("empty.noItemsFound", value: "No %@ found", comment: "No items found"), items)
        }
        
        static func youHaveNo(_ items: String) -> String {
            String(format: NSLocalizedString("empty.youHaveNo", value: "You have no %@", comment: "You have no items"), items)
        }
    }
    
    struct Success {
        static func itemAdded(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemAdded", value: "%@ added successfully", comment: "Item added"), item)
        }
        
        static func itemSaved(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemSaved", value: "%@ saved successfully", comment: "Item saved"), item)
        }
        
        static func itemDeleted(_ item: String) -> String {
            String(format: NSLocalizedString("success.itemDeleted", value: "%@ deleted successfully", comment: "Item deleted"), item)
        }
    }
}

// MARK: - Error Messages Extension
extension AppStrings.ErrorMessages {
    static func failedTo(_ action: String) -> String {
        String(format: NSLocalizedString("error.failedTo", value: "Failed to %@", comment: "Failed to do something"), action)
    }
    
    static func unableTo(_ action: String) -> String {
        String(format: NSLocalizedString("error.unableTo", value: "Unable to %@", comment: "Unable to do something"), action)
    }
    
    static func errorOccurred(_ context: String) -> String {
        String(format: NSLocalizedString("error.occurred", value: "An error occurred %@", comment: "Error occurred"), context)
    }
}
"""
        
        # Save CommonStrings.swift
        with open(self.project_root / 'MedicationManager' / 'Core' / 'Configuration' / 'CommonStrings.swift', 'w') as f:
            f.write(common_strings_content)
        
        print("✅ Created CommonStrings.swift")
        
    def update_source_files(self):
        """Update source files with AppStrings references"""
        print("\n🔄 Updating source files...")
        
        updated_count = 0
        
        # Process each Swift file
        swift_files = []
        for root, dirs, files in os.walk(self.project_root / 'MedicationManager'):
            for file in files:
                if file.endswith('.swift') and file not in self.protected_files:
                    swift_files.append(Path(root) / file)
        
        for file_path in swift_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Apply direct replacements
                for old_string, new_string in self.replacements.items():
                    content = content.replace(old_string, new_string)
                
                # Apply pattern replacements
                for pattern, replacement in self.patterns:
                    def replace_func(match):
                        captured = match.group(1)
                        return f'{replacement}("{captured}")'
                    
                    content = re.sub(pattern, replace_func, content)
                
                # If content changed, write it back
                if content != original_content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    updated_count += 1
                    print(f"✅ Updated: {file_path.relative_to(self.project_root)}")
                    
            except Exception as e:
                print(f"❌ Error updating {file_path}: {e}")
        
        print(f"\n✅ Updated {updated_count} files")

def main():
    consolidator = StringConsolidator('.')
    consolidator.consolidate()
    
    print("\n🎯 Next Steps:")
    print("1. Review CommonStrings.swift")
    print("2. Run the AppTheme color and font consolidation")
    print("3. Test the app to ensure all strings work correctly")
    print("4. Consider further categorization of remaining unique strings")

if __name__ == '__main__':
    main()