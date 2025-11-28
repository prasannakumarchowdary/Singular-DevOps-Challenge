<#
    Process-Logs.ps1
    -----------------
    This script does what the challenge asks:

    1. Download index.txt (list of log files).
    2. Download all log files into the logs folder.
    3. Read each log line and work out:
         - Year + Month
         - Log level (Information, Warning, Error)
    4. Count totals per Year+Month.
    5. Calculate % increase/decrease for Warnings & Errors vs previous month.
    6. Save:
         - report\report.json
         - report\index.html
#>

# ---------------------------
# 1. Basic configuration
# ---------------------------

# Base URL of the files (from the PDF)
$BaseUrl  = "https://files.singular-devops.com/challenges/01-applogs"
$IndexUrl = "$BaseUrl/index.txt"

# $PSScriptRoot = folder where THIS script lives (scripts)
# Project root = one level up from scripts (DevOpsTask)
$ScriptDir   = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir -Parent

# Paths to logs and report folders
$LogsDir   = Join-Path $ProjectRoot "logs"
$ReportDir = Join-Path $ProjectRoot "report"

# Make sure logs and report folders exist
New-Item -ItemType Directory -Path $LogsDir   -Force | Out-Null
New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

Write-Host "Project root : $ProjectRoot"
Write-Host "Logs folder  : $LogsDir"
Write-Host "Report folder: $ReportDir"
Write-Host ""

# ---------------------------
# 2. Download index.txt
# ---------------------------

$IndexPath = Join-Path $LogsDir "index.txt"

Write-Host "Downloading index file from:"
Write-Host "  $IndexUrl"
Invoke-WebRequest -Uri $IndexUrl -OutFile $IndexPath
Write-Host "Saved index.txt to: $IndexPath"
Write-Host ""

# ---------------------------
# 3. Download all log files
# ---------------------------

# Read each non-empty line in index.txt (each line is a file name)
$LogFileNames = Get-Content $IndexPath | Where-Object { $_.Trim() -ne "" }

if (-not $LogFileNames -or $LogFileNames.Count -eq 0) {
    Write-Error "index.txt is empty. No log files to download."
    exit 1
}

Write-Host "Found $($LogFileNames.Count) log file names in index.txt"
Write-Host ""

foreach ($name in $LogFileNames) {
    $name    = $name.Trim()
    $LogUrl  = "$BaseUrl/$name"
    $LogPath = Join-Path $LogsDir $name

    Write-Host "Downloading: $LogUrl"
    Invoke-WebRequest -Uri $LogUrl -OutFile $LogPath
}

Write-Host ""
Write-Host "All log files downloaded."
Write-Host ""

# ---------------------------
# 4. Helper functions
# ---------------------------

function Get-LogDate {
    <#
        Try to read a date from the beginning of a log line.
        Assumption: the date is in the first ~10 characters.
        Example: "2022-07-01 10:15:23 INFO ..." → "2022-07-01"
        Returns [DateTime] or $null if parsing fails.
    #>
    param(
        [string]$Line
    )

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $null
    }

    # Take first 10 characters or fewer if line is shorter
    $lengthToTake = [Math]::Min(10, $Line.Length)
    $dateString   = $Line.Substring(0, $lengthToTake)

    try {
        $parsed = [DateTime]::Parse($dateString)
        return $parsed
    }
    catch {
        # If the string cannot be parsed as a date
        return $null
    }
}

function Get-LogLevel {
    <#
        Work out the log level from the line.
        Looks for:
          - ERROR / Error
          - WARN / Warning
          - INFO / Information

        Returns exactly one of:
          "Information", "Warning", "Error"
        or $null if nothing matches.
    #>
    param(
        [string]$Line
    )

    if ($Line -match "ERROR" -or $Line -match "Error") {
        return "Error"
    }
    elseif ($Line -match "WARN" -or $Line -match "Warning") {
        return "Warning"
    }
    elseif ($Line -match "INFO" -or $Line -match "Information") {
        return "Information"
    }
    else {
        return $null
    }
}

# ---------------------------
# 5. Read all logs and count per month
# ---------------------------

# Hashtable to hold stats for each month: key = "yyyy-MM"
$Stats = @{}

Write-Host "Processing log files..."
Write-Host ""

# Get all files in logs folder EXCEPT index.txt
$LogFiles = Get-ChildItem -Path $LogsDir | Where-Object { $_.Name -ne "index.txt" }

