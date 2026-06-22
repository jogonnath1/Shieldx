# Directories to exclude
$excludeDirs = @('.git', '.dart_tool', 'build', '.idea', '.vscode', 'temp_extract')

# Allowed text/code/config extensions
$allowedExtensions = @(
    '.dart', '.yaml', '.py', '.html', '.tex', '.md', '.xml', '.gradle', 
    '.swift', '.properties', '.plist', '.json', '.java', '.kt', '.h', '.m', 
    '.sh', '.bat', '.env', '.gitignore', '.lock', '.txt', '.pbxproj', '.mmd', '.kts'
)

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Is-Excluded($path) {
    foreach ($dir in $excludeDirs) {
        if ($path -like "*\$dir\*" -or $path -like "*\$dir") {
            return $true
        }
    }
    return $false
}

$files = Get-ChildItem -Recurse -File -Path .

$stats = @{}
$grandTotalLines = 0
$grandTotalFiles = 0

foreach ($file in $files) {
    if (Is-Excluded $file.FullName) {
        continue
    }
    
    $ext = $file.Extension.ToLower()
    if ($allowedExtensions -notcontains $ext) {
        continue
    }
    
    try {
        $content = Get-Content $file.FullName -ErrorAction Stop
        $lines = $content.Count
        if ($content -eq $null) {
            $lines = 0
        }
    } catch {
        continue
    }
    
    if (-not $stats.ContainsKey($ext)) {
        $stats[$ext] = @{ Files = 0; Lines = 0 }
    }
    
    $stats[$ext].Files += 1
    $stats[$ext].Lines += $lines
    
    $grandTotalLines += $lines
    $grandTotalFiles += 1
    
    $results.Add([PSCustomObject]@{
        Path = $file.FullName.Replace((Get-Item .).FullName + '\', '')
        Extension = $ext
        Lines = $lines
    })
}

Write-Host "=== SOURCE CODE & CONFIG CODE LINES ==="
$summaryList = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($key in $stats.Keys) {
    $summaryList.Add([PSCustomObject]@{
        Extension = $key
        Files = $stats[$key].Files
        Lines = $stats[$key].Lines
    })
}

$summaryList | Sort-Object Lines -Descending | Format-Table -AutoSize

Write-Host "----------------------------------------"
Write-Host "Total Files: $grandTotalFiles"
Write-Host "Total Lines: $grandTotalLines"
