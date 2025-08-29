# postgres-migrate-database.ps1
# Migrates a PostgreSQL database from version 12 to version 16

function Migrate-PostgresDatabase {
    [CmdletBinding()]
    param(
        [string]$OldVersion = "12",
        [string]$NewVersion = "16",
        [string]$Database = "quickweb-development",
        [string]$Username = "postgres",
        [string]$Server = "localhost",
        [string]$BackupFile = $Database + "_backup.dump"
    )

    Write-Host "Dumping database '$Database' from PostgreSQL $OldVersion..."
    & "C:\Program Files\PostgreSQL\$OldVersion\bin\pg_dump.exe" `
        --host=$Server `
        -p 5432 `
        -W `
        --username=$Username `
        --clean `
        --format=tar `
        --file=$BackupFile `
        $Database

    if ($LASTEXITCODE -ne 0) {
        Write-Error "pg_dump failed. Migration aborted."
        exit 1
    }

    Write-Host "Checking if database '$Database' exists on PostgreSQL $NewVersion..."
    $psqlPath = "C:\Program Files\PostgreSQL\$NewVersion\bin\psql.exe"
    $createdbPath = "C:\Program Files\PostgreSQL\$NewVersion\bin\createdb.exe"
    $dbExists = & $psqlPath --host=$Server -p 5434 --username=$Username -tAc "SELECT 1 FROM pg_database WHERE datname='$Database';"

    if (-not $dbExists) {
        Write-Host "Database '$Database' does not exist on PostgreSQL $NewVersion. Creating..."
        & $createdbPath -w  passfile="C:\.pgpass"   --host=$Server -p 5434 --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create database '$Database' on PostgreSQL $NewVersion. Migration aborted."
            exit 1
        }
        Write-Host "Database '$Database' created successfully on PostgreSQL $NewVersion."
    } 
    else {
        
        Write-Host "Database '$Database' already exists on PostgreSQL $NewVersion."
        Write-Host "Dropping existing database '$Database' on PostgreSQL $NewVersion..."
        $dropdbPath = "C:\Program Files\PostgreSQL\$NewVersion\bin\dropdb.exe"
        & $dropdbPath -w  --host=$Server -p 5434 --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to drop database '$Database' using dropdb. Migration aborted."
            exit 1
        }
        # $DropScript = "DROP DATABASE `"$Database`";"
        # & $psqlPath --host=$Server -p 5434 --username=$Username -c "$DropScript"
        # if ($LASTEXITCODE -ne 0) {
        #     Write-Error "Failed to drop database '$Database' on PostgreSQL $NewVersion. Migration aborted."
        #     exit 1
        # }
        Write-Host "Database '$Database' dropped successfully on PostgreSQL $NewVersion."
        & $createdbPath -w  --host=$Server -p 5434 --username=$Username $Database
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to recreate database '$Database' on PostgreSQL $NewVersion. Migration aborted."
            exit 1
        }
        Write-Host "Database '$Database' recreated successfully on PostgreSQL $NewVersion."
    }

    Write-Host "Restoring database '$Database' to PostgreSQL $NewVersion..."
    & "C:\Program Files\PostgreSQL\$NewVersion\bin\pg_restore.exe" `
        --host=$Server `
        -p 5434 `
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
$psql12Path = "C:\Program Files\PostgreSQL\12\bin\psql.exe"
$server = "localhost"
$username = "postgres"
$databases = & $psql12Path -w --host=$server -p 5432 --username=$username -tAc "SELECT datname FROM pg_database WHERE datistemplate = false; "

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to retrieve databases from PostgreSQL 12."
    exit 1
}

$databases = $databases -split "`n" | Where-Object { $_.Trim() -ne "" }

foreach ($db in $databases) {
    if ($db -eq "postgres" -or $db -eq "template0" -or $db -eq "template1") {
        continue
    }
    Write-Host "Migrating database: $db"
    Migrate-PostgresDatabase -Database $db 
}


# param(
#     [string]$OldVersion = "12",
#     [string]$NewVersion = "16",
#     [string]$Database = "quickweb-development",
#     [string]$Username = "postgres",
#     [string]$Server = "localhost",
#     [string]$BackupFile = $Database + "_backup.sql"
# )

# # Step 1: Dump the database from PostgreSQL 12
# Write-Host "Dumping database '$Database' from PostgreSQL $OldVersion..."
# & "C:\Program Files\PostgreSQL\$OldVersion\bin\pg_dump.exe" `
#     --host=$Server `
#     -p 5432 `
#     --username=$Username `
#     --clean `
#     --format=tar `
#     --file=$BackupFile `
#     $Database

# if ($LASTEXITCODE -ne 0) {
#     Write-Error "pg_dump failed. Migration aborted."
#     exit 1
# }

# # Step 1.5: Create the database on the new server if it does not exist
# Write-Host "Checking if database '$Database' exists on PostgreSQL $NewVersion..."
# $psqlPath = "C:\Program Files\PostgreSQL\$NewVersion\bin\psql.exe"
# $createdbPath = "C:\Program Files\PostgreSQL\$NewVersion\bin\createdb.exe"
# $dbExists = & $psqlPath --host=$Server -p 5434 --username=$Username -tAc "SELECT 1 FROM pg_database WHERE datname='$Database'; "

# if (-not $dbExists) {
#     Write-Host "Database '$Database' does not exist on PostgreSQL $NewVersion. Creating..."
#     & $createdbPath --host=$Server -p 5434 --username=$Username $Database
#     if ($LASTEXITCODE -ne 0) {
#         Write-Error "Failed to create database '$Database' on PostgreSQL $NewVersion. Migration aborted."
#         exit 1
#     }
#     Write-Host "Database '$Database' created successfully on PostgreSQL $NewVersion."
# } 
# else {
#     Write-Host "Database '$Database' already exists on PostgreSQL $NewVersion."
# }

# # Step 2: Restore the database to PostgreSQL 16
# Write-Host "Restoring database '$Database' to PostgreSQL $NewVersion..."
# & "C:\Program Files\PostgreSQL\$NewVersion\bin\pg_restore.exe" `
#     --host=$Server `
#     -p 5434 `
#     --username=$Username `
#     --dbname=$Database `
#     --verbose `
#     $BackupFile

# if ($LASTEXITCODE -ne 0) {
#     Write-Error "pg_restore failed. Migration aborted."
#     exit 1
# }

# Write-Host "Migration completed successfully."