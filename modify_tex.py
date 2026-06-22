import re

with open('ShieldX_Project_Report.tex', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Title Page
title_page_new = r"""\begin{titlepage}
    \begin{center}
        \vspace*{1cm}
        {\fontsize{22}{26}\bfseries\selectfont ShieldX: Crime Reporting Management System}\\[2cm]
        
        {\large\selectfont Authors' Name and IDs}\\[0.5cm]
        {\large\bfseries\selectfont Student Name 1 (ID: ID 1)\\ Student Name 2 (ID: ID 2)\\ Student Name 3 (ID: ID 3)}\\[2.5cm]
        
        \IfFileExists{diagrams/lu_logo.png}{
            \includegraphics[width=3.5cm]{lu_logo.png}
        }{
            \begin{tikzpicture}[scale=1.2]
                \draw[thick, fill=blue!10] (0,1.2) -- (1.0,1.2) to[out=0,in=90] (1.2,0) to[out=270,in=0] (0,-1.4) to[out=180,in=270] (-1.2,0) to[out=90,in=180] (-1.0,1.2) -- cycle;
                \draw[thick, fill=red!60!black] (-0.8,0.8) rectangle (0.8,-0.4);
                \node at (0,0.2) [align=center, text=white, font=\tiny\bfseries] {Leading\\University};
            \end{tikzpicture}
        }\\[0.1cm]
        {\small\bfseries estd. 2001}\\[0.1cm]
        {\small\scshape LEADING UNIVERSITY}\\[2cm]
        
        {\large\selectfont B.Sc. Thesis/Project in Computing Science and Engineering}\\[0.5cm]
        {\large\selectfont Supervisor at CSE-LU: Supervisor Name}\\[2.5cm]
        
        {\large\selectfont Leading University}\\
        {\large\selectfont Department of Computing Science and Engineering}\\
        {\large\selectfont Ragibnagar, South Surma, Sylhet-3112}\\
        {\large\selectfont BANGLADESH}\\[1.5cm]
        
        {\large\selectfont 17 September, 2025}
    \end{center}
\end{titlepage}"""

content = re.sub(r'\\begin\{titlepage\}.*?\\end\{titlepage\}', lambda m: title_page_new, content, flags=re.DOTALL)

# 2. Update Recommendation Letter from Project Supervisor
rec_sup_new = r"""\chapter*{Recommendation Letter from the Project Supervisor}
\addcontentsline{toc}{chapter}{Recommendation Letter from the Project Supervisor}
The project entitled ``ShieldX'' was submitted by the students,

\begin{enumerate}[label=\arabic*.]
    \item Mr. Student Name 1\\
          ID : ID 1
    \item Mr. Student Name 2\\
          ID : ID 2
    \item Mr. Student Name 3\\
          ID : ID 3
\end{enumerate}

is a record of research work carried out under my supervision and I, hereby, approve that the report be submitted in partial fulfillment of the requirements for the award of their Bachelor Degrees.
\vspace{2cm}

\noindent\textbf{Signature of the Supervisor:}\\[1.5cm]
\noindent\rule{6cm}{0.4pt}\\
Dr. Shafkat Kibria\\
Assistant Professor, Dept. of CSE\\
Leading University, Sylhet\\
Date: 12 February, 2023"""

content = re.sub(r'\\chapter\*\{Recommendation Letter from the Project Supervisor\}.*?\\clearpage', lambda m: rec_sup_new + '\n\n\\clearpage', content, flags=re.DOTALL)

# 3. Update Recommendation Letter from Head of Department
rec_head_new = r"""\chapter*{Recommendation Letter from the Head of the Department}
\addcontentsline{toc}{chapter}{Recommendation Letter from the Head of the Department}
The project entitled ``ShieldX'' was submitted by the students,

\begin{enumerate}[label=\arabic*., start=4]
    \item Name: Student Name 1\\
          ID : ID 1
    \item Name: Student Name 2\\
          ID : ID 2
    \item Name: Student Name 3\\
          ID : ID 3
\end{enumerate}

is, hereby, accepted as the partial fulfillment of the requirements for the award of their Bachelor's Degree.
\vspace{2cm}

\noindent\textbf{Signature of the Head of the Department:}\\[1.5cm]
\noindent\rule{6cm}{0.4pt}\\
Kazi Md. Jahid Hasan\\
Assistant Professor \& Head (Acting)\\
Dept. of CSE\\
Leading University, Sylhet"""

content = re.sub(r'\\chapter\*\{Recommendation Letter from the Head of the Department\}.*?\\clearpage', lambda m: rec_head_new + '\n\n\\clearpage', content, flags=re.DOTALL)

# 4. Update Certificate of Acceptance
cert_new = r"""\chapter*{Certificate of Acceptance of the Project}
\addcontentsline{toc}{chapter}{Certificate of Acceptance of the Project}
The project entitled ``ShieldX'' was submitted by the students,

\begin{enumerate}[label=\arabic*.]
    \item Mr. Student Name 1\\
          ID : ID 1
    \item Mr. Student Name 2\\
          ID : ID 2
    \item Mr. Student Name 3\\
          ID : ID 3
\end{enumerate}

is, hereby, accepted as the partial fulfillment of the requirements for the award of their Bachelor's Degree.
\vspace{3cm}

\noindent\textbf{Signatures:}\\[2cm]
\noindent
\begin{tabularx}{\textwidth}{@{}XXX@{}}
    \rule{4.5cm}{0.4pt} & \rule{4.5cm}{0.4pt} & \rule{4.5cm}{0.4pt} \\
    Name: & Name: & Name: \\[0.5cm]
    Chairman, Defense Board & Member 1, Defense Board & Member 2, Defense Board
\end{tabularx}"""

content = re.sub(r'\\chapter\*\{Certificate of Acceptance of the Project\}.*?(?=\\chapter\*\{Abstract\})', lambda m: cert_new + '\n', content, flags=re.DOTALL)

# 5. Acknowledgements
content = content.replace(r'\chapter*{Acknowledgement}', r'\chapter*{Acknowledgements}')
content = content.replace(r'\addcontentsline{toc}{chapter}{Acknowledgement}', r'\addcontentsline{toc}{chapter}{Acknowledgements}')
ack_text = r"It is common to thank the supervisors and others who have contributed.\\[0.5cm]"
if ack_text not in content:
    content = content.replace(r'First and foremost', ack_text + '\nFirst and foremost')

# 6. Appendices renaming
content = content.replace(r'\chapter{Important Source Code Snippets}', r'\chapter{Source Code}')
content = content.replace(r'\chapter{Complete User Guide}', r'\chapter{User\'s Guide}')

with open('ShieldX_Project_Report.tex', 'w', encoding='utf-8') as f:
    f.write(content)

print("Modification complete.")
