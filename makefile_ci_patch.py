import sys
import re

if len(sys.argv) != 2:
    print("Usage: python makefile_ci_patch.py <path_to_official_Makefile>")
    sys.exit(1)

src_path = sys.argv[1]
dst_path = "Makefile.ci"

with open(src_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

output_lines = []
inside_path_check = False
for line in lines:
    # Remove path metacharacter check block
    if 'METACHARACTERS' in line:
        inside_path_check = True
        continue
    if inside_path_check:
        if line.strip().startswith('endif'):
            inside_path_check = False
        continue
    # Remove lines with 'cowardly refusing to build' errors
    if 'cowardly refusing to build' in line:
        continue
    # Fix python -c quoting (only if not already quoted)
    pyc_match = re.search(r'python -c ([^"\
][^\n]*)', line)
    if pyc_match:
        code = pyc_match.group(1).strip()
        # Only add quotes if not already present
        if not code.startswith('"') and not code.startswith("'"):
            quoted = f'python -c "{code}"'
            line = re.sub(r'python -c [^"\
][^\n]*', quoted, line)
    output_lines.append(line)

with open(dst_path, "w", encoding="utf-8") as f:
    f.writelines(output_lines)

print(f"Patched Makefile written to {dst_path}") 