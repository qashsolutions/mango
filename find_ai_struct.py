#!/usr/bin/env python3
import re

def find_ai_struct(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    # Find struct AI
    in_ai_struct = False
    ai_struct_lines = []
    brace_count = 0
    
    for i, line in enumerate(lines):
        if 'struct AI' in line and '{' in line:
            in_ai_struct = True
            brace_count = 1
            ai_struct_lines.append((i+1, line.rstrip()))
        elif in_ai_struct:
            ai_struct_lines.append((i+1, line.rstrip()))
            brace_count += line.count('{') - line.count('}')
            if brace_count == 0:
                in_ai_struct = False
                print("AI struct found:")
                for line_num, content in ai_struct_lines:
                    print(f"{line_num}: {content}")
                break
    
    # Find analyzingMedications
    print("\n\nSearching for 'analyzingMedications':")
    for i, line in enumerate(lines):
        if 'analyzingMedications' in line:
            print(f"Line {i+1}: {line.strip()}")

if __name__ == "__main__":
    find_ai_struct("/Users/cvr/Documents/Project/MedicationManager/MedicationManager/Core/Configuration/AppStrings.swift")