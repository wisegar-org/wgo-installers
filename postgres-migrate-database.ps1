
# postgres-migrate-database.ps1
# Migrates a PostgreSQL database from version 12 to version 16

[CmdletBinding()]
param(
    [string]$oldversion = "12",
    [string]$newversion = "16",
    [string]$server = "localhost",
    [string]$username = "postgres",
    [int]$oldport = 5432,
    [int]$newport = 5434
)

# Redirect all output to a log file
$logFile = "postgres-migrate-database.log"
Start-Transcript -Path $logFile -Append

# Ensure pgpass file exists
function Write-Ensure-PgpassFile {
    $pgpassPath = "$env:APPDATA\PostgreSQL\pgpass.conf"
    if (-not (Test-Path $pgpassPath)) {
        New-Item -Path $pgpassPath -ItemType File -Force | Out-Null
        Write-HostYellow "pgpass file created at $pgpassPath. Please edit it with your credentials."
        Invoke-Item $pgpassPath
        exit 0
    }
}
# Get the path to pg_restore for a specific PostgreSQL version
function Get-PgRestorePath {
    param(
        [string]$Version
    )
    $pgRestorePath = "C:\Program Files\PostgreSQL\$Version\bin\pg_restore.exe"
    if (-not (Test-Path $pgRestorePath)) {
        Write-Error "pg_restore.exe not found for PostgreSQL version $Version at $pgRestorePath"
        exit 1
    }
    return $pgRestorePath
}
# Get the path to dropdb for a specific PostgreSQL version
function Get-DropdbPath {
    param(
        [string]$Version
    )
    $dropdbPath = "C:\Program Files\PostgreSQL\$Version\bin\dropdb.exe"
    if (-not (Test-Path $dropdbPath)) {
        Write-Error "dropdb.exe not found for PostgreSQL version $Version at $dropdbPath"
        exit 1
    }
    return $dropdbPath
}
# Get the path to createdb for a specific PostgreSQL version
function Get-CreatedbPath {
    param(
        [string]$Version
    )
    $createdbPath = "C:\Program Files\PostgreSQL\$Version\bin\createdb.exe"
    if (-not (Test-Path $createdbPath)) {
        Write-Error "createdb.exe not found for PostgreSQL version $Version at $createdbPath"
        exit 1
    }
    return $createdbPath
}
# Get the path to psql for a specific PostgreSQL version
function Get-PsqlPath {
    param(
        [string]$Version
    )
    $psqlPath = "C:\Program Files\PostgreSQL\$Version\bin\psql.exe"
    if (-not (Test-Path $psqlPath)) {
        Write-Error "psql.exe not found for PostgreSQL version $Version at $psqlPath"
        exit 1
    }
    return $psqlPath
}
# Get the path to pg_dump for a specific PostgreSQL version
function Get-PgDumpPath {
    param(
        [string]$Version
    )
    $pgDumpPath = "C:\Program Files\PostgreSQL\$Version\bin\pg_dump.exe"
    if (-not (Test-Path $pgDumpPath)) {
        Write-Error "pg_dump.exe not found for PostgreSQL version $Version at $pgDumpPath"
        exit 1
    }
    return $pgDumpPath
}
function Write-HostYellow {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Write-NewPostgresDatabase {
    param(
        [string]$OldVersion,
        [int]$OldPort,
        [string]$NewVersion,
        [int]$NewPort,
        [string]$Database,
        [string]$Username,
        [string]$Server,
        [string]$BackupFile = $Database + "_backup.dump"
    )


    Write-HostYellow "Dumping database '$Database' from PostgreSQL $OldVersion..."
    $PgDumpPath = Get-PgDumpPath -Version $OldVersion
    & $PgDumpPath `
        --host=$Server `
        -p $OldPort `
        -w `
        --username=$Username `
        --clean `
        --format=tar `
        --file=$BackupFile `
        $Database

    if ($LASTEXITCODE -ne 0) {
        Write-Error "pg_dump failed. Migration aborted."
        exit 1
    }

    Write-HostYellow "Checking if database '$Database' exists on PostgreSQL $NewVersion..."
    $psqlPath = Get-PsqlPath -Version $NewVersion
    $createdbPath = Get-CreatedbPath -Version $NewVersion
    $dbExists = & $psqlPath --host=$Server -p $NewPort --username=$Username -tAc "SELECT 1 FROM pg_database WHERE datname='$Database';"

    if (-not $dbExists) {
        Write-HostYellow "Database '$Database' does not exist on PostgreSQL $NewVersion. Creating..."
        & $createdbPath -w --host=$Server -p $NewPort --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create database '$Database' on PostgreSQL $NewVersion. Migration aborted."
            exit 1
        }
        Write-HostYellow "Database '$Database' created successfully on PostgreSQL $NewVersion."
    } 
    else {
        
        Write-HostYellow "Database '$Database' already exists on PostgreSQL $NewVersion."
        Write-HostYellow "Dropping existing database '$Database' on PostgreSQL $NewVersion..."
        $dropdbPath = Get-DropdbPath -Version $NewVersion
        & $dropdbPath -w --host=$Server -p $NewPort --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to drop database '$Database' using dropdb. Migration aborted."
            exit 1
        }
        Write-HostYellow "Database '$Database' dropped successfully on PostgreSQL $NewVersion."
        & $createdbPath -w --host=$Server -p $NewPort --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to recreate database '$Database' on PostgreSQL $NewVersion. Migration aborted."
            exit 1
        }
        Write-HostYellow "Database '$Database' recreated successfully on PostgreSQL $NewVersion."
    }

    Write-HostYellow "Restoring database '$Database' to PostgreSQL $NewVersion..."
    $PgRestorePath = Get-PgRestorePath -Version $NewVersion 
    &  $PgRestorePath `
        --host=$Server `
        -p $NewPort `
        -w `
        --username=$Username `
        --dbname=$Database `
        --verbose `
        $BackupFile

    if ($LASTEXITCODE -ne 0) {
        Write-Error "pg_restore failed. Migration aborted."
    }
    else {
        Write-Host "Migration completed successfully."
    }
}

# Get all databases from PostgreSQL 12
function Write-AllDatabase {
    param(
        [string]$OldVersion,
        [int]$OldPort,
        [string]$NewVersion,
        [int]$NewPort,
        [string]$Username,
        [string]$Server
    )

    # Write-HostYellow "Ensuring pgpass file exists..."
    Write-Ensure-PgpassFile
    $psqlPath = Get-PsqlPath -Version $OldVersion
    $databases = &  $psqlPath -w --host=$Server -p $OldPort --username=$Username -tAc "SELECT datname FROM pg_database WHERE datistemplate = false; "

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to retrieve databases from PostgreSQL $OldVersion."
        exit 1
    }

    $databases = $databases -split "`n" | Where-Object { $_.Trim() -ne "" }

    foreach ($db in $databases) {
        if ($db -eq "postgres" -or $db -eq "template0" -or $db -eq "template1") {
            continue
        }
        Write-HostYellow "Migrating database: $db"
        Write-NewPostgresDatabase -Database $db -OldVersion $OldVersion -OldPort $OldPort -NewVersion $NewVersion -NewPort $NewPort -Username $Username -Server $Server
    }
    Write-HostYellow "All databases migrated."
}

Write-AllDatabase -OldVersion $oldversion -OldPort $oldport -NewVersion $newversion -NewPort $newport -Username $username -Server $server
