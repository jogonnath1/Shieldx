$files = Get-ChildItem -Recurse -Filter *.dart -Path .

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

$userScreens = 0
$userWidgets = 0
$userProviders = 0

$adminScreens = 0
$adminWidgets = 0
$adminProviders = 0

$authScreens = 0
$commonScreens = 0
$commonWidgets = 0
$coreLines = 0
$dataLines = 0
$sharedProviders = 0
$rootDartLines = 0
$testLines = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $lines = $content.Count
    if ($content -eq $null) {
        $lines = 0
    }
    
    $relPath = $file.FullName.Replace((Get-Item .).FullName + '\', '')
    
    $category = "Unknown"
    
    # User Part
    if ($relPath.StartsWith("lib\presentation\user\")) {
        $category = "User Screen/Model"
        $userScreens += $lines
    } elseif ($relPath.StartsWith("lib\presentation\widgets\user\")) {
        $category = "User Widget"
        $userWidgets += $lines
    } elseif ($relPath -eq "lib\providers\sos_provider.dart") {
        $category = "User Provider"
        $userProviders += $lines
    }
    # Admin Part
    elseif ($relPath.StartsWith("lib\presentation\admin\")) {
        $category = "Admin Screen"
        $adminScreens += $lines
    } elseif ($relPath.StartsWith("lib\presentation\widgets\admin\")) {
        $category = "Admin Widget"
        $adminWidgets += $lines
    } elseif ($relPath -eq "lib\providers\admin_sos_provider.dart") {
        $category = "Admin Provider"
        $adminProviders += $lines
    }
    # Shared / Common Part
    elseif ($relPath.StartsWith("lib\presentation\auth\")) {
        $category = "Auth Screen"
        $authScreens += $lines
    } elseif ($relPath.StartsWith("lib\presentation\common\")) {
        $category = "Common Screen"
        $commonScreens += $lines
    } elseif ($relPath.StartsWith("lib\presentation\widgets\common\")) {
        $category = "Common Widget"
        $commonWidgets += $lines
    } elseif ($relPath.StartsWith("lib\core\")) {
        $category = "Core (Shared)"
        $coreLines += $lines
    } elseif ($relPath.StartsWith("lib\data\")) {
        $category = "Data/Models (Shared)"
        $dataLines += $lines
    } elseif ($relPath.StartsWith("lib\providers\")) {
        $category = "Shared Provider"
        $sharedProviders += $lines
    } elseif ($relPath.StartsWith("test\")) {
        $category = "Tests"
        $testLines += $lines
    } elseif ($relPath.StartsWith("lib\app.dart") -or $relPath.StartsWith("lib\main.dart")) {
        $category = "Root App Setup"
        $rootDartLines += $lines
    } else {
        $category = "Scratch/Other Tools"
        # Ignore scratch files for production code count
    }
    
    $results.Add([PSCustomObject]@{
        Path = $relPath
        Category = $category
        Lines = $lines
    })
}

$userTotal = $userScreens + $userWidgets + $userProviders
$adminTotal = $adminScreens + $adminWidgets + $adminProviders
$sharedTotal = $authScreens + $commonScreens + $commonWidgets + $coreLines + $dataLines + $sharedProviders + $rootDartLines

Write-Host "=== FINE-GRAINED SUMMARY ==="
Write-Host "USER PART:"
Write-Host "  - User Screens & Models (lib/presentation/user): $userScreens lines"
Write-Host "  - User-Specific Widgets (lib/presentation/widgets/user): $userWidgets lines"
Write-Host "  - User-Specific Providers (sos_provider.dart): $userProviders lines"
Write-Host "  * TOTAL USER PART: $userTotal lines"
Write-Host ""
Write-Host "ADMIN PART:"
Write-Host "  - Admin Screens (lib/presentation/admin): $adminScreens lines"
Write-Host "  - Admin-Specific Widgets (lib/presentation/widgets/admin): $adminWidgets lines"
Write-Host "  - Admin-Specific Providers (admin_sos_provider.dart): $adminProviders lines"
Write-Host "  * TOTAL ADMIN PART: $adminTotal lines"
Write-Host ""
Write-Host "SHARED/COMMON PART:"
Write-Host "  - Authentication Screens (lib/presentation/auth): $authScreens lines"
Write-Host "  - Common Screens (lib/presentation/common): $commonScreens lines"
Write-Host "  - Common/Shared Widgets (lib/presentation/widgets/common): $commonWidgets lines"
Write-Host "  - Core Utilities & Config (lib/core): $coreLines lines"
Write-Host "  - Data Models & Services (lib/data): $dataLines lines"
Write-Host "  - Shared Providers (lib/providers): $sharedProviders lines"
Write-Host "  - App Root/Setup (lib/main.dart, lib/app.dart): $rootDartLines lines"
Write-Host "  * TOTAL SHARED/COMMON: $sharedTotal lines"
Write-Host ""
Write-Host "OTHER:"
Write-Host "  - Test Files (test/*): $testLines lines"
Write-Host "----------------------------------------"
Write-Host "Total Application Code (excluding scratch/tests): $($userTotal + $adminTotal + $sharedTotal) lines"
Write-Host "Grand Total (including scratch/tests): $($results | Measure-Object -Property Lines -Sum | Select-Object -ExpandProperty Sum) lines"
