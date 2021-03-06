#import module from repo
Import-Module (Join-Path $PSScriptRoot "..\PoshSSDTBuildDeploy") -Force

Describe "Publish-DatabaseDeployment" {    
    
    function Get-DbId ($databaseName, $serverInstanceName) {
        @(Invoke-Sqlcmd -Query "select db_id('$databaseName') as DbId" -ServerInstance $serverInstanceName) | Select-Object -First 1 -ExpandProperty DbId
    }

    function Get-DbCreationDate ($databaseName, $serverInstanceName) {
        @(Invoke-Sqlcmd -Query "select create_date as createdate from sys.databases where name = '$databaseName' " -ServerInstance $serverInstanceName) | Select-Object -First 1 -ExpandProperty createdate
    }

    BeforeAll {
        $instanceName = "poshssdtbuilddeploy"
        SqlLocalDB.exe create $instanceName 13.0 -s
        SqlLocalDB.exe info $instanceName
    
        $serverInstance = "(localdb)\$instanceName"
        $svrConnstring = "SERVER=$serverInstance;Integrated Security=True;Database=master"
        $WWI_NAME = "WideWorldImporters"
        $WWI = Join-Path $PSScriptRoot "wwi-dw-ssdt"
        $WWI_SLN = Join-Path $WWI "\WideWorldImportersDW.sqlproj"
        $WWI_DAC = Join-Path $WWI "\Microsoft.Data.Tools.Msbuild\lib\net46"
        $WWI_DACFX = Join-Path $WWI_DAC "\Microsoft.SqlServer.Dac.dll"
        $WWI_DACPAC = Join-Path $WWI "\bin\Debug\WideWorldImportersDW.dacpac"
        $WWI_PUB = Join-Path $WWI "\bin\Debug\WideWorldImportersDW.publish.xml"
        $DeploymentReportPathPattern = Join-Path $WWI "*DeploymentReport_*.xml"
        $DeploymentScriptPathPattern = Join-Path $WWI "*DeployScript_*.sql"
        $DeploymentSummaryPathPattern = Join-Path $WWI "*DeploymentSummary_*.txt"
    
        #Remove-Item $WWI_DACPAC -Force -ErrorAction SilentlyContinue
        #Invoke-MsBuildSSDT -DatabaseSolutionFilePath $WWI_SLN -DataToolsFilePath $WWI_DAC
    }

    BeforeEach {
        Remove-Item $DeploymentReportPathPattern -ErrorAction SilentlyContinue
        Remove-Item $DeploymentScriptPathPattern -ErrorAction SilentlyContinue  
        Remove-Item $DeploymentSummaryPathPattern -ErrorAction SilentlyContinue  
        Invoke-Sqlcmd -Query "drop database if exists $WWI_NAME" -ServerInstance $serverInstance  
    }

    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is not generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Not -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }
    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is not generated and Missing Variable is written to Host" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI -getSqlCmdVars } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Not -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }

    it "Deploy the database and DeploymentScript is generated and DeploymentReport is not generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Exist
        $DeploymentReportPathPattern | Should -Not -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }
    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is generated and DeploymentSummary is not generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $true -GenerateDeploymentSummary $false -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }

    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is generated and DeploymentSummary is generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Exist
    }

    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is generated and DeploymentSummary default is used" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $true -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }


    it "Deploy the database and DeploymentScript is generated and DeploymentReport is generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Exist
    }
    it "Database is not deployed and DeploymentScript is generated and DeploymentReport is not generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI -ScriptOnly } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Exist
        $DeploymentReportPathPattern | Should -Not -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }
    it "Database is not deployed and DeploymentScript is not generated and DeploymentReport is generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $true -ScriptPath $WWI -ScriptOnly } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }
    it "Database is not deployed and DeploymentScript is generated and DeploymentReport is generated" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -ScriptPath $WWI -ScriptOnly } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }  
    it "throws exception if not at least one of GenerateDeploymentScript or GenerateDeploymentReport is true when using ScriptOnly" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeployMentReport $false -ScriptPath $WWI -ScriptOnly} |
            Should -Throw "Specify at least one of GenerateDeploymentScript or GenerateDeploymentReport to be true when using ScriptOnly!"
    }
    it "throws exception if Script Path is Invalid" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeployMentReport $false -ScriptPath "X:\bob" } |
            Should -Throw "Script Path Invalid"
    }
    it "Throws exception that variable is not included in session" {
        Remove-Variable DeployTag -Scope "Global" -Force
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -ScriptPath $WWI -getSqlCmdVars -FailOnMissingVars } | 
            Should -Throw
    }
    it "Variable is included in the session" {
        $global:DeployTag = "PesterTest"
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -ScriptPath $WWI -getSqlCmdVars -FailOnMissingVars -Verbose } | Should -Not -Throw
        $DeploymentScriptPathPattern | Should -Exist
        $DeploymentReportPathPattern | Should -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }  
    it "Deploy the database and DeploymentScript is not generated and DeploymentReport is not generated and DeployTag is updated to PesterTest" {
        {$DeployTag = "PesterTest"
            Write-Host $DeployTag
            Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -ScriptPath $WWI -getSqlCmdVars -Verbose} | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
        $DeploymentScriptPathPattern | Should -Not -Exist
        $DeploymentReportPathPattern | Should -Not -Exist
        $DeploymentSummaryPathPattern | Should -Not -Exist
    }

    it "Connection String from publish.xml is used for publishing database." {
        {
            $WWI_PUB = Join-Path $WWI "\bin\Debug\WideWorldImportersDW_PesterTestLocalConnString.publish.xml"
            $instanceName = "poshssdtbuilddeploy2"
            sqllocaldb.exe create $instanceName 13.0 -s
            sqllocaldb.exe info $instanceName
            $serverInstance = "(localdb)\$instanceName"
            Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetDatabaseName $WWI_NAME -ScriptPath $WWI -GenerateDeploymentScript $true -getSqlCmdVars -Verbose} | Should -Not -Throw
            Get-DbId -databaseName $WWI_NAME -serverInstanceName "(localdb)\poshssdtbuilddeploy2" | Should -Not -BeNullOrEmpty
    }

    It "Pass DacDeploy Options" {
        Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI
        $expected = Get-DbCreationDate -databaseName $WWI_NAME -serverInstanceName $serverInstance
        { $deployOptions = @{'commandTimeout' = 180; 'CreateNewDatabase' = $false } 
            Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI -dacDeployOptions $deployOptions } | Should -Not -Throw
        $actual = Get-DbCreationDate -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Be $expected
    }
    it "Pass Invalid DacDeploy Options" {
        { $deployOptions = @{'commandTimeout' = 30; 'bob' = 'false'} 
        Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI -dacDeployOptions $deployOptions } | Should -Throw
    }
    
    It "Pass DacDeploy Options" {
        Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI
        $expected = Get-DbCreationDate -databaseName $WWI_NAME -serverInstanceName $serverInstance
        { $deployOptions = @{'commandTimeout' = "180"; 'CreateNewDatabase' = $false } 
            Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $true -GenerateDeploymentSummary $true -ScriptPath $WWI -dacDeployOptions $deployOptions } | Should -Throw
    }


    it "Storage Type is set to Memory" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI  -StorageType "Memory" } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
    }
    
    
    it "Storage Type is set to File" {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $false -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -ScriptPath $WWI  -StorageType "File" } | Should -Not -Throw
        Get-DbId -databaseName $WWI_NAME -serverInstanceName $serverInstance | Should -Not -BeNullOrEmpty
    }
    
    
    it "Storage Type is set to something invalid, throws." {
        {Publish-DatabaseDeployment -dacfxPath $WWI_DACFX -dacpac $WWI_DACPAC -publishXml $WWI_PUB -targetConnectionString $svrConnstring -targetDatabaseName $WWI_NAME -GenerateDeploymentScript $true -GenerateDeploymentReport $false -GenerateDeploymentSummary $false -StorageType "something invalid" } | Should -Throw
    }
    
}
