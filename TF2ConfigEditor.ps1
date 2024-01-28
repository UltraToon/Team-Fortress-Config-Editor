$ErrorActionPreference = 'stop'
$TF2 = "C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2"
if (!(Test-Path $TF2)) {'[ERROR] Please install TF2! Press [ENTER] to exit.'; $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null; exit}
do {
    $mainOptions = Read-Host -prompt "
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ~       ____             __ _         _____    _ _ _                  ~
    ~      / ___|___  _ __  / _(_) __ _  | ____|__| (_) |_ ___  _ __      ~
    ~     | |   / _ \| '_ \| |_| |/ _` | |  _| / _` | | __/ _ \| '__|     ~
    ~     | |__| (_) | | | |  _| | (_| | | |__| (_| | | || (_) | |        ~
    ~      \____\___/|_| |_|_| |_|\__, | |_____\__,_|_|\__\___/|_|        ~
    ~                             |___/                                   ~
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    > Manage:
        [1] Manage Presets [tf/custom]
        [2] Manage Bases [tf/cfg]

    > Other:
        [3] What is this?
        [4] Reset TF2
    "
} until ($mainOptions -in 1..4)
Clear-Host
if ($mainOptions -eq 1) {
    $presetFile = 'TF2CE/Presets.cfg'
    $presetMenu = "
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ~      ____                     _     __  __                                        ~
    ~     |  _ \ _ __ ___  ___  ___| |_  |  \/  | __ _ _ __   __ _  __ _  ___ _ __      ~
    ~     | |_) | '__/ _ \/ __|/ _ \ __| | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|     ~
    ~     |  __/| | |  __/\__ \  __/ |_  | |  | | (_| | | | | (_| | (_| |  __/ |        ~
    ~     |_|   |_|  \___||___/\___|\__| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|        ~
    ~                                                              |___/                ~
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    > Manage:
        [1] Upload a preset

    > Select:
        {0} 

    "
    if (!(Test-Path $presetFile)) {$null = New-Item $presetFile -Force}
    $map = @{}; $counter = 2
    $addToMenu = Get-Content $presetFile | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        '[{0}] {1}' -f $counter++, $leaf
    }
    $selection = Read-Host ($presetMenu -f ($addToMenu -join [System.Environment]::NewLine))
    if ($selection -eq 1) {
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dialogResult = $folderDialog.ShowDialog()
        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            Add-Content $presetFile -Value $folderDialog.SelectedPath
        } else {Write-Error "User chose Cancel"}
    } elseif ($selection -ge 2) {
        'Cleaning up...'
        Remove-Item "$TF2\tf\custom" -Force -Recurse -ErrorAction SilentlyContinue
        'Applying preset...'
        Copy-Item $map[$selection] "$TF2\tf\custom" -Recurse -Force
    }
} elseif ($mainOptions -eq 2) {
    $baseFile = 'TF2CE/Bases.cfg'
    $baseMenu = "
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ~      ____                   __  __                                        ~
    ~     | __ )  __ _ ___  ___  |  \/  | __ _ _ __   __ _  __ _  ___ _ __      ~
    ~     |  _ \ / _` / __|/ _ \ | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|     ~
    ~     | |_) | (_| \__ \  __/ | |  | | (_| | | | | (_| | (_| |  __/ |        ~
    ~     |____/ \__,_|___/\___| |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|        ~
    ~                                                      |___/                ~
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    > Manage:
        [1] Upload a base

    > Select:
        {0} 

    "
    if (!(Test-Path $baseFile)) {$null = New-Item $baseFile -Force}
    $map = @{}; $counter = 2
    $addToMenu = Get-Content $baseFile | ForEach-Object {
        $leaf = Split-Path $_ -Leaf
        $map[$counter.ToString()] = "$_"
        '[{0}] {1}' -f $counter++, $leaf
    }
    $selection = Read-Host ($baseMenu -f ($addToMenu -join [System.Environment]::NewLine))
    if ($selection -eq 1) {
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dialogResult = $folderDialog.ShowDialog()
        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            Add-Content $baseFile -Value $folderDialog.SelectedPath
        } else {Write-Error "User chose Cancel"}
    } elseif ($selection -ge 2) {
        'Cleaning up...'
        Remove-Item "$TF2\tf\cfg\overrides" -Force -Recurse -ErrorAction SilentlyContinue
        'Applying base...'
        Copy-Item $map[$selection] "$TF2\tf\" -Recurse -Force
    }
}
elseif ($mainOptions -eq 3) {
    $null = Read-Host -prompt '
    > Presets:
        - They are basically swappable, renamable, duplicates of your [tf/custom] folder (huds, mods, cfg, sounds etc.,)
        - They can be anywhere on your PC, just load them in. It does it for you after that.
        - Just open the Preset Manager, choose "[1] Upload a preset", then reload the script. It should be there now.
    
    > Bases:
        - Just like presets, but with your CFG folders, I decided to do this seperately for modularity reasons.
        - It is STRONGLY recommended to use mastercomfigs overrides method (tf/cfg/overrides/yourcfgfiles). If not already, install mastercomfig.
        - It is the same process as uploading presets, just choose the "Manage Bases" option.
    
    > Reset TF2:
        - Hence the name, it resets TF2 of its configuration and files. This does not modify account data since its saved in the cloud.
        - Its useful to fix your game if its broken in a way, or have a fresh new start to make a config.
        - If you have things you care about in the TF folder, then back them up to another location outside of the game folder.
    
        Press [ENTER] to exit
        '
} elseif ($mainOptions -eq 4) {
    $null = Read-Host -prompt '
    !!! PLEASE BACKUP YOUR CFG AND CUSTOM FOLDER IF YOU WANT TO KEEP SETTINGS !!!
    > It will NOT reset account data (LVLS, ITEMS, ETC.,)
       +==================+
       | [ENTER] Continue |
       | [CTRL+C] Cancel  |
       +==================+
    '
    Clear-Host
    Remove-Item "$TF2\tf\custom\*", "$TF2\tf\cfgs" -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem "C:\Program Files (x86)\Steam\userdata\*\440\remote\cfg\config.cfg" | Set-content -Value $null
    Start-Process steam://validate/440
    "Doing a file validation check! It should show the [PLAY] button once finished."
    $null = Read-Host -prompt "Press [ENTER] when the process is done"
    Start-Process -filepath "$TF2\hl2.exe" -argumentlist "-novid -autoconfig -default +host_writeconfig config.cfg full +mat_savechanges +quit -game tf" -wait
}
Clear-Host
'~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~                                                   ~
~      ____  _   _  ____ ____ _____ ____ ____       ~
~     / ___|| | | |/ ___/ ___| ____/ ___/ ___|      ~
~     \___ \| | | | |  | |   |  _| \___ \___ \      ~
~      ___) | |_| | |__| |___| |___ ___) |__) |     ~
~     |____/ \___/ \____\____|_____|____/____/      ~
~                                                   ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Press [ENTER] to exit                                       
'
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null