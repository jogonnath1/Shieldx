report_path = r"f:\Shieldx\ShieldX_Project_Report.tex"

with open(report_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

print("--- Checking \includegraphics lines ---")
for idx, line in enumerate(lines):
    if "includegraphics" in line:
        print(f"Line {idx+1}: {repr(line)}")

print("\n--- Checking Screenshot section ---")
start_checking = False
counter = 0
for idx, line in enumerate(lines):
    if "Screenshot" in line:
        start_checking = True
    if start_checking:
        print(f"Line {idx+1}: {repr(line)}")
        counter += 1
        if counter > 15:
            break
