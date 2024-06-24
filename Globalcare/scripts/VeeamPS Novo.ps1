try{
# Comando 1 Retorna os Jobs de Backup
Get-VBRJob -WarningAction SilentlyContinue |Where-Object { $_.IsScheduleEnabled -ge 'true' }| Select @{Name='Name';Expression={$_.Name}} , @{Name='LatestRunLocal';Expression={$_.LatestRunLocal}}, @{Name='Description';Expression={$_.Description}}, @{Name='IsRunning';Expression={$_.IsRunning}},@{Name='LatestStatus';Expression={$_.Info.LatestStatus}}, @{Name='TypeToString';Expression={$_.TypeToString}}| ConvertTo-json | Out-File -FilePath C:\globalcare\scripts\VBRJob.json

# Comando 2 Utilizado para saber quantas vms existe no JOB
Get-VBRBackup -WarningAction SilentlyContinue | Select @{Name='Name';Expression={$_.Info.Name}},@{Name='VmCount';Expression={$_.VmCount}} | ConvertTo-json | Out-File -FilePath C:\globalcare\scripts\VBRBackup.json

# Comando 3 Retorna os server que estão apresentados para a Console do Veeam
Get-VBRServer -WarningAction SilentlyContinue | ConvertTo-json | Out-File -FilePath C:\globalcare\scripts\VBRServer.json

# Comando 4 retorna os repositorios fisicos do backup
$repos = Get-VBRBackupRepository
$repoReport = @()
foreach ($repo in $repos) {
    $container = $repo.GetContainer()
    $totalSpace = [Math]::Round($container.CachedTotalSpace.InBytes)
    $freeSpace = [Math]::Round($container.CachedFreeSpace.InBytes)
    $repoReport += [PSCustomObject]@{
        Name = $repo.Name
        TotalSpace = $totalSpace
        FreeSpace = $freeSpace
    }
}
if ($repoReport.Count -eq 0) {
    Write-Host "Nenhum reposit rio encontrado ou nenhum valor dispon vel."
} else {
    $repoReport | ConvertTo-Json | Out-File -FilePath C:\globalcare\scripts\Repository.json
}

# Comando 5 retorna os repositorios Scale Out
$sobrs = Get-VBRBackupRepository -Scaleout
$sobrReport = @()
foreach ($sobr in $sobrs) {
    $extents = $sobr.Extent
    $totalSpace = $null
    $totalFreeSpace = $null
    foreach ($extent in $extents) {
        $repo = $extent.Repository
        $container = $repo.GetContainer()
        $totalSpace += [Math]::Round($container.CachedTotalSpace.InBytes)
        $totalFreeSpace += [Math]::Round($container.CachedFreeSpace.InBytes)
    }
    $sobrReport += $sobr | select Name, @{n='TotalSpace';e={$totalSpace}}, @{n='FreeSpace';e={$totalFreeSpace}}
}
$sobrReport | ConvertTo-Json | Out-File -FilePath C:\globalcare\scripts\RepositoryScaleOut.json


# Comando 6 Retorna os backups de Agent

$date = (Get-Date).AddHours(-24)
Get-VBRComputerBackupJobSession  | Get-VBRTaskSession | where {$_.JobSess.CreationTime -ge $date} | Where-Object { $_.IsScheduleEnabled -ge 'true' } |
    Group-Object {$_.Id} |
    ForEach-Object {
        $lastSession = $_.Group | Sort-Object {$_.JobSess.CreationTime} | Select-Object -Last 1
        $jobName = $lastSession.JobSess.OrigJobName -split '\('
        [PSCustomObject]@{
            JobName = $jobName[0]
            Resultado = $lastSession.JobSess.Result
            Reason = $lastSession.Info.Reason
            Creation = $lastSession.JobSess.CreationTime
            EndTime = $lastSession.JobSess.EndTime
            Name = $lastSession.Name
        }
    } |
    Sort-Object Name |
    ConvertTo-Json |
    Out-File -FilePath C:\globalcare\scripts\jobAgent.json

# Comando 7 Retorne os Jobs de Tape

Get-VBRTapeJob -WarningAction SilentlyContinue | Select @{Name='Name';Expression={$_.Name}} ,@{Name='LastResult';Expression={$_.LastResult}},@{Name='Description';Expression={$_.Description}},@{Name='NextRun';Expression={$_.NextRun}},@{Name='Enabled';Expression={$_.Enabled}}| Sort-Object Name | ConvertTo-Json | Out-File -FilePath C:\globalcare\scripts\VBRTapeJob.json

# Comando 8 Retorna os Jobs de Sure Backup
Get-VBRSureBackupJob|Select @{Name='Name';Expression={$_.Name}} , @{Name='LastRun';Expression={$_.LastRun}}, @{Name='Description';Expression={$_.Description}}, @{Name='NextRun';Expression={$_.NextRun}},@{Name='LastResult';Expression={$_.LastResult}}, @{Name='IsEnabled';Expression={$_.IsEnabled}}| ConvertTo-Json | Out-File -FilePath C:\globalcare\scripts\VBRSureBackupJob.json

#Comando 9 SQL BAckup Trasiction 

$date = (Get-Date).AddHours(-24)

# Função para obter e processar sessões de backup
function Get-BackupSessions {
    param (
        [string]$type
    )
    
    $sessions = @()
    
    $ids = Get-VBRSession -Type $type | Where-Object { $_.CreationTime -ge $date } | ForEach-Object { $_.Id }
    
    if ($ids) {
        foreach ($id in $ids) {
            $session = Get-VBRBackupSession -Id $id
            $sessions += $session
        }
    } else {}

    return $sessions
}

# Processar backups dos dois tipos
$endpointSqlLogBackups = Get-BackupSessions -type "EndpointSqlLogBackup"
$sqlLogBackups = Get-BackupSessions -type "SqlLogBackup"

# Combinar resultados e converter para JSON
$combinedBackups = $endpointSqlLogBackups + $sqlLogBackups

# Filtrar os jobs para obter apenas o mais recente para cada Name
$latestBackups = $combinedBackups | Group-Object {$_.JobName} | ForEach-Object {
    $_.Group | Sort-Object {$_.Progress.StartTimeLocal} -Descending | Select-Object -First 1
}

#Convert para JSON
$jsonOutput = $latestBackups |Select @{Name='Name';Expression={$_.JobName}} , @{Name='LatestRunLocal';Expression={$_.Progress.StartTimeLocal}},@{Name='LatestStatus';Expression={$_.Info.State}},@{Name='Result';Expression={$_.Info.Result}}| ConvertTo-Json

# Exibir o JSON
Write-Output $jsonOutput |Out-File -FilePath "C:\Globalcare\scripts\sqlLog.json"

#Comando 10 Oracle BAckup Transaction
$date = (Get-Date).AddHours(-24)
# Função para obter e processar sessões de backup
function Get-BackupSessions {
    param (
        [string]$type
    )
    $sessions = @()
    $ids = Get-VBRSession -Type $type | Where-Object { $_.CreationTime -ge $date } | ForEach-Object { $_.Id }
    if ($ids) {
        foreach ($id in $ids) {
            $session = Get-VBRBackupSession -Id $id
            $sessions += $session
        }
    } else {}
    return $sessions
}
# Processar backups dos dois tipos
$endpointOracleLogBackups = Get-BackupSessions -type "EndpointOracleLogBackup"
$OracleLogBackups = Get-BackupSessions -type "OracleLogBackup"
$OracleRMAN = Get-BackupSessions -type "OracleRMANBackup"
# Combinar resultados
$combinedBackups = $endpointOracleLogBackups + $OracleLogBackups + $OracleRMAN
# Filtrar os jobs para obter apenas o mais recente para cada Name
$latestBackups = $combinedBackups | Group-Object {$_.JobName} | ForEach-Object {
    $_.Group | Sort-Object {$_.Progress.StartTimeLocal} -Descending | Select-Object -First 1
}
# Converter para JSON
$jsonOutput = $latestBackups | Select-Object @{Name='Name';Expression={$_.JobName}} , @{Name='LatestRunLocal';Expression={$_.Progress.StartTimeLocal}}, @{Name='LatestStatus';Expression={$_.Info.State}}, @{Name='Result';Expression={$_.Info.Result}} | ConvertTo-Json
# Exibir o JSON
Write-Output $jsonOutput | Out-File -FilePath "C:\Globalcare\scripts\OracleLog.json"



#Zabbix Sender que envia a informação se o Script Executou.

C:\Globalcare\bin\win64\zabbix_sender.exe -vv -c C:\globalcare\conf\zabbix_agent2.conf -s SRV-BB-BKP01  -k resultjob.veeam  -o 1

}catch{
C:\Globalcare\bin\win64\zabbix_sender.exe -vv -c C:\globalcare\conf\zabbix_agent2.conf -s SRV-BB-BKP01  -k resultjob.veeam  -o 0
}