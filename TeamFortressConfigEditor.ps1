# TODO: setup try and catch
# TODO: Autoupdate

$ErrorActionPreference = 'stop'
Add-Type -AssemblyName System.Windows.Forms # WinGUI

function Get-TF2Path {
    $steamLibrary = Get-Content "$(Split-Path $(([string]((
        Get-ItemPropertyValue -Path "Registry::HKEY_CLASSES_ROOT\steam\Shell\Open\Command" -Name "(Default)") -Split "-", 2, "SimpleMatch")[0]).Trim().Trim('"')))\config\libraryfolders.vdf" |
        Where-Object { $_ -like '*"path"*' } |
        ForEach-Object { Join-Path ($_.Trim().Trim('"path"').Trim().Trim('"').Replace("\\", "\")) 'steamapps\common\Team Fortress 2' }

    $TF2InstallPath = $steamLibrary | Where-Object { Test-Path (Join-Path $_ 'hl2.exe') }

    return $TF2InstallPath
}

# Constants
$TF2InstallPath = Get-TF2Path
$Documents = [Environment]::GetFolderPath("MyDocuments")
$PresetsConfigFile = "$Documents\TF2CE\Presets.cfg"
$BasesConfigFile = "$Documents\TF2CE\Bases.cfg"
$HUDsConfigFile = "$Documents\TF2CE\HUDs.cfg"
$ToggleMode = $false # To enable conditional modes, like remove mode or autorefresh :D

if (!(Test-Path $TF2InstallPath)) {
    "[ERROR] TF2 installation not found at '$TF2InstallPath'."
    'Make sure TF2 is installed, otherwise, update $TF2InstallPath.'
    Pause
    Exit 1
}
$genArgs = @{
    Force = $true
    Recurse = $true
    ErrorAction = "SilentlyContinue"
}

# Load lists
function DynamicMenuLoad {
    [cmdletbinding()]
    param (
        [string]$configFile,
        [string]$menu = "$menu"
    )
    if (-not (Test-Path $configFile)) { $null = New-Item $configFile -Force }
    $script:map = @{}; $counter = 1
    $addToMenu = Get-Content $configFile | Where-Object { $_ } | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        "`t[{0}] {1}" -f $counter++, $leaf
    }
    Read-Host ($menu -f ($addToMenu -join [System.Environment]::NewLine))
}

# Append content from folder dialog to file/generate file
function UploadFolder {
    [cmdletbinding()]
    param (
        [string]$configFile,
        [string]$statusName = "$statusName"
    )
    $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
    $dialogResult = $folderDialog.ShowDialog()

    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $folderDialog.SelectedPath
        $escapedPath = [regex]::Escape($selectedPath)
        if (Select-String $configFile -pattern $escapedPath) {
            "$statusName Choice already exists!"
            break promptLoop
        }
        $vdfPath = Join-Path $selectedPath -ChildPath "info.vdf"
        if ($configFile -eq $HUDsConfigFile -and -not (Test-Path $vdfPath)) {
            "$statusName HUD folder of choice needs to include info.vdf!"
            break promptLoop
        }
        Add-Content -Path $configFile -Value $selectedPath
    }
}
function Show-MainMenu {
    $status = ""
    :promptLoop while ($true) {
        Clear-Host
        $menu = Read-Host -prompt (@'
    ╭───────────────────────────────────────────────────────────────────────────────╮
    │                .----.     Scripted by UltraToon       .---.                   │
    │                '---,  `.____________________________.'  _  `.                 │
    │                     )   ____________________________   <_>  :                 │
    │                .---'  .'    Welcome to my TF2       `.     .'                 │
    │                 `----'                                `---'                   │
    │       __   ____             __ _         _____    _ _ _              __       │
    │      / /  / ___|___  _ __  / _(_) __ _  | ____|__| (_) |_ ___  _ __  \ \      │
    │     / /  | |   / _ \| '_ \| |_| |/ _` | |  _| / _` | | __/ _ \| '__|  \ \     │
    │     \ \  | |__| (_) | | | |  _| | (_| | | |__| (_| | | || (_) | |     / /     │
    │      \_\  \____\___/|_| |_|_| |_|\__, | |_____\__,_|_|\__\___/|_|    /_/      │
    │                                  |___/                                        │
    ╰───────────────────────────────────┰───────────────────────────────────────────╯
        Make sure to backup configs!    │               ❯❯❯ STATUS ❮❮❮
    ❯ Manage:                           │
        [1] Manage Presets [custom]     │   {0}
        [2] Manage Bases [cfg]          │
        [3] Manage HUDs [custom]        │
                                        │
    ❯ Other:                            │
        [4] Reset TF2                   │
        [5] What is this?               │
                                        │
        [Q] Exit                        │
                                        ◯

'@ -f $status)
        $status = switch ($menu) {
            1 { ManagePresets }
            2 { ManageBases }
            3 { ManageHUDs }
            4 { ResetTF2 }
            5 { FAQ }
            q { break promptLoop }
            default { "Unknown action: '$_'" }
        }
        if ('q' -in $status) { break }
    }
}

function ManagePresets {
    [cmdletbinding()]
    param (
        [bool]$ToggleMode = $ToggleMode
    )
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'Preset Manager:'
        $menu = (@'
    ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
    │                                                                                             │
    │       __  ____                     _     __  __                                    __       │
    │      / / |  _ \ _ __ ___  ___  ___| |_  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  | |_) | '__/ _ \/ __|/ _ \ __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  |  __/| | |  __/\__ \  __/ |_  | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |_|   |_|  \___||___/\___|\__| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                                   |___/                     │
    │                     Swappable, renamable tf/custom folders!                                 │
    ╰─────────────────────────────────────────────────────────────────────────────────────────────╯

    ❯ Navigate:
        [M] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [U] Upload a preset
        [R] Remove a preset [Toggle]

    ❯ Select{0}:
    {1}

'@ -f $(if ($ToggleMode) { " (REMOVE MODE ON)" }), '{0}')

        switch (DynamicMenuLoad -configFile $PresetsConfigFile) {
            m {
                "$statusName Exit"
                break promptLoop
            }
            q { return 'q' }
            u { UploadFolder -configFile $PresetsConfigFile }
            r {
                $ToggleMode = -not $ToggleMode # flip variable
                continue
            }
            { 0..9 -contains $_ } {
                if ($ToggleMode) {
                    (get-content "$PresetsConfigFile") -replace [Regex]::Escape($map[$_]) | set-content $PresetsConfigFile
                } else {
                    Remove-Item "$TF2InstallPath\tf\custom" @genArgs
                    Copy-Item $map[$_] "$TF2InstallPath\tf\custom" -Recurse -Force
                    "$statusName Applied Preset!"
                    break promptLoop
                }
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

function ManageBases {
    [cmdletbinding()]
    param (
        [bool]$ToggleMode = $ToggleMode
    )
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'Base Manager:'
        $menu = (@'
    ╭─────────────────────────────────────────────────────────────────────────────────────╮
    │                                                                                     │
    │       __  ____                   __  __                                    __       │
    │      / / | __ )  __ _ ___  ___  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  |  _ \ / _` / __|/ _ \ | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  | |_) | (_| \__ \  __/ | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |____/ \__,_|___/\___| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                           |___/                     │
    │             We strongly recommend using MasterComfig overrides!                     │
    ╰─────────────────────────────────────────────────────────────────────────────────────╯

    ❯ Navigate:
        [M] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [U] Upload a base
        [R] Remove a base [Toggle]

    ❯ Select{0}:
    {1}

'@ -f $(if ($ToggleMode) { " (REMOVE MODE ON)" }), '{0}')
        switch (DynamicMenuLoad -configFile $BasesConfigFile) {
            m {
                "$statusName Exit"
                break promptLoop
            }
            q { return 'q' }
            u { UploadFolder -configFile $BasesConfigFile }
            r {
                $ToggleMode = -not $ToggleMode # flip variable
                continue
            }
            { 0..9 -contains $_ } {
                if ($ToggleMode) {
                    (get-content "$BasesConfigFile") -replace [Regex]::Escape($map[$_]) | set-content $BasesConfigFile
                } else {
                    Remove-Item "$TF2InstallPath\tf\cfg\overrides, $TF2InstallPath\tf\cfg\autoexec" @genArgs
                    Copy-Item $map[$_] "$TF2InstallPath\tf\" -Recurse -Force
                    "$statusName Applied Base!"
                    break promptLoop
                }
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

function ManageHUDs {
    [cmdletbinding()]
    param (
        [bool]$ToggleMode = $ToggleMode
    )
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'HUD Manager:'
        $menu = (@'
    ╭──────────────────────────────────────────────────────────────────────────────────╮
    │                   No support for multiple HUD loading! (YET)                     │
    │       __  _   _ _   _ ____    __  __                                    __       │
    │      / / | | | | | | |  _ \  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  | |_| | | | | | | | | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  |  _  | |_| | |_| | | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |_| |_|\___/|____/  |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                        |___/                     │
    │                                                                                  │
    ╰──────────────────────────────────────────────────────────────────────────────────╯

    ❯ Navigate:
        [M] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [U] Upload a HUD
        [R] Remove a HUD [Toggle]

    ❯ Select{0}:
    {1}

'@ -f $(if ($ToggleMode) { " (REMOVE MODE ON)" }), '{0}')
        switch (DynamicMenuLoad -configFile $HUDsConfigFile) {
            m {
                "$statusName Exit"
                break promptLoop
            }
            q { return 'q' }
            u { UploadFolder -configFile $HUDsConfigFile }
            r {
                $ToggleMode = -not $ToggleMode # flip variable
                continue
            }
            { 0..9 -contains $_ } {
                if ($ToggleMode) {
                    (get-content "$HUDsConfigFile") -replace [Regex]::Escape($map[$_]) | set-content $HUDsConfigFile
                } else {
                    (Get-ChildItem "$TF2InstallPath\tf\custom" -filter 'info.vdf' -Recurse) | Remove-Item -LiteralPath { $_.DirectoryName } @genArgs
                    Copy-Item $map[$_] "$TF2InstallPath\tf\custom\" -Recurse -Force
                    "$statusName Applied HUD!"
                    break promptLoop
                }
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}



function ResetTF2 {
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'Reset TF2:'
        $menu = Read-Host -prompt (@'
    ╭───────────────────────────────────────────────────────╮
    │      !Backup folders you want from the TF folder!     │
    │      ____                _     _____ _____ ____       │
    │     |  _ \ ___  ___  ___| |_  |_   _|  ___|___ \      │
    │     | |_) / _ \/ __|/ _ \ __|   | | | |_    __) |     │
    │     |  _ <  __/\__ \  __/ |_    | | |  _|  / __/      │
    │     |_| \_\___||___/\___|\__|   |_| |_|   |_____|     │
    │    Does not reset account data (lvls, items, stats)   │
    ╰───────────────────────────────────────────────────────╯

    ❯ Navigate:
        [0] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [R] Enable autorefresh [Toggle] (restores current cfgs)

    ❯ Select:
        [1] Clean out configs [cfg (comfig only)/custom]
        [2] Complete reset [fixes issues] {0}

'@ -f $(if ($ToggleMode) { "(AUTOREFRESH ON)" }), '{0}')
        Clear-Host
        switch ($menu) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
            r {
                if (-not (Test-Path "$TF2InstallPath\tf\cfg\overrides" -PathType Container)) {
                    Start-Process 'https://docs.comfig.app/page/customization/custom_configs/'
                    "$statusName [ERROR] mcomfig overrides only!"
                    break PromptLoop
                }
                $ToggleMode = -not $ToggleMode # flip variable
                continue
            }
            1 {
                Remove-Item "$TF2InstallPath\tf\custom\*" @genArgs
                Remove-Item "$TF2InstallPath\tf\cfg\overrides" @genArgs
                "$statusName Configs completely cleaned"
                break PromptLoop
            }
            2 {
                $destinationPath = "$env:TEMP\TF2CE_cache"
                if ($ToggleMode) {
                    Copy-Item -Path "$TF2InstallPath\tf\custom" -Destination "$destinationPath\custom\" @genArgs
                    Copy-Item -Path "$TF2InstallPath\tf\cfg\overrides" -Destination "$destinationPath\cfg\overrides" @genArgs
                }
                Remove-Item "$TF2InstallPath\tf\custom\*" @genArgs
                Remove-Item "$TF2InstallPath\tf\cfg" @genArgs
                Get-ChildItem "$steamLibrary\userdata\*\440\remote\cfg\config.cfg" | Set-Content -Value $null
                Start-Process 'steam://validate/440'
                $progress = '\', '|', '/', '-'; $i = 0
                while ($true) {
                    if ((Test-Path "$TF2InstallPath\tf\custom\workshop", "$TF2InstallPath\tf\custom\readme.txt", "$TF2InstallPath\tf\cfg\config_default.cfg") -contains $false) {
                        $char = $progress[$i++ % $progress.Count]
                        Write-Progress -Activity "◯──────────────── [$char] Validating Files ────────────────◯" -Status "❯ Verifying location and integrity of files..."
                    } else {
                        $char = $progress[$i++ % $progress.Count]
                        Write-Progress -Activity "◯──────────────── [$char] Autogenerating Configs ────────────────◯" -Status "❯ Autoconfiguring TF2... (Process in background)"
                        Start-Process "$TF2InstallPath\hl2.exe" -ArgumentList "-sw -small -h 1 -w 1 -novid -autoconfig -default +host_writeconfig config.cfg full +mat_savechanges +quit -lockwindow -game tf" -Wait
                        if ($ToggleMode) {
                            Copy-Item "$destinationPath\*" -Destination "$TF2InstallPath\tf\" @genArgs
                            Remove-Item $destinationPath @genArgs
                        }
                        "$statusName Completely Cleaned!"
                        break PromptLoop
                    }
                }
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

function FAQ {
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'FAQ:'
        $menu = Read-Host -prompt @'
    Open the corresponding .cfg files to edit/remove/add content too!
    Enabling remove mode lets you remove items when selecting below, just toggle it.
    ╭────────────────────────────────────────┰──────────────────────────────────────────────────────────────╮
    │ ❯ Presets:                             │ ❯ Bases                                                      │
    │ > They are swappable/renamable         │ > Just like presets                                          │
    │   profiles of the tf/custom folder     │   but with tf/cfg folders.                                   │
    │ > They can be anywhere on your PC,     │ > RECOMMENDED to use mcomfigs overrides:                     │
    │   just use the manager.                │ (https://docs.comfig.app/page/customization/custom_configs/) │
    ┠────────────────────────────────────────╂──────────────────────────────────────────────────────────────┨
    │ ❯ HUDs:                                │ ❯ Reset TF2:                                                 │
    │ > Swappable and renamable HUDs!        │ > You can reset TF2 of its configurations or completely.     │
    │ > Multi-HUD loading not supported,     │ > Account does not get reset since its in the cloud.         │
    │ instead, merge them with the folders.  │ > Autorefesh restores cfgs (tf/cfg,custom) after the reset.  │
    ╰────────────────────────────────────────┸──────────────────────────────────────────────────────────────╯

    ❯ Navigate:
        [M] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [1] Open Github Repo
        [2] Open MasterComfig Homepage
        [3] Open MasterComfig Customization (overrides guide)

'@
        switch ($menu) {
            m {
                "$statusName Exit"
                break promptLoop
            }
            q { return 'q' }
            1 {
                Start-Process 'https://github.com/UltraToon/TF2PresetChooser'
                "$statusName Opened https://github.com/UltraToon/TF2PresetChooser"
                break promptLoop
            }
            2 {
                Start-Process 'https://mastercomfig.com/'
                "$statusName Opened https://mastercomfig.com/"
                break promptLoop
            }
            3 {
                Start-Process 'https://docs.comfig.app/page/customization/custom_configs/'
                "$statusName Opened https://docs.comfig.app/page/customization/custom_configs/"
                break promptLoop
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

# Invoke Script
Show-MainMenu
