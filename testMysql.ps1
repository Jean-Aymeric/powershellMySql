try {
    . ("JADMySql.ps1")
}
catch {
    Write-Output "Error while loading JADMySql.ps1 script"
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