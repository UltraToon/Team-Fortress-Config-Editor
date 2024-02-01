$ErrorActionPreference = 'stop'
$TF2 = "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2"
Add-Type -AssemblyName System.Windows.Forms
$null = New-Item "$env:USERPROFILE\Documents\TF2CE\" -Force -ItemType "directory"
if (!(Test-Path $TF2)) {"[ERROR] Please install TF2!"; cmd /c 'pause'; exit}
$genArgs = @{
    Force = $true
    Recurse = $true
    ErrorAction = "SilentlyContinue"
}

function DynamicLoad {
    [cmdletbinding()]
    param (
        [string]$cfgFile = "$cfgFile"
    )
    if (!(Test-Path $cfgFile)) {return}
    $Script:map = @{}; $Script:counter = 3
    Get-Content $cfgFile | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        "`t[{0}] {1}" -f $counter++, $leaf
    }
}

function MainMenu{
    Clear-Host
    $mainMenu = Read-Host -prompt @'
    ┌───────────────────────────────────────────────────────────────────────────────┐
    │                                                                               │
    │       __   ____             __ _         _____    _ _ _              __       │
    │      / /  / ___|___  _ __  / _(_) __ _  | ____|__| (_) |_ ___  _ __  \ \      │
    │     / /  | |   / _ \| '_ \| |_| |/ _` | |  _| / _` | | __/ _ \| '__|  \ \     │
    │     \ \  | |__| (_) | | | |  _| | (_| | | |__| (_| | | || (_) | |     / /     │
    │      \_\  \____\___/|_| |_|_| |_|\__, | |_____\__,_|_|\__\___/|_|    /_/      │
    │                                  |___/                                        │
    │                                                                               │
    └───────────────────────────────────────────────────────────────────────────────┘

    ! When applying any of these, the corresponding folders in your TF2 game will get removed for clean up !
    > Manage:
        [1] Manage Presets [custom]
        [2] Manage Bases [cfg]
        [3] Manage Huds [custom]

    > Other:
        [4] What is this?
        [5] Reset TF2
        [CTRL+C] Exit

'@
    return $mainMenu
}
function PresetManager {
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\Presets.cfg"
    $presetMenu = @'
    ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                             │
    │       __  ____                     _     __  __                                    __       │
    │      / / |  _ \ _ __ ___  ___  ___| |_  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  | |_) | '__/ _ \/ __|/ _ \ __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  |  __/| | |  __/\__ \  __/ |_  | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |_|   |_|  \___||___/\___|\__| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                                   |___/                     │
    │                                                                                             │
    └─────────────────────────────────────────────────────────────────────────────────────────────┘

    > Manage:
        [1] Upload a preset
        [2] Back to Main Menu
        
    > Select:
    {0}

'@  
    $addToMenu = DynamicLoad
    $selection = Read-Host ($presetMenu -f ($addToMenu -join [System.Environment]::NewLine))
    switch ($selection) {
        1 {
            $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            $dialogResult = $folderDialog.ShowDialog()
            if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                Add-Content $cfgFile -Value $folderDialog.SelectedPath
                return 2
            } else {return 2}
        }
        2 {return 1}
        {$_ -ge $counter}{
            'Cleaning up...'
            Remove-Item "$TF2\tf\custom" @genArgs
            'Applying preset...'
            Copy-Item $map[$selection] "$TF2\tf\custom" -Recurse -Force
        }
    }
}

