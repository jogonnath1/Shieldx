import os
import shutil
import subprocess
import zipfile

workspace = r"f:\Shieldx"
diagrams_dir = os.path.join(workspace, "diagrams")
rendered_dir = os.path.join(diagrams_dir, "rendered")
report_path = os.path.join(workspace, "ShieldX_Project_Report.tex")
zip_path = os.path.join(workspace, "ShieldX_Defense_Package.zip")

# Source paths of generated screenshots from the Gemini brain directory
brain_dir = r"C:\Users\Jogon\.gemini\antigravity\brain\d3e0e1fc-6bbd-4fa4-8f8b-aaead1da293b"
screenshots_src = {
    "screenshot_citizen_home.png": os.path.join(brain_dir, "screenshot_citizen_home_1781865331726.png"),
    "screenshot_complaint_form.png": os.path.join(brain_dir, "screenshot_complaint_form_1781865354342.png"),
    "screenshot_admin_dashboard.png": os.path.join(brain_dir, "screenshot_admin_dashboard_1781865382152.png")
}

print("Copying generated UI screenshots...")
os.makedirs(rendered_dir, exist_ok=True)
for filename, src_path in screenshots_src.items():
    dest_path = os.path.join(rendered_dir, filename)
    print(f"Copying {src_path} -> {dest_path}")
    shutil.copy(src_path, dest_path)

diagrams = [
    "activity_complaint_submission",
    "usecase_shieldx_system",
    "class_shieldx_data_models",
    "sequence_sos_activation",
    "component_system_architecture",
    "er_diagram_database",
    "dfd_sos_emergency"
]

print("\nRendering Mermaid diagrams...")
for diag in diagrams:
    mmd_path = os.path.join(diagrams_dir, f"{diag}.mmd")
    pdf_out = os.path.join(rendered_dir, f"{diag}.pdf")
    png_out = os.path.join(rendered_dir, f"{diag}.png")
    
    # Render PDF (vector)
    print(f"Rendering {diag} to PDF...")
    cmd_pdf = f"npx --yes @mermaid-js/mermaid-cli -i \"{mmd_path}\" -o \"{pdf_out}\" -t neutral"
    subprocess.run(cmd_pdf, shell=True, check=True)
    
    # Render PNG (high-res scale 3)
    print(f"Rendering {diag} to PNG (scale 3)...")
    cmd_png = f"npx --yes @mermaid-js/mermaid-cli -i \"{mmd_path}\" -o \"{png_out}\" -t neutral -s 3"
    subprocess.run(cmd_png, shell=True, check=True)

print("\nUpdating LaTeX file content...")
with open(report_path, "r", encoding="utf-8") as f:
    latex_content = f.read()

# 1. Preamble modifications: Add float package
if "\\usepackage{float}" not in latex_content:
    latex_content = latex_content.replace(
        "\\usepackage{tikz}",
        "\\usepackage{tikz}\n\\usepackage{float}"
    )
    print("Added \\usepackage{float} to preamble.")

# 2. Globally change figure placement from [ht] to [H] (strict position, removes massive white spaces)
latex_content = latex_content.replace("\\begin{figure}[ht]", "\\begin{figure}[H]")
print("Globally converted \\begin{figure}[ht] to \\begin{figure}[H]")

# 3. Promote subsections to sections so they appear in the Table of Contents
section_promotions = {
    "\\subsection{Database Design}": "\\section{Database Design}",
    "\\subsection{System Architecture}": "\\section{System Architecture}",
    "\\subsection{Entity-Relationship (ER) Diagram}": "\\section{Entity-Relationship (ER) Diagram}",
    "\\subsection{Data Flow Diagram (DFD) --- SOS Emergency}": "\\section{Data Flow Diagram (DFD) --- SOS Emergency}",
    "\\subsection{Project Directory Structure}": "\\section{Project Directory Structure}"
}
for old_sub, new_sec in section_promotions.items():
    if old_sub in latex_content:
        latex_content = latex_content.replace(old_sub, new_sec)
        print(f"Promoted: {old_sub} -> {new_sec}")

# 4. Update graphic scales with optimal width/height bounding dimensions
replacements = {
    # Activity Diagram
    r"\includegraphics[height=0.6\textheight,keepaspectratio]{diagrams/rendered/activity_complaint_submission.pdf}":
    r"\includegraphics[width=0.85\textwidth,height=0.45\textheight,keepaspectratio]{diagrams/rendered/activity_complaint_submission.pdf}",
    
    # Use Case Diagram
    r"\includegraphics[height=0.55\textheight,keepaspectratio]{diagrams/rendered/usecase_shieldx_system.pdf}":
    r"\includegraphics[width=0.9\textwidth,height=0.4\textheight,keepaspectratio]{diagrams/rendered/usecase_shieldx_system.pdf}",
    
    # Class Diagram
    r"\includegraphics[width=0.95\textwidth]{diagrams/rendered/class_shieldx_data_models.pdf}":
    r"\includegraphics[width=0.95\textwidth,height=0.42\textheight,keepaspectratio]{diagrams/rendered/class_shieldx_data_models.pdf}",
    
    # Sequence Diagram
    r"\includegraphics[height=0.55\textheight,keepaspectratio]{diagrams/rendered/sequence_sos_activation.pdf}":
    r"\includegraphics[width=0.85\textwidth,height=0.45\textheight,keepaspectratio]{diagrams/rendered/sequence_sos_activation.pdf}",
    
    # Component Diagram
    r"\includegraphics[width=0.85\textwidth]{diagrams/rendered/component_system_architecture.pdf}":
    r"\includegraphics[width=0.85\textwidth,height=0.18\textheight,keepaspectratio]{diagrams/rendered/component_system_architecture.pdf}",
    
    # ER Diagram
    r"\includegraphics[width=0.85\textwidth]{diagrams/rendered/er_diagram_database.pdf}":
    r"\includegraphics[width=0.85\textwidth,height=0.35\textheight,keepaspectratio]{diagrams/rendered/er_diagram_database.pdf}",
    
    # DFD Diagram
    r"\includegraphics[height=0.35\textheight,keepaspectratio]{diagrams/rendered/dfd_sos_emergency.pdf}":
    r"\includegraphics[width=0.75\textwidth,height=0.3\textheight,keepaspectratio]{diagrams/rendered/dfd_sos_emergency.pdf}"
}

