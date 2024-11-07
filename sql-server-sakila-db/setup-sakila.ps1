# Define the URLs for the SQL schema and data insert files
$SchemaFileUrl = "https://raw.githubusercontent.com/Corndel/sakila/main/sql-server-sakila-db/sql-server-sakila-schema.sql"
$DataInsertFileUrl = "https://raw.githubusercontent.com/Corndel/sakila/main/sql-server-sakila-db/sql-server-sakila-insert-data.sql"

# Credentials
$username = "corndeladmin"
$password = "Password01"

function DoesTableExist {
    param (
        [string]$serverInstanceName,
        [string]$tableName
    )

    $query = "IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '$tableName') SELECT 1 ELSE SELECT 0"
    $result = Invoke-Sqlcmd -ServerInstance $serverInstanceName -Database "sakila" -Username $username -Password $password -Query $query
    return ($result -eq 1)
}

function IsTableEmpty {
    param (
        [string]$serverInstanceName,
        [string]$tableName
    )

    $query = "SELECT TOP 1 1 FROM dbo.$tableName"
    $result = Invoke-Sqlcmd -ServerInstance $serverInstanceName -Database "sakila" -Username $username -Password $password -Query $query
    return ($null -eq $result)
}

# Main script execution
Write-Output "Script started at $(Get-Date)"

# Get the only existing resource group
$resourceGroupName = (Get-AzResourceGroup).ResourceGroupName

# Get the SQL Server instance details
$serverInstanceName = (Get-AzSqlServer -ResourceGroupName $resourceGroupName).FullyQualifiedDomainName

$tableExists = DoesTableExist -serverInstanceName $serverInstanceName -tableName "actor"

if (-not $tableExists) {
    Write-Output "Table 'actor' does not exist. Running schema script."
    
    # Download and execute the SQL schema file
    $SchemaFileContent = Invoke-WebRequest -Uri $SchemaFileUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    Invoke-Sqlcmd -ServerInstance $serverInstanceName -Database "sakila" -Username $username -Password $password -Query $SchemaFileContent
}

$tableEmpty = IsTableEmpty -serverInstanceName $serverInstanceName -tableName "actor"

if ($tableEmpty) {
    Write-Output "Table 'actor' is empty. Running data insertion script."

    # Download and execute the SQL data insert file
    $DataInsertFileContent = Invoke-WebRequest -Uri $DataInsertFileUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    Invoke-Sqlcmd -ServerInstance $serverInstanceName -Database "sakila" -Username $username -Password $password -Query $DataInsertFileContent
} else {
    Write-Output "Data already exists in the 'actor' table. Skipping data insertion."
}

Write-Output "Script completed at $(Get-Date)"
