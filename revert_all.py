import re

with open('temp_restore/main.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Revert indentfirst
content = content.replace(r"\usepackage{indentfirst} % Indent first paragraph of sections" + "\n", "")

def revert_section(content, section_title, original_text, end_marker):
    pattern = r'(\\sub(?:sub)?section\{' + re.escape(section_title) + r'\}.*?)\n' + re.escape(end_marker)
    def repl(m):
        return m.group(1).split('\n')[0] + '\n' + original_text + '\n' + end_marker
    
    new_content = re.sub(pattern, repl, content, flags=re.DOTALL)
    if new_content == content:
        print(f"Warning: Could not revert {section_title}")
    return new_content

orig_activity = "These diagrams illustrate the core process flows of the ShieldX application, including the citizen complaint submission, emergency SOS triggering, and the admin complaint lifecycle management."
orig_usecase = "This diagram outlines the interactions between the primary actors and the system."
orig_class = r"This diagram defines the structural data models of the application, matching the actual Dart classes in \texttt{lib/data/models/}."
orig_er = r"The following Entity Relationship (ER) diagram illustrates the core database schema of the ShieldX system. It highlights the primary relationships and foreign key constraints between the main entities: \texttt{profiles}, \texttt{complaints}, \texttt{emergencies}, \texttt{officers}, \texttt{notifications}, \texttt{messages}, and \texttt{status\_history}."
orig_dfd0 = "The Context Diagram defines the system boundaries and shows the high-level data exchange between the ShieldX core system and external entities."
orig_dfd1 = "The Level 1 DFD decomposes the main system into its primary subsystems: Authentication, Complaint Processing, SOS Dispatch, and Analytics."
orig_screenshots = "The following screenshots illustrate the core user interfaces of the ShieldX application, showcasing the intuitive layout, consistent design system, and dark-themed aesthetics tailored for both citizens and administrators."

content = revert_section(content, "UML Activity Diagrams", orig_activity, r"\begin{landscape}")
content = revert_section(content, "UML Use Case Diagram", orig_usecase, r"\begin{figure}[H]")
content = revert_section(content, "UML Class Diagram", orig_class, r"\begin{landscape}")
content = revert_section(content, "Entity Relationship (ER) Diagram", orig_er, r"\begin{landscape}")
content = revert_section(content, "DFD Level 0 (Context Diagram)", orig_dfd0, r"\begin{landscape}")
content = revert_section(content, "DFD Level 1", orig_dfd1, r"\begin{figure}[H]")

idx1 = content.find(r'\section{Screenshot \& Interface Analysis}')
idx2 = content.find(r'\begin{figure}[H]', idx1)
if idx1 != -1 and idx2 != -1:
    before = content[:idx1 + len(r'\section{Screenshot \& Interface Analysis}')]
    after = content[idx2:]
    content = before + '\n' + orig_screenshots + '\n\n' + after
else:
    print("Warning: Could not revert Screenshot section")

with open('temp_restore/main.tex', 'w', encoding='utf-8') as f:
    f.write(content)
print("Restoration script completed successfully.")
