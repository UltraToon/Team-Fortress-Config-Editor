$ErrorActionPreference = 'stop'
$TF2 = "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2"
Add-Type -AssemblyName System.Windows.Forms
if (!(Test-Path $TF2)) {
    "[ERROR] Please install TF2!"
    cmd /c 'pause'
    exit
}
$genArgs = @{
    Force = $true
    Recurse = $true
    ErrorAction = "SilentlyContinue"
}

function DynamicMenuLoad {
    [cmdletbinding()]
    param (
        [string]$cfgFile = "$cfgFile",
        [string]$menu = "$menu"
    )
    if (!(Test-Path $cfgFile)) {$null = New-Item $cfgFile -Force}
    $script:map = @{}; $script:counter = 2
    $addToMenu = Get-Content $cfgFile | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        "`t[{0}] {1}" -f $counter++, $leaf
    }
    Read-Host ($menu -f ($addToMenu -join [System.Environment]::NewLine))
}
function UploadFolder {
    [cmdletbinding()]
    param (
        [string]$cfgFile = "$cfgFile"
    )
    $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
    $dialogResult = $folderDialog.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        Add-Content $cfgFile -Value $folderDialog.SelectedPath
        Invoke-Expression (Get-PSCallStack)[1].FunctionName
    } else {Invoke-Expression (Get-PSCallStack)[1].FunctionName}
}