for old_line, new_line in replacements.items():
    if old_line in latex_content:
        latex_content = latex_content.replace(old_line, new_line)
        print(f"Updated scale settings for {old_line.split('/')[-1]}")
    else:
        print(f"Warning: could not find graphic line to update scale: {old_line.split('/')[-1]}")

# Normalize line endings to Unix style LF (\n) to ensure exact matching across platforms
latex_content = latex_content.replace("\r\n", "\n")

# 5. Embed the 3 missing screenshot diagrams in place of the text placeholder list
placeholder_block = r"""\section{Screenshot \& Interface Analysis}
\begin{itemize}
    \item \textbf{Figure 1: Citizen Home \& SOS Dashboard}\\
    The user interface features the dark theme (\texttt{AppTheme.darkTheme}) with the prominent red SOS button for immediate access. It displays a summary of the user's recent complaints with status badges and quick-action buttons for submitting complaints and viewing police stations.
    \item \textbf{Figure 2: Complaint Submission Form}\\
    This screen shows the multi-step form with crime category dropdown (14 categories), text areas for description, a \texttt{flutter\_map} snippet for pinpointing the incident location, \texttt{image\_picker} for evidence upload, date/time selector, and anonymous submission toggle.
    \item \textbf{Figure 3: Admin Real-time Analytical Dashboard}\\
    The admin view provides a macro-level perspective. Bar charts (via \texttt{fl\_chart}) show complaint frequencies by status, category distribution, monthly trends, and location-based hotspots. A live map highlights active SOS beacons. A thana selector allows filtering data per police station.
\end{itemize}""".replace("\r\n", "\n")

replacement_block = """\\section{Screenshot \\& Interface Analysis}
The following screenshots illustrate the core user interfaces of the ShieldX application, showing the layout, design system, and data visualizations.

\\begin{figure}[H]
    \\centering
    \\includegraphics[width=0.42\\textwidth]{diagrams/rendered/screenshot_citizen_home.png}
    \\caption{Citizen Home \\& SOS Dashboard}
    \\label{fig:screenshot-citizen-home}
\\end{figure}

The citizen dashboard (Figure~\\ref{fig:screenshot-citizen-home}) features the application's signature dark theme with a prominent red SOS button for immediate emergency distress signaling. It also lists recent complaints with status badges.

\\begin{figure}[H]
    \\centering
    \\includegraphics[width=0.42\\textwidth]{diagrams/rendered/screenshot_complaint_form.png}
    \\caption{Citizen Complaint Submission Form}
    \\label{fig:screenshot-complaint-form}
\\end{figure}

The complaint submission form (Figure~\\ref{fig:screenshot-complaint-form}) allows users to enter incident details, choose from 14 crime categories, pick a location on an interactive map, upload evidence, and choose anonymous submission.

\\begin{figure}[H]
    \\centering
    \\includegraphics[width=0.72\\textwidth]{diagrams/rendered/screenshot_admin_dashboard.png}
    \\caption{Admin Real-time Analytical Dashboard}
    \\label{fig:screenshot-admin-dashboard}
\\end{figure}

The admin analytical dashboard (Figure~\\ref{fig:screenshot-admin-dashboard}) provides administrators with a map highlighting active emergency beacons, and charts analyzing complaint counts by status and thana distribution."""

# Clean up escaping in block match if needed (replacing flutter_map block)
# Note: we need to match it exactly. Let's make sure it matches.
if placeholder_block in latex_content:
    latex_content = latex_content.replace(placeholder_block, replacement_block)
    print("Embedded actual screenshot figures in place of text list.")
else:
    # Try with single backslash or other minor variations if it fails
    # Let's perform a direct replace by slicing or search
    print("Warning: Exact screenshot text block not found. Checking double backslash variations...")
    # Clean up double backslashes in the code
    placeholder_block_alt = placeholder_block.replace("\\\\", "\\") # single backslash in LaTeX
    # Let's do a substring replace if needed. We will check it when running.

with open(report_path, "w", encoding="utf-8") as f:
    f.write(latex_content)

print("\nCreating ZIP package...")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    z.write(report_path, "ShieldX_Project_Report.tex")
    for diag in diagrams:
        pdf_rel = f"diagrams/rendered/{diag}.pdf"
        png_rel = f"diagrams/rendered/{diag}.png"
        z.write(os.path.join(rendered_dir, f"{diag}.pdf"), pdf_rel)
        z.write(os.path.join(rendered_dir, f"{diag}.png"), png_rel)
    # Include screenshots in the zip
    for screenshot in screenshots_src.keys():
        screenshot_rel = f"diagrams/rendered/{screenshot}"
        z.write(os.path.join(rendered_dir, screenshot), screenshot_rel)

print("ZIP package created at:", zip_path)
print("Done!")
