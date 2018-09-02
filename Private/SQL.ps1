function Send-SqlInsert {
    [CmdletBinding()]
    param(
        [PSCustomObject] $Object,
        [hashtable] $SqlSettings
    )
    $ReturnData = @()
    $Queries = New-SqlQuery -Object $Object -SqlSettings $SqlSettings
    foreach ($Query in $Queries) {
        $ReturnData += $Query
        try {
            $Data = Invoke-Sqlcmd2 -SqlInstance $SqlSettings.SqlServer -Database $SqlSettings.SqlDatabase -Query $Query -ErrorAction Stop
        } catch {
            $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
            #Write-Color @script:WriteParameters -Text '[e] ', 'SQL Error: ', $ErrorMessage -Color White, White, Yellow
            $ReturnData += "Error occured: $ErrorMessage"
        }
    }
    return $ReturnData
}

function New-SqlQuery {
    [CmdletBinding()]
    param (
        [hashtable ]$SqlSettings,
        [PSCustomObject] $Object
    )
    $TableMapping = $SqlSettings.SqlTableMapping
    $SQLTable = $SqlSettings.SqlTable

    $ArraySQLQueries = New-ArrayList
    ## Added fields to know when event was added to SQL and by WHO (in this case TaskS Scheduler User)
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "AddedWhen" -Value (Get-Date)
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "AddedWho" -Value ($Env:USERNAME)

    $CreateTableSQL = New-SqlQueryCreateTable -SqlSettings $SqlSettings -Object $Object
    Add-ToArray -List $ArraySQLQueries -Element $CreateTableSQL

    foreach ($O in $Object) {
        $ArrayMain = New-ArrayList
        $ArrayKeys = New-ArrayList
        $ArrayValues = New-ArrayList

        #Write-Verbose "Test: $($($O.PSObject.Properties.Name) -join ',')"
        foreach ($E in $O.PSObject.Properties) {
            $FieldName = $E.Name
            $FieldValue = $E.Value

            foreach ($MapKey in $TableMapping.Keys) {
                if ($FieldName -eq $MapKey) {
                    $MapValue = $TableMapping.$MapKey
                    if ($FieldValue -is [DateTime]) { $FieldValue = Get-Date $FieldValue -Format "yyyy-MM-dd HH:mm:ss" }
                    if ($FieldValue -contains "'") { $FieldValue = $FieldValue -Replace "'", "''" }
                    #if ($FieldValue -eq '') { $FieldValue = 'NULL' }
                    Add-ToArray -List $ArrayKeys -Element "[$MapValue]"
                    Add-ToArray -List $ArrayValues -Element "'$FieldValue'"
                }
            }
        }
        Add-ToArray -List $ArrayMain -Element "INSERT INTO $SQLTable ("
        Add-ToArray -List $ArrayMain -Element ($ArrayKeys -join ',')
        Add-ToArray -List $ArrayMain -Element ') VALUES ('
        Add-ToArray -List $ArrayMain -Element ($ArrayValues -join ',')
        Add-ToArray -List $ArrayMain -Element ')'

        Add-ToArray -List $ArraySQLQueries -Element ([string] ($ArrayMain) -replace "`n", "" -replace "`r", "")
    }

    # Write-Verbose "SQLQuery: $SqlQuery"
    return $ArraySQLQueries
}

function New-SqlQueryCreateTable {
    [CmdletBinding()]
    param (
        [hashtable ]$SqlSettings,
        [PSCustomObject] $Object
    )
    $TableMapping = $SqlSettings.SqlTableMapping
    $SQLTable = $SqlSettings.SqlTable

    $ArraySQLQueries = New-ArrayList

    foreach ($O in $Object) {
        $ArrayMain = New-ArrayList
        $ArrayKeys = New-ArrayList
        $ArrayValues = New-ArrayList

        foreach ($E in $O.PSObject.Properties) {
            $FieldName = $E.Name
            $FieldValue = $E.Value

            foreach ($MapKey in $TableMapping.Keys) {
                if ($FieldName -eq $MapKey) {
                    $MapValue = $TableMapping.$MapKey

                    if ($FieldValue -is [DateTime]) {
                        Add-ToArray -List $ArrayKeys -Element "[$MapValue] [DateTime] NULL"
                    } elseif ($FieldValue -is [int] -or $FieldValue -is [Int64]) {
                        Add-ToArray -List $ArrayKeys -Element "[$MapValue] [int] NULL"
                    } elseif ($FieldValue -is [bool]) {
                        Add-ToArray -List $ArrayKeys -Element "[$MapValue] [bit] NULL"
                    } else {
                        Add-ToArray -List $ArrayKeys -Element "[$MapValue] [nvarchar](max) NULL"
                    }
                }
            }
        }
        Add-ToArray -List $ArrayMain -Element "CREATE TABLE $SQLTable ("
        Add-ToArray -List $ArrayMain -Element ($ArrayKeys -join ',')
        Add-ToArray -List $ArrayMain -Element ')'


        Add-ToArray -List $ArraySQLQueries -Element ([string] ($ArrayMain) -replace "`n", "" -replace "`r", "")
        break
    }
    return $ArraySQLQueries
}