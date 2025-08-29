
# postgres-migrate-database.ps1
# Migrates a PostgreSQL database from version 12 to version 16


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
    [CmdletBinding()]
    param(
        [string]$OldVersion = "12",
        [int]$OldPort = 5432,
        [string]$NewVersion = "16",
        [int]$NewPort = 5434,
        [string]$Database = "quickweb-development",
        [string]$Username = "postgres",
        [string]$Server = "localhost",
        [string]$BackupFile = $Database + "_backup.dump"
    )


    Write-HostYellow "Dumping database '$Database' from PostgreSQL $OldVersion..."
    & Get-PgDumpPath -Version $OldVersion `
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
    &  Get-PgRestorePath -Version $NewVersion `
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
$oldversion = "12"
$newversion = "16"
$server = "localhost"
$username = "postgres"
[int]$oldport = 5432
[int]$newport = 5434
$databases = &  Get-PsqlPath -Version $oldversion -w --host=$server -p $oldport --username=$username -tAc "SELECT datname FROM pg_database WHERE datistemplate = false; "

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to retrieve databases from PostgreSQL 12."
    exit 1
}

$databases = $databases -split "`n" | Where-Object { $_.Trim() -ne "" }

foreach ($db in $databases) {
    if ($db -eq "postgres" -or $db -eq "template0" -or $db -eq "template1") {
        continue
    }
    Write-HostYellow "Migrating database: $db"
    Write-NewPostgresDatabase -Database $db -OldVersion $oldversion -OldPort $oldport -NewVersion $newversion -NewPort $newport -Username $username -Server $server
}
Write-HostYellow "All databases migrated."
# Migrate-PostgresDatabase -Database "quickweb-development"