function BaseManager{
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\Bases.cfg"
    $baseMenu = @'
    ┌─────────────────────────────────────────────────────────────────────────────────────┐
    │                                                                                     │
    │       __  ____                   __  __                                    __       │
    │      / / | __ )  __ _ ___  ___  |  \/  | __ _ _ __   __ _  __ _  ___ _ __  \ \      │
    │     / /  |  _ \ / _` / __|/ _ \ | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|  \ \     │
    │     \ \  | |_) | (_| \__ \  __/ | |  | | (_| | | | | (_| | (_| |  __/ |     / /     │
    │      \_\ |____/ \__,_|___/\___| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|    /_/      │
    │                                                           |___/                     │
    │                                                                                     │
    └─────────────────────────────────────────────────────────────────────────────────────┘
    
    > Manage:
        [1] Upload a base
        [2] Back to Main Menu

    > Select:
    {0} 

'@  
    $addToMenu = DynamicLoad
    $selection = Read-Host ($baseMenu -f ($addToMenu -join [System.Environment]::NewLine))
    switch ($selection) {
        1 {
            $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            $dialogResult = $folderDialog.ShowDialog()
            if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                Add-Content $cfgFile -Value $folderDialog.SelectedPath -Force
                return 2
            } else {return 2}
        }
        2 {return 1}
        {$_ -ge $counter} {
            'Cleaning up...'
            Remove-Item "$TF2\tf\cfg\overrides","$TF2\tf\cfg\autoexec.cfg" @genArgs
            'Applying base...'
            Copy-Item $map[$selection] "$TF2\tf\cfg" -Recurse -Force
        }
    }
}

function HUDManager {
    Clear-Host
    $cfgFile = "$env:USERPROFILE\Documents\TF2CE\HUDs.cfg"
    $hudMenu = @'
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

    > Manage:
        [1] Upload a HUD
        [2] Back to Main Menu

    > Select:
    {0} 

'@  
    $addToMenu = DynamicLoad
    $selection = Read-Host ($hudMenu -f ($addToMenu -join [System.Environment]::NewLine))
    switch ($selection) {
        1 {
            $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            $dialogResult = $folderDialog.ShowDialog()
            if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                Add-Content $cfgFile -Value $folderDialog.SelectedPath -Force
                return 2
            } else {return 2}
        }
        2 {return 1}
        {$_ -ge $counter} {
            'Cleaning up...'
            (Get-ChildItem "$TF2\tf\custom" -filter 'info.vdf' -Recurse) | Remove-Item -LiteralPath {$_.DirectoryName} @genArgs
            'Applying HUD...'
            Copy-Item $map[$selection] "$TF2\tf\custom\" -Recurse -Force
        }
    }
}
        

        
function FAQ {
    Clear-Host
    $faq = Read-Host -prompt @'
    To remove any of these below, go to your documents and open the corresponding file and remove the line, or delete it. :P
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    > Presets:
        - They are basically swappable and renamable profiles of the custom folder
        - They can be anywhere on your PC, just upload and select them through the manager.
        - Perfect for scene changes of switching competetive or a casual preset for example.
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    > Bases:
        - Just like presets, but with your CFG folders, I decided to do this seperately for modularity reasons.
        - It is STRONGLY recommended to use mastercomfigs overrides method (tf\cfg\overrides\yourcfgfiles)
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    > Huds:
        - Just like presets, but with your HUDs! I decided to do this seperately for modularity reasons.
        - As of now, you cant nit and pick multiple huds on top in your TF folder, instead:
            Copy and paste your other hud folders ontop of your main one
            It should be the same effect as loading multiple
        - Support for this will be added soon ^
        ────────────────────────────────────────────────────────────────────────────────────────────────────────
    > Reset TF2:
        - You can reset TF2 of its configurations or completely. Useful for fixing issues or starting fresh for configuration.
        - This does not modify account data since its saved in the cloud.
        ! Please backup folders you want to keep from the TF folder !
      <────────────────────────────────────────────────────────────────────────────────────────────────────────>
    > Manage
        [1] Open Github [Link]
        [2] Back to Main Menu

'@
    switch ($faq) {
        1 {Start-Process 'https://github.com/UltraToon/TF2PresetChooser'; return 4}
        2 {return 1}       
    }
    return $faq
}

function ResetTF2 {
    Clear-Host
    do {
        $resetTF2 = Read-Host -prompt @'
    ┌───────────────────────────────────────────────────────┐
    │      !Backup folders you want from the TF folder!     │
    │      ____                _     _____ _____ ____       │
    │     |  _ \ ___  ___  ___| |_  |_   _|  ___|___ \      │
    │     | |_) / _ \/ __|/ _ \ __|   | | | |_    __) |     │
    │     |  _ <  __/\__ \  __/ |_    | | |  _|  / __/      │
    │     |_| \_\___||___/\___|\__|   |_| |_|   |_____|     │
    │    Does not reset account data (lvls, items, stats)   │
    └───────────────────────────────────────────────────────┘

    > Manage
    [1] Back to Main Menu
    [CTRL+C] Exit

    > Reset TF2
    [2] Clean out configs [cfg,custom] [Only works with mastercomfig!]
    [3] Complete reset [Fixes issue, clean refresh]

'@  
        } until ($resetTF2 -in 1..3)
        Clear-Host
        switch ($resetTF2) {
            1 {MainMenu}
            2 {
                'Clearing cfg and custom...'
                Remove-Item "$TF2\tf\custom\*", "$TF2\tf\cfg\overrides" @genArgs
            }
            3 {
                Remove-Item "$TF2\tf\custom\*", "$TF2\tf\cfg" @genArgs
                Get-ChildItem "C:\Program Files (x86)\Steam\userdata\*\440\remote\cfg\config.cfg" | Set-content -Value $null
                Start-Process steam://validate/440
                $null = Read-Host -prompt "A green [PLAY] button should appear once finished`nPress any key when the process is done`n"
                Start-Process -filepath "$TF2\hl2.exe" -argumentlist "-novid -autoconfig -default +host_writeconfig config.cfg full +mat_savechanges +quit -game tf" -wait
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

Clear-Host
@'
    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │       __  ____   More Features Coming Soon!  __       │
    │      / / / ___| _   _  ___ ___ ___  ___ ___  \ \      │
    │     / /  \___ \| | | |/ __/ __/ _ \/ __/ __|  \ \     │
    │     \ \   ___) | |_| | (_| (_|  __/\__ \__ \  / /     │
    │      \_\ |____/ \__,_|\___\___\___||___/___/ /_/      │
    │               PRESS ANY KEY TO EXIT                   │
    └───────────────────────────────────────────────────────┘                              
'@
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null