#!/usr/bin/env python3
"""
BMAD Coder Workspace Configuration Renderer

Renders Jinja2 templates for BMAD configuration files and AGENTS.md based on
Coder workspace parameters passed as command-line arguments.

For V6: Overwrites config.yaml files completely
For AGENTS.md: Preserves user content, updates only system-managed sections
"""

import sys
import argparse
from datetime import datetime
from pathlib import Path
from jinja2 import Environment, FileSystemLoader


class ConfigRenderer:
    """Handles rendering of BMAD configuration templates"""
    
    SKILL_LEVEL_MAP = {
        "1": "beginner",
        "2": "intermediate",
        "3": "expert"
    }
    
    def __init__(self, args):
        self.bmad_version = args.bmad_version
        self.project_root = Path(args.project_root)
        self.template_dir = Path("/usr/local/config/templates")
        
        # Initialize Jinja2 environment
        self.jinja_env = Environment(
            loader=FileSystemLoader(str(self.template_dir)),
            trim_blocks=True,
            lstrip_blocks=True
        )
        
        # Build parameters dict from arguments
        self.params = self._build_parameters(args)
    
    def _build_parameters(self, args) -> dict:
        """Build parameters dict from command-line arguments"""
        # Map numeric skill level to string
        skill_level_str = self.SKILL_LEVEL_MAP.get(str(args.user_technical_proficiency), "beginner")
        
        return {
            "user_name": args.user_name,
            "communication_language": args.communication_language,
            "document_output_language": args.document_output_language,
            "project_name": args.project_name,
            "user_skill_level": skill_level_str,
            "user_technical_proficiency": args.user_technical_proficiency,
            "target_maturity_level": args.target_maturity_level,
            "generation_date": datetime.utcnow().isoformat() + "Z"
        }
    
    def render_v6_configs(self):
        """Render and write V6 config.yaml files (always overwrite)"""
        print("📝 Rendering V6 configuration files...")
        
        config_mappings = [
            ("v6/core-config.yaml.j2", self.project_root / "_bmad" / "core" / "config.yaml"),
            ("v6/bmm-config.yaml.j2", self.project_root / "_bmad" / "bmm" / "config.yaml"),
            ("v6/memory-config.yaml.j2", self.project_root / "_bmad" / "_memory" / "config.yaml"),
        ]
        
        for template_name, output_path in config_mappings:
            try:
                template = self.jinja_env.get_template(template_name)
                rendered = template.render(**self.params)
                
                # Ensure parent directory exists
                output_path.parent.mkdir(parents=True, exist_ok=True)
                
                # Write config file (always overwrite)
                output_path.write_text(rendered, encoding="utf-8")
                print(f"  ✓ {output_path.relative_to(self.project_root)}")
                
            except Exception as e:
                print(f"  ✗ Failed to render {output_path}: {e}", file=sys.stderr)
                raise
    
    def render_agents_md(self):
        """Render AGENTS.md with section-based merging"""
        print("📝 Rendering AGENTS.md...")
        
        template_name = f"AGENTS.md.v{self.bmad_version}.j2"
        output_path = self.project_root / "AGENTS.md"
        
        try:
            template = self.jinja_env.get_template(template_name)
            new_content = template.render(**self.params)
            
            # If AGENTS.md exists, merge sections
            if output_path.exists():
                existing_content = output_path.read_text(encoding="utf-8")
                merged_content = self._merge_agents_md(existing_content, new_content)
            else:
                merged_content = new_content
            
            # Write merged content
            output_path.write_text(merged_content, encoding="utf-8")
            print("  ✓ AGENTS.md")
            
        except Exception as e:
            print(f"  ✗ Failed to render AGENTS.md: {e}", file=sys.stderr)
            raise
    
    def _merge_agents_md(self, existing: str, new: str) -> str:
        """
        Merge AGENTS.md by preserving user content while updating system sections.
        
        Strategy: Extract sections (### headers) from both files. For sections that
        exist in the new template, use the new content. For sections only in the
        existing file (user-added), preserve them.
        """
        def extract_sections(content: str) -> dict:
            """Extract sections keyed by header name"""
            sections = {}
            current_header = None
            current_content = []
            
            lines = content.split('\n')
            i = 0
            
            # Capture content before first section
            preamble = []
            while i < len(lines):
                line = lines[i]
                if line.startswith('### '):
                    break
                preamble.append(line)
                i += 1
            
            if preamble:
                sections['__PREAMBLE__'] = '\n'.join(preamble)
            
            # Extract sections
            while i < len(lines):
                line = lines[i]
                
                if line.startswith('### '):
                    # Save previous section
                    if current_header is not None:
                        sections[current_header] = '\n'.join(current_content)
                    
                    # Start new section
                    current_header = line
                    current_content = [line]
                else:
                    current_content.append(line)
                
                i += 1
            
            # Save last section
            if current_header is not None:
                sections[current_header] = '\n'.join(current_content)
            
            return sections
        
        existing_sections = extract_sections(existing)
        new_sections = extract_sections(new)
        
        # Merge: prioritize new template sections, add user-only sections at end
        merged_sections = []
        
        # Start with preamble from new template
        if '__PREAMBLE__' in new_sections:
            merged_sections.append(new_sections['__PREAMBLE__'])
        
        # Add all sections from new template (in order)
        for header, content in new_sections.items():
            if header != '__PREAMBLE__':
                merged_sections.append(content)
        
        # Add user-created sections that don't exist in new template
        for header, content in existing_sections.items():
            if header != '__PREAMBLE__' and header not in new_sections:
                merged_sections.append(content)
        
        return '\n\n'.join(merged_sections)
    
    def run(self):
        """Run the configuration rendering process"""
        print(f"🚀 BMAD Configuration Renderer (v{self.bmad_version})")
        print(f"📂 Project Root: {self.project_root}")
        print(f"👤 User: {self.params['user_name']} (skill: {self.params['user_skill_level']})")
        print(f"🎯 Target Maturity: Level {self.params['target_maturity_level']}")
        print(f"🌍 Language: {self.params['communication_language']}")
        print()
        
        try:
            # Render V6 config files (if V6)
            if self.bmad_version == "6":
                self.render_v6_configs()
            
            # Always render AGENTS.md
            self.render_agents_md()
            
            print()
            print("✅ Configuration rendering complete!")
            return 0
            
        except Exception as e:
            print()
            print(f"❌ Configuration rendering failed: {e}", file=sys.stderr)
            return 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Render BMAD configuration templates"
    )
    parser.add_argument("--bmad-version", required=True, help="BMAD version (4 or 6)")
    parser.add_argument("--project-root", required=True, help="Project root directory")
    parser.add_argument("--user-name", required=True, help="User display name")
    parser.add_argument("--communication-language", required=True, help="AI communication language")
    parser.add_argument("--document-output-language", required=True, help="Documentation language")
    parser.add_argument("--project-name", required=True, help="Project name")
    parser.add_argument("--user-technical-proficiency", type=int, required=True, help="User skill level (1-4)")
    parser.add_argument("--target-maturity-level", type=int, required=True, help="Target maturity (1-4)")
    
    args = parser.parse_args()
    renderer = ConfigRenderer(args)
    sys.exit(renderer.run())
