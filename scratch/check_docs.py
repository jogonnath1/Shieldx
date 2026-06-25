import os
import re
import glob

def get_all_dart_files(root_dir):
    dart_files = set()
    for dirpath, _, filenames in os.walk(root_dir):
        for f in filenames:
            if f.endswith('.dart'):
                dart_files.add(f)
    return dart_files

def get_documented_files(docs_dir):
    documented = set()
    md_files = glob.glob(os.path.join(docs_dir, '*.md'))
    
    pattern = re.compile(r'([a-zA-Z0-9_]+\.dart)')
    
    for md_file in md_files:
        with open(md_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            matches = pattern.findall(content)
            for m in matches:
                documented.add(m)
    return documented

def main():
    lib_dir = 'lib'
    docs_dir = 'Project Documentations'
    
    actual_files = get_all_dart_files(lib_dir)
    documented_files = get_documented_files(docs_dir)
    
    undocumented = actual_files - documented_files
    
    print(f"Total Dart files in lib: {len(actual_files)}")
    print(f"Total documented Dart files (by filename): {len(documented_files.intersection(actual_files))}")
    print(f"\n--- Undocumented Files ({len(undocumented)}) ---")
    for f in sorted(undocumented):
        print(f)

if __name__ == '__main__':
    main()
