#!/usr/bin/env python3

"""
Cross-file dependency and integration checker for MedicationManager
Analyzes how files work together and checks integration points
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict, deque
import networkx as nx
import matplotlib.pyplot as plt

class CrossDependencyChecker:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.dependency_graph = nx.DiGraph()
        self.api_calls = defaultdict(list)
        self.shared_state = defaultdict(list)
        self.navigation_flows = []
        self.data_flows = []
        self.integration_issues = []
        
    def analyze(self):
        """Main analysis entry point"""
        print("🔗 Cross-File Dependency Analysis")
        print("=" * 60)
        
        # Build dependency graph
        self.build_dependency_graph()
        
        # Analyze different aspects
        self.analyze_api_integration()
        self.analyze_state_management()
        self.analyze_navigation_flow()
        self.analyze_data_flow()
        self.check_singleton_usage()
        self.check_protocol_implementations()
        
        # Generate reports
        self.generate_dependency_report()
        self.visualize_dependencies()
        
    def build_dependency_graph(self):
        """Build a graph of file dependencies"""
        swift_files = self.collect_swift_files()
        
        for file_path in swift_files:
            file_name = file_path.stem
            self.dependency_graph.add_node(file_name, path=str(file_path))
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find dependencies through various patterns
                
                # Direct type usage
                types_used = re.findall(r'(?:let|var|:)\s+(\w+)(?:<|\s|$)', content)
                for type_name in types_used:
                    if self.is_project_type(type_name):
                        self.dependency_graph.add_edge(file_name, type_name)
                
                # Function calls
                func_calls = re.findall(r'(\w+)\.(shared|manager|default)', content)
                for manager in func_calls:
                    if self.is_project_type(manager):
                        self.dependency_graph.add_edge(file_name, manager)
                
                # Protocol conformance
                conformances = re.findall(r':\s*([^{]+)\s*{', content)
                for conformance_list in conformances:
                    protocols = [p.strip() for p in conformance_list.split(',')]
                    for protocol in protocols:
                        if self.is_project_type(protocol):
                            self.dependency_graph.add_edge(file_name, protocol)
                            
            except Exception as e:
                print(f"Error analyzing {file_path}: {e}")
    
    def is_project_type(self, type_name):
        """Check if type belongs to project"""
        system_types = {
            'String', 'Int', 'Double', 'Bool', 'Date', 'URL', 'Data',
            'Array', 'Dictionary', 'Set', 'Optional', 'Result',
            'View', 'Text', 'Button', 'VStack', 'HStack', 'ZStack',
            'ObservableObject', 'Published', 'State', 'Binding'
        }
        return type_name not in system_types and type_name[0].isupper()
    
    def analyze_api_integration(self):
        """Analyze API integration points"""
        print("\n🌐 Analyzing API Integration...")
        
        api_files = [
            'FirebaseManager.swift',
            'ClaudeAIClient.swift',
            'CoreDataManager.swift',
            'DataSyncManager.swift'
        ]
        
        for file_name in api_files:
            users = list(self.dependency_graph.predecessors(file_name.replace('.swift', '')))
            if users:
                self.api_calls[file_name] = users
                print(f"  {file_name} is used by {len(users)} files")
    
    def analyze_state_management(self):
        """Analyze shared state and data flow"""
        print("\n🔄 Analyzing State Management...")
        
        # Find all ViewModels
        viewmodels = [node for node in self.dependency_graph.nodes() if 'ViewModel' in node]
        
        for vm in viewmodels:
            # Find which views use this ViewModel
            views = [node for node in self.dependency_graph.predecessors(vm) if 'View' in node]
            if views:
                self.shared_state[vm] = views
                print(f"  {vm} manages state for {len(views)} views")
        
        # Check for state sharing violations
        for vm in viewmodels:
            users = list(self.dependency_graph.predecessors(vm))
            non_view_users = [u for u in users if 'View' not in u and u != vm]
            if non_view_users:
                self.integration_issues.append({
                    'type': 'state_sharing_violation',
                    'viewmodel': vm,
                    'improper_users': non_view_users
                })
    
    def analyze_navigation_flow(self):
        """Analyze navigation patterns"""
        print("\n🧭 Analyzing Navigation Flow...")
        
        nav_patterns = [
            (r'NavigationLink.*destination:\s*(\w+)', 'NavigationLink'),
            (r'\.sheet.*content:.*\{.*(\w+View)', 'Sheet'),
            (r'\.fullScreenCover.*content:.*\{.*(\w+View)', 'FullScreenCover'),
            (r'\.navigate\(to:\s*\.(\w+)', 'Programmatic')
        ]
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                source = file_path.stem
                
                for pattern, nav_type in nav_patterns:
                    destinations = re.findall(pattern, content)
                    for dest in destinations:
                        self.navigation_flows.append({
                            'source': source,
                            'destination': dest,
                            'type': nav_type
                        })
                        
            except:
                pass
        
        print(f"  Found {len(self.navigation_flows)} navigation connections")
    
    def analyze_data_flow(self):
        """Analyze data flow patterns"""
        print("\n📊 Analyzing Data Flow...")
        
        # Track data flow from models to views
        models = [node for node in self.dependency_graph.nodes() if 'Model' in node and 'ViewModel' not in node]
        
        for model in models:
            # Find path to views
            paths_to_views = []
            views = [node for node in self.dependency_graph.nodes() if 'View' in node and 'Model' not in node]
            
            for view in views:
                try:
                    paths = list(nx.all_simple_paths(self.dependency_graph, model, view, cutoff=4))
                    if paths:
                        paths_to_views.extend(paths)
                except:
                    pass
            
            if paths_to_views:
                self.data_flows.append({
                    'model': model,
                    'view_paths': len(paths_to_views),
                    'sample_path': paths_to_views[0] if paths_to_views else []
                })
        
        print(f"  Analyzed {len(self.data_flows)} model-to-view data flows")
    
    def check_singleton_usage(self):
        """Check singleton pattern usage"""
        print("\n🔐 Checking Singleton Usage...")
        
        singletons = []
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find singleton patterns
                if 'static let shared' in content or 'static var shared' in content:
                    class_name = re.search(r'(?:class|struct)\s+(\w+)', content)
                    if class_name:
                        singletons.append(class_name.group(1))
                        
            except:
                pass
        
        print(f"  Found {len(singletons)} singletons: {', '.join(singletons)}")
        
        # Check for proper singleton usage
        for singleton in singletons:
            users = list(self.dependency_graph.predecessors(singleton))
            if len(users) > 10:
                self.integration_issues.append({
                    'type': 'excessive_singleton_usage',
                    'singleton': singleton,
                    'user_count': len(users)
                })
    
    def check_protocol_implementations(self):
        """Check protocol implementations across files"""
        print("\n🔌 Checking Protocol Implementations...")
        
        protocols = {}
        implementations = defaultdict(list)
        
        for file_path in self.collect_swift_files():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Find protocol definitions
                protocol_defs = re.findall(r'protocol\s+(\w+)\s*(?::\s*[^{]+)?\s*{([^}]+)}', content, re.DOTALL)
                for name, body in protocol_defs:
                    required_methods = re.findall(r'func\s+(\w+)', body)
                    protocols[name] = required_methods
                
                # Find implementations
                for prot_name in protocols:
                    if f': {prot_name}' in content or f', {prot_name}' in content:
                        implementations[prot_name].append(file_path.stem)
                        
            except:
                pass
        
        # Check for protocols without implementations
        for protocol, implementers in implementations.items():
            if not implementers:
                self.integration_issues.append({
                    'type': 'unimplemented_protocol',
                    'protocol': protocol
                })
            print(f"  {protocol}: {len(implementers)} implementations")
    
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
    
    def generate_dependency_report(self):
        """Generate comprehensive dependency report"""
        print("\n" + "=" * 60)
        print("📊 DEPENDENCY ANALYSIS REPORT")
        print("=" * 60)
        
        # Basic stats
        print(f"\n📈 Statistics:")
        print(f"  Total files: {self.dependency_graph.number_of_nodes()}")
        print(f"  Total dependencies: {self.dependency_graph.number_of_edges()}")
        print(f"  Average dependencies per file: {self.dependency_graph.number_of_edges() / max(1, self.dependency_graph.number_of_nodes()):.1f}")
        
        # Most dependent files
        print(f"\n🎯 Most Depended Upon (Top 5):")
        in_degrees = dict(self.dependency_graph.in_degree())
        top_deps = sorted(in_degrees.items(), key=lambda x: x[1], reverse=True)[:5]
        for file, count in top_deps:
            print(f"  {file}: {count} dependents")
        
        # Most dependent files
        print(f"\n🔗 Most Dependencies (Top 5):")
        out_degrees = dict(self.dependency_graph.out_degree())
        top_users = sorted(out_degrees.items(), key=lambda x: x[1], reverse=True)[:5]
        for file, count in top_users:
            print(f"  {file}: {count} dependencies")
        
        # Circular dependencies
        print(f"\n🔄 Circular Dependencies:")
        try:
            cycles = list(nx.simple_cycles(self.dependency_graph))
            if cycles:
                for cycle in cycles[:5]:
                    print(f"  {' -> '.join(cycle)} -> {cycle[0]}")
            else:
                print("  ✅ No circular dependencies found")
        except:
            print("  ⚠️  Could not check for cycles")
        
        # Integration issues
        if self.integration_issues:
            print(f"\n⚠️  Integration Issues ({len(self.integration_issues)}):")
            for issue in self.integration_issues[:5]:
                print(f"  {issue['type']}: {issue}")
        
        # Save detailed report
        report = {
            'nodes': list(self.dependency_graph.nodes()),
            'edges': list(self.dependency_graph.edges()),
            'api_calls': dict(self.api_calls),
            'shared_state': dict(self.shared_state),
            'navigation_flows': self.navigation_flows,
            'data_flows': self.data_flows,
            'integration_issues': self.integration_issues
        }
        
        with open('cross-dependency-report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        print("\n💾 Detailed report saved to cross-dependency-report.json")
    
    def visualize_dependencies(self):
        """Create dependency visualization"""
        try:
            plt.figure(figsize=(20, 16))
            
            # Create layout
            pos = nx.spring_layout(self.dependency_graph, k=3, iterations=50)
            
            # Color nodes by type
            node_colors = []
            for node in self.dependency_graph.nodes():
                if 'View' in node and 'Model' not in node:
                    node_colors.append('lightblue')
                elif 'ViewModel' in node:
                    node_colors.append('lightgreen')
                elif 'Model' in node:
                    node_colors.append('lightyellow')
                elif 'Manager' in node:
                    node_colors.append('lightcoral')
                else:
                    node_colors.append('lightgray')
            
            # Draw
            nx.draw(self.dependency_graph, pos,
                    node_color=node_colors,
                    node_size=1000,
                    with_labels=True,
                    font_size=8,
                    font_weight='bold',
                    arrows=True,
                    edge_color='gray',
                    alpha=0.7)
            
            plt.title("MedicationManager Dependency Graph", fontsize=16)
            plt.axis('off')
            plt.tight_layout()
            plt.savefig('dependency-graph.png', dpi=150, bbox_inches='tight')
            print("\n📊 Dependency graph saved to dependency-graph.png")
            
        except Exception as e:
            print(f"\n⚠️  Could not create visualization: {e}")
            print("  Install matplotlib and networkx: pip install matplotlib networkx")

def main():
    checker = CrossDependencyChecker('.')
    checker.analyze()

if __name__ == '__main__':
    main()