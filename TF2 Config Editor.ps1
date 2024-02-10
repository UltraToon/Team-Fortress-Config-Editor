# Make the status append instead of clearing
# Color text with variables and `e
# add a log system
# improve select string specificty
# get preset name
# add backup system

$ErrorActionPreference = 'stop'
Add-Type -AssemblyName System.Windows.Forms # Graphical API
$toggleMode = $false

# Constants
$steamLibrary = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath").SteamPath
$TF2InstallPath = "$steamLibrary\steamapps\common\Team Fortress 2"
$PresetsConfigFile = "$env:USERPROFILE\Documents\TF2CE\Presets.cfg"
$BasesConfigFile = "$env:USERPROFILE\Documents\TF2CE\Bases.cfg"
$HUDsConfigFile = "$env:USERPROFILE\Documents\TF2CE\HUDs.cfg"

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
    if (!(Test-Path $configFile)) {
        $null = New-Item $configFile -ErrorAction 'SilentlyContinue' -Force -Value "
# Find out the type by checking what file you are in (eg., bases.cfg = bases)
# To know which one is which, the name is above the path for example:
#    # MyAwesomePreset
#    C:\Users\Ivan\Documents\MyAwesomePreset <- Remove this to remove the item!
`n"
    }
    $script:map = @{}; $script:counter = 2
    $addToMenu = Get-Content $configFile | Select-String -NotMatch "^#|^$" | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        "`t[{1}] {0}" -f $counter++, $leaf
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
        $selectedPathName = Split-Path $selectedPath -Leaf
        Add-Content $configFile -Value "# $selectedPathName`n$selectedPath`n"
    }
}
function Show-MainMenu {
    $status = ""
    :promptLoop while ($true) {
        Clear-Host
        $menu = Read-Host -prompt (@'
    ╭───────────────────────────────────────────────────────────────────────────────╮
    │                     Welcome to my Team Fortress 2                             │
    │       __   ____             __ _         _____    _ _ _              __       │
    │      / /  / ___|___  _ __  / _(_) __ _  | ____|__| (_) |_ ___  _ __  \ \      │
    │     / /  | |   / _ \| '_ \| |_| |/ _` | |  _| / _` | | __/ _ \| '__|  \ \     │
    │     \ \  | |__| (_) | | | |  _| | (_| | | |__| (_| | | || (_) | |     / /     │
    │      \_\  \____\___/|_| |_|_| |_|\__, | |_____\__,_|_|\__\___/|_|    /_/      │
    │                                  |___/                                        │
    │                More features coming soon! By UltraToon.                       │
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
        } if ('q' -in $status) { break }
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
        {0}
    ❯ Navigate:
        [0] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [1] Upload a preset
        [R] Remove a preset

    ❯ Select:
    {1}

'@ -f $($ToggleMode ? "[TOGGLE MODE ENABLED]" : ""))
        switch (DynamicMenuLoad -configFile $PresetsConfigFile) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
            1 { UploadFolder -configFile $PresetsConfigFile }
            R {
                Start-Process $PresetsConfigFile -Wait
            }
            { $_ -ge $counter } {
                if ($ToggleMode) {
                    $ToggleMode = -not $ToggleMode
                } else {
                    $presetName = $selectedValue -replace '^\[\d+\]\s+', ''
                    Remove-Item "$TF2InstallPath\tf\custom" @genArgs
                    Copy-Item $map[$_] "$TF2InstallPath\tf\custom" -Recurse -Force
                    "$statusName Applied $presetName!"
                    break promptLoop
                }
                break
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

function ManageBases {
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'Base Manager:'
        $menu = @'
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
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Upload a base
        [2] Remove a base

    ❯ Select:
    {0}

'@
        switch (DynamicMenuLoad -configFile $BasesConfigFile) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
            1 { UploadFolder -configFile $BasesConfigFile }
            { $_ -ge $counter } {
                Remove-Item "$TF2InstallPath\tf\cfg\overrides, $TF2InstallPath\tf\cfg\autoexec" @genArgs
                Copy-Item $map[$_] "$TF2InstallPath\tf\" -Recurse -Force
                "$statusName Applied Base!"
                break promptLoop
            }
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

function ManageHUDs {
    :promptLoop while ($true) {
        Clear-Host
        $statusName = 'HUD Manager:'
        $menu = @'
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
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Upload a HUD

    ❯ Select:
    {0}

'@
        switch (DynamicMenuLoad -configFile $HUDsConfigFile) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
            1 { UploadFolder -configFile $HUDsConfigFile }
            { $_ -ge $counter } {
                (Get-ChildItem "$TF2InstallPath\tf\custom" -filter 'info.vdf' -Recurse) | Remove-Item -LiteralPath { $_.DirectoryName } @genArgs
                Copy-Item $map[$_] "$TF2InstallPath\tf\custom\" -Recurse -Force
                "$statusName Applied HUD!"
                break promptLoop
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
        $menu = Read-Host -prompt @'
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

    ❯ Reset TF2:
        [1] Clean out configs [cfg (comfig only)/custom]
        [2] Complete reset [Fixes issue, clean refresh]

'@
        Clear-Host
        switch ($menu) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
            1 {
                Remove-Item "$TF2InstallPath\tf\custom\*", "$TF2InstallPath\tf\cfg\overrides" @genArgs
                "$statusName Configs Completely Cleaned"
                break PromptLoop
            }
            2 {
                Remove-Item "$TF2InstallPath\tf\custom\*", "$TF2InstallPath\tf\cfg" @genArgs
                Get-ChildItem "$steamLibrary\userdata\*\440\remote\cfg\config.cfg" | Set-content -Value $null
                Start-Process 'steam://validate/440'
                $progress = '\', '|', '/', '-'; $i = 0
                while ($true) {
                    if ((Test-Path "$TF2InstallPath\tf\custom\workshop", "$TF2InstallPath\tf\custom\readme.txt", "$TF2InstallPath\tf\cfg\config_default.cfg") -contains $false) {
                        $char = $progress[$i++ % $progress.Count]
                        Write-Progress -Activity "◯──────────────── [$char] Validating Files ────────────────◯" -Status "❯ Verifying location and integrity of files..."
                        Start-Sleep 1
                    } else {
                        $char = $progress[$i++ % $progress.Count]
                        Write-Progress -Activity "◯──────────────── [$char] Autogenerating Configs ────────────────◯" -Status "❯ Autoconfiguring TF2... (Process in background)"
                        Start-Process "$TF2InstallPath\hl2.exe" -ArgumentList "-sw -small -h 1 -w 1 -novid -autoconfig -default +host_writeconfig config.cfg full +mat_savechanges +quit -lockwindow -game tf" -Wait
                        Start-Sleep 1
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
    Open TF2CE folder in documents to edit/delete presets and more.
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Presets:
        - They are basically swappable and renamable profiles of the custom folder
        - They can be anywhere on your PC, just upload and select them through the manager.
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Bases:
        - Just like presets, but with your CFG folders, I decided to do this seperately for modularity reasons.
        - It is STRONGLY recommended to use mastercomfigs overrides method (tf\cfg\overrides\yourcfgfiles)
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Huds:
        - Just like presets, but with your HUDs! I decided to do this seperately for modularity reasons.
        - Multi-HUD loading not supported, so just merge them with the folders.
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Reset TF2:
        - You can reset TF2 of its configurations or completely. Useful for fixing issues or starting fresh for configuration.
        - This does not modify account data since its saved in the cloud.
      <────────────────────────────────────────────────────────────────────────────────────────────────────────>
    ❯ Navigate:
        [0] Back to Main Menu
        [Q] Exit

    ❯ Manage:
        [1] Open Github [Link]
        [2] Open MasterComfig [Link]

'@
        switch ($menu) {
            q { return 'q' }
            0 {
                "$statusName Exit"
                break promptLoop
            }
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
            default {
                "$statusName Unknown action: '$_'"
                break promptLoop
            }
        }
    }
}

# Invoke Script
Show-MainMenu