if (-not $LogFiles -or $LogFiles.Count -eq 0) {
    Write-Error "No log files found in $LogsDir."
    exit 1
}

foreach ($file in $LogFiles) {
    Write-Host "Processing file: $($file.Name)"

    Get-Content $file.FullName | ForEach-Object {
        $line = $_

        # 1) extract date
        $logDate = Get-LogDate -Line $line
        if (-not $logDate) {
            return
        }

        # 2) extract log level
        $level = Get-LogLevel -Line $line
        if (-not $level) {
            return
        }

        # 3) build a key per month, like "2022-07"
        $monthKey = "{0:yyyy-MM}" -f $logDate

        # 4) if we haven't seen this month yet, create an entry
        if (-not $Stats.ContainsKey($monthKey)) {
            $Stats[$monthKey] = [PSCustomObject]@{
                MonthKey    = $monthKey
                Information = 0
                Warning     = 0
                Error       = 0
            }
        }

        # 5) increase the correct counter
        switch ($level) {
            "Information" { $Stats[$monthKey].Information++ }
            "Warning"     { $Stats[$monthKey].Warning++ }
            "Error"       { $Stats[$monthKey].Error++ }
        }
    }
}

Write-Host ""
Write-Host "Finished counting all log entries."
Write-Host ""

if ($Stats.Count -eq 0) {
    Write-Warning "No log entries were counted. Check date and level parsing."
}

# ---------------------------
# 6. Build report objects with % changes
# ---------------------------

# Sort by MonthKey so months are in order (e.g. 2022-07, 2022-08, 2022-09)
$OrderedMonths = $Stats.Values | Sort-Object MonthKey

$Previous    = $null
$ReportItems = @()

foreach ($item in $OrderedMonths) {
    $warningChange = $null
    $errorChange   = $null

    if ($Previous -ne $null) {
        # Only calculate % change if previous value > 0
        if ($Previous.Warning -gt 0) {
            $warningChange = [Math]::Round(
                (($item.Warning - $Previous.Warning) / $Previous.Warning) * 100,
                2
            )
        }

        if ($Previous.Error -gt 0) {
            $errorChange = [Math]::Round(
                (($item.Error - $Previous.Error) / $Previous.Error) * 100,
                2
            )
        }
    }

    # Split "yyyy-MM" into year and month numbers
    $yearString, $monthString = $item.MonthKey -split "-"

    $ReportItems += [PSCustomObject]@{
        Year                 = [int]$yearString
        Month                = [int]$monthString
        InformationCount     = $item.Information
        WarningCount         = $item.Warning
        ErrorCount           = $item.Error
        WarningPercentChange = $warningChange
        ErrorPercentChange   = $errorChange
    }

    $Previous = $item
}

# ---------------------------
# 7. Save report.json
# ---------------------------

$ReportJsonPath = Join-Path $ReportDir "report.json"
$ReportItems | ConvertTo-Json -Depth 3 | Out-File $ReportJsonPath -Encoding UTF8

Write-Host "JSON report written to:"
Write-Host "  $ReportJsonPath"
Write-Host ""

# ---------------------------
# 8. Generate index.html
# ---------------------------

# Build HTML table rows
$HtmlRows = foreach ($r in $ReportItems) {
@"
        <tr>
            <td>$($r.Year)</td>
            <td>$($r.Month)</td>
            <td>$($r.InformationCount)</td>
            <td>$($r.WarningCount)</td>
            <td>$($r.ErrorCount)</td>
            <td>$($r.WarningPercentChange)</td>
            <td>$($r.ErrorPercentChange)</td>
        </tr>
"@
}

$RowsString = $HtmlRows -join "`n"

$HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>Application Log Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { text-align: center; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: center; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Application Log Report</h1>
    <p>
        This report shows, per month, the number of Information, Warning and Error messages, and the percentage
        change in Warnings and Errors compared to the previous month.
    </p>
    <table>
        <thead>
            <tr>
                <th>Year</th>
                <th>Month</th>
                <th>Information</th>
                <th>Warnings</th>
                <th>Errors</th>
                <th>Warning % Change</th>
                <th>Error % Change</th>
            </tr>
        </thead>
        <tbody>
$RowsString
        </tbody>
    </table>
</body>
</html>
"@

$HtmlPath = Join-Path $ReportDir "index.html"
$HtmlContent | Out-File $HtmlPath -Encoding UTF8

Write-Host "HTML report written to:"
Write-Host "  $HtmlPath"
Write-Host ""
Write-Host "Done."
