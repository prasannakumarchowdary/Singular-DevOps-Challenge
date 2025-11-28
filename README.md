# Singular DevOps – Application Log Analysis Challenge

This project is developed as part of the **Singular Systems – DevOps Code Challenge (Intermediate) – 2025**.

It automates the process of downloading application log files, parsing them, and generating a monthly analytical report.

---

# Features

✔ Downloads `index.txt` and all CSV log files from remote server  
✔ Parses logs using attributes:
- Date
- LogLevel
- Application
- Message

✔ Aggregates monthly counts for:
- Information messages
- Warnings
- Errors

✔ Calculates 🔺 percentage increase or 🔻 decrease in:
- Warnings
- Errors

✔ Generates:
- `report/report.json`
- `report/index.html` (visual report)

---

# Project Structure

DevOpsTask/
│
├── logs/               # Downloaded CSV log files
├── report/             # Generated HTML + JSON report
├── scripts/
│   └── process-logs.ps1  # Main PowerShell script
├── Docker 
    └── Dockerfile    # Hosting web-app
    └── run-container.ps1  # Build and run the container
└── README.md


---

# Technology Used

| Tool/Language | Purpose |
|--------------|---------|
| PowerShell 7 | Automation script |
| HTML + CSS | Reporting UI |
| GitHub | Version control & submission |

---

# How to Run

Open *PowerShell 7*:

powershell
cd C:\Users\sharath\DevOpsTask
pwsh .\scripts\process-logs.ps1

This downloads logs → parses → produces:
report/report.json
report/index.html

✔ Output will be created in the *report* folder  
✔ Open `index.html` in the browser to view the report

# Docker Hosting

docker build -t applogs-report-static -f Docker/Dockerfile .
docker run -d -p 8080:80 --name applogs-report-static applogs-report-static

# Access
 http://localhost:8080

---

# Sample Output

| Month | Info | Warning | Error | Warning % Chg | Error % Chg |
|-------|------|---------|-------|----------------|--------------|
| 2022-07 | 34 | 6 | 10 | N/A | N/A |
| 2022-08 | 32 | 9 | 4 | 50% | −60% |
| 2022-09 | 25 | 8 | 5 | −11.11% | 25% |

---

#  AI Usage 

AI was used for:
- PowerShell scripting guidance
- Debugging issues
- Report formatting improvements

---

# Technical Challenges & Learnings

- Parsing and structuring log data correctly

- Handling month-over-month % changes and division edge cases

- Making the report portable using Docker + Nginx

# Improvements if Given More Time

Add CI/CD pipeline with GitHub Actions

Deploy report publicly using GitHub Pages or cloud platform

Enhance UI with visual charts

# Bonus Ideas

- GitHub Actions workflow for automated report regeneration
- Deploy HTML report using GitHub Pages
- Dockerize the reporting app


