function connectToMySql {
    try {
        $mysqlConnection = New-Object MySql.Data.MySqlClient.MySqlConnection
        $mysqlConnection.ConnectionString = "Host=localhost;
                                             Port=3306;
                                             Username=root;
                                             Password=root;
                                             Database=jadsiege"
        $mysqlConnection.Open()
        return [MySql.Data.MySqlClient.MySqlConnection]$mysqlConnection
    } catch {
        Write-Error Exception.Message
        Exit
    }
}

function disconnectFromMySql {
    param (
        [MySql.Data.MySqlClient.MySqlConnection]$mysqlConnection
    )
    try {
        $mysqlConnection.Close()
    } catch {
        Write-Error Exception.Message
        Exit
    }
}

function getDataSetFromQuery {
    param(
        [MySql.Data.MySqlClient.MySqlConnection]$mysqlConnection,
        [string]$querySelect
    )
    try {
        $mysqlCommand = New-Object MySql.Data.MySqlClient.MySqlCommand($querySelect, $mysqlConnection)
        $mysqlDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($mysqlCommand)
        $dataSet = New-Object System.Data.DataSet
        $mysqlDataAdapter.Fill($dataSet)
        $mysqlDataAdapter.Dispose()
        $mysqlCommand.Dispose()
        return $dataSet
    } catch {
        Write-Error Exception.Message
        Exit
    }
}

function getDataSetFromProcedure {
    param(
        [MySql.Data.MySqlClient.MySqlConnection]$mysqlConnection,
        [string]$procedure,
        $parameters=@{}
    )
    try {
        $mysqlCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
        $mysqlCommand.Connection = $mysqlConnection
        $mysqlCommand.CommandText = $procedure
        $mysqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure
        foreach ($parameter in $parameters.Keys) {
            $mysqlCommand.Parameters.AddWithValue("@$parameter", $parameters[$parameter]) | Out-Null
        }
        $mysqlDataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($mysqlCommand)
        $dataSet = New-Object System.Data.DataSet
        $mysqlDataAdapter.Fill($dataSet)
        $mysqlDataAdapter.Dispose()
        $mysqlCommand.Dispose()
        return $dataSet
#        $mysqlCommand.ExecuteNonQuery() | Out-Null
#        $mysqlCommand.Dispose()
   } catch {
        Write-Error Exception.Message
        Exit
    }
}

function callProcedure {
   param(
        [MySql.Data.MySqlClient.MySqlConnection]$mysqlConnection,
        [string]$procedure,
        $parameters=@{}
    )
    try {
        $mysqlCommand = New-Object MySql.Data.MySqlClient.MySqlCommand
        $mysqlCommand.Connection = $mysqlConnection
        $mysqlCommand.CommandText = $procedure
        $mysqlCommand.CommandType = [System.Data.CommandType]::StoredProcedure
        foreach ($parameter in $parameters.Keys) {
            $mysqlCommand.Parameters.AddWithValue("@$parameter", $parameters[$parameter]) | Out-Null
        }
        $mysqlCommand.ExecuteNonQuery() | Out-Null
        $mysqlCommand.Dispose()
   } catch {
        Write-Error Exception.Message
        Exit
    }
}

function writeOutputDataSet {
    param (
        $dataSet
    )
    $columnsSize = @{}
    foreach ($column in $dataSet.Tables.Columns) {
        $columnsSize.add($column.ColumnName, $column.ColumnName.length +1)
    }
    foreach ($row in $dataSet.Tables) {
        foreach ($column in $dataSet.Tables.Columns) {
            if ($columnsSize[$column.ColumnName] -le "$($row[$column])".length) {
                $columnsSize[$column.ColumnName] = "$($row[$column])".length +1
            }
        }
    }
    [int]$tableSize = 1
    foreach ($column in $dataSet.Tables.Columns) {
        $tableSize += $columnsSize[$column.ColumnName] + 3
    }
    Write-Output "".PadRight($tableSize, "-")
    [string]$titleString = "|"
    foreach ($column in $dataSet.Tables.Columns) {
        $titleString += " " + ($column.ColumnName).PadRight($columnsSize[$column.ColumnName], " ") + " |"
    }
    Write-Output $titleString
    Write-Output "".PadRight($tableSize, "-")
    foreach ($row in $dataSet.Tables) {
        [string]$rowString = "|"
        foreach ($column in $dataSet.Tables.Columns) {
            $rowString += " " + "$($row[$column])".PadRight($columnsSize[$column.ColumnName], " ") + " |"
        }
        Write-Output $rowString
    }
    Write-Output "".PadRight($tableSize, "-")
}

$mysqlnet=[Reflection.Assembly]::LoadWithPartialName("MySql.Data")
if (-not $mysqlnet) {
    Write-Error "Erreur de chargement du module MySql.Data"
    Exit
}
$mysqlConnection = connectToMySql;

callProcedure -mysqlConnection $mysqlConnection -procedure "setLog" -parameters @{_message="Test via Powershell avec callProcedure()"};

$dataSet3 = getDataSetFromQuery -mysqlConnection $mysqlConnection -querySelect "SELECT * FROM jadsiege.article;"
writeOutputDataSet -dataSet $dataSet3
Write-Output "`n"
$dataSet1 = getDataSetFromProcedure -mysqlConnection $mysqlConnection -procedure "getLog" -parameters @{_team="remote_root"};
writeOutputDataSet -dataSet $dataSet1
Write-Output "`n"


disconnectFromMySql ($mysqlConnection)