function MainMenu{
    Clear-Host
    $mainMenu = Read-Host -prompt @'
    ┌───────────────────────────────────────────────────────────────────────────────┐
    │                     Welcome to my Team Fortress 2                             │
    │       __   ____             __ _         _____    _ _ _              __       │
    │      / /  / ___|___  _ __  / _(_) __ _  | ____|__| (_) |_ ___  _ __  \ \      │
    │     / /  | |   / _ \| '_ \| |_| |/ _` | |  _| / _` | | __/ _ \| '__|  \ \     │
    │     \ \  | |__| (_) | | | |  _| | (_| | | |__| (_| | | || (_) | |     / /     │
    │      \_\  \____\___/|_| |_|_| |_|\__, | |_____\__,_|_|\__\___/|_|    /_/      │
    │                                  |___/                                        │
    │                More features coming soon! By UltraToon.                       │
    └───────────────────────────────────────────────────────────────────────────────┘

    Applying any manage tools will clear the corresponding folders!
    ❯ Manage:
        [1] Manage Presets [custom]
        [2] Manage Bases [cfg]
        [3] Manage Huds [custom]

    ❯ Other:
        [4] What is this?
        [5] Reset TF2

        [CTRL+C] Exit

'@
    return $mainMenu
}
function PresetManager {
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\Presets.cfg"
    $menu = @'
    ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                             │
    │       __  ____                     _     __  __                                    __       │
    │      / / |  _ \ _ __ ___  ___  ___| |_  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  | |_) | '__/ _ \/ __|/ _ \ __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  |  __/| | |  __/\__ \  __/ |_  | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |_|   |_|  \___||___/\___|\__| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                                   |___/                     │
    │                     Swappable, renamable tf/custom folders!                                 │
    └─────────────────────────────────────────────────────────────────────────────────────────────┘
    
    ❯ Navigate:
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Upload a preset
        
    ❯ Select:
    {0}

'@  
    switch (DynamicMenuLoad) {
        0 {
            MainMenu
        }
        1 {
            UploadFolder
        }
        {$_ -ge $counter} {
            'Cleaning up...'
            Remove-Item "$TF2\tf\custom" @genArgs
            'Applying preset...'
            Copy-Item $map[$_] "$TF2\tf\custom" -Recurse -Force
            PresetManager
        }
    }
}

function BaseManager{
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\Bases.cfg"
    $menu = @'
    ┌─────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                     │
    │       __  ____                   __  __                                    __       │
    │      / / | __ )  __ _ ___  ___  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  |  _ \ / _` / __|/ _ \ | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  | |_) | (_| \__ \  __/ | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |____/ \__,_|___/\___| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                           |___/                     │
    │             We strongly recommend using MasterComfig overrides!                     │
    └─────────────────────────────────────────────────────────────────────────────────────┘
    
    ❯ Navigate:
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Upload a base
        [2] Remove a base

    ❯ Select:
    {0} 

'@  
    switch (DynamicMenuLoad) {
        0 {
            MainMenu
        }
        1 {
            UploadFolder
        }
        {$_ -ge $counter} {
            'Cleaning up...'
            Remove-Item "$TF2\tf\cfg\overrides, $TF2\tf\cfg\autoexec" @genArgs
            'Applying base...'
            Copy-Item $map[$_] "$TF2\tf\" -Recurse -Force
            BaseManager
        }
    }
}

function HUDManager {
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\HUDs.cfg"
    $menu = @'
    ┌──────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                  │
    │       __  _   _ _   _ ____    __  __                                    __       │
    │      / / | | | | | | |  _ \  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  | |_| | | | | | | | | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  |  _  | |_| | |_| | | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |_| |_|\___/|____/  |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                        |___/                     │
    │                 We recommend to store your huds in a folder!                     │
    └──────────────────────────────────────────────────────────────────────────────────┘

    ❯ Navigate:
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Upload a HUD

    ❯ Select:
    {0} 

'@  
    switch (DynamicMenuLoad) {
        0 {
            MainMenu
        }
        1 {
            UploadFolder
        }
        {$_ -ge $counter} {
            'Cleaning up...'
            (Get-ChildItem "$TF2\tf\custom" -filter 'info.vdf' -Recurse) | Remove-Item -LiteralPath {$_.DirectoryName} @genArgs
            'Applying HUD...'
            Copy-Item $map[$_] "$TF2\tf\custom\" -Recurse -Force
            HUDManager
        }
    }
}
        
        
function FAQ {
    Clear-Host
    $faq = Read-Host -prompt @'
    To remove any of these below, go to your documents and open the corresponding file and remove the line, or delete it. :P
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Presets:
        - They are basically swappable and renamable profiles of the custom folder
        - They can be anywhere on your PC, just upload and select them through the manager.
        - Perfect for scene changes of switching competetive or a casual preset for example.
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Bases:
        - Just like presets, but with your CFG folders, I decided to do this seperately for modularity reasons.
        - It is STRONGLY recommended to use mastercomfigs overrides method (tf\cfg\overrides\yourcfgfiles)
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Huds:
        - Just like presets, but with your HUDs! I decided to do this seperately for modularity reasons.
        - As of now, you cant have multiple HUDs loaded, so just drop the folders onto each other (by which is your main first)
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    ❯ Reset TF2:
        - You can reset TF2 of its configurations or completely. Useful for fixing issues or starting fresh for configuration.
        - This does not modify account data since its saved in the cloud.
        ! Please backup folders you want to keep from the TF folder !
      <────────────────────────────────────────────────────────────────────────────────────────────────────────>
    ❯ Navigate:
        [0] Back to Main Menu
        [CTRL+C] Exit

    ❯ Manage:
        [1] Open Github [Link]
        [2] Open MasterComfig [Link]

'@
    switch ($faq) {
        0 {
            MainMenu
        }
        1 {
            Start-Process 'https://github.com/UltraToon/TF2PresetChooser'
            FAQ
        }
        2 {
            Start-Process 'https://mastercomfig.com/'
            FAQ
        }
        default {
            FAQ
        }
    }
}

function ResetTF2 {
    param (
        [string]$status
    )

    Clear-Host
    $resetTF2 = Read-Host -prompt (@'
    ┌───────────────────────────────────────────────────────┐
    │      !Backup folders you want from the TF folder!     │
    │      ____                _     _____ _____ ____       │
    │     |  _ \ ___  ___  ___| |_  |_   _|  ___|___ \      │
    │     | |_) / _ \/ __|/ _ \ __|   | | | |_    __) |     │
    │     |  _ <  __/\__ \  __/ |_    | | |  _|  / __/      │
    │     |_| \_\___||___/\___|\__|   |_| |_|   |_____|     │
    │    Does not reset account data (lvls, items, stats)   │
    └───────────────────────────────────────────────────────┘
    {0}
    ❯ Navigate:
    [0] Back to Main Menu
    [CTRL+C] Exit

    ❯ Reset TF2:
    [1] Clean out configs [cfg (comfig only)/custom]
    [2] Complete reset [Fixes issue, clean refresh]

'@  -f "`t`t$status") 
    Clear-Host
    switch ($resetTF2) {
        0 {
            MainMenu
        }
        1 {
            'Clearing cfg\overrides and custom...'
            Remove-Item "$TF2\tf\custom\*", "$TF2\tf\cfg\overrides" @genArgs
            ResetTF2 -status "❯ Configs Cleaned! ❮"

        }
        2 {
            Remove-Item "$TF2\tf\custom\*", "$TF2\tf\cfg" @genArgs
            Get-ChildItem "C:\Program Files (x86)\Steam\userdata\*\440\remote\cfg\config.cfg" | Set-content -Value $null
            Start-Process steam://validate/440
            $null = Read-Host -prompt @'
            ❯ VALIDATING FILES ❮
    Press any key once you see this button:

                ┌────────┐
                │ ▶ PLAY │
                └────────┘
'@
            Start-Process -filepath "$TF2\hl2.exe" -argumentlist "-novid -autoconfig -default +host_writeconfig config.cfg full +mat_savechanges +quit -game tf" -wait
            ResetTF2 -status "❯ TF2 Reset! ❮"
        }
    }
}

do {
    $response = MainMenu
    $response = switch ($response) {
        1 {PresetManager}
        2 {BaseManager}
        3 {HUDManager}
        4 {FAQ}
        5 {ResetTF2}
    }
} while ($response -in 1..5)