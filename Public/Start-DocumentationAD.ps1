function Start-DocumentationAD {
    [CmdletBinding()]
    param(
        $Document
    )
    $TypesRequired = Get-TypesRequired -Sections $Document.DocumentAD.Sections.SectionForest, $Document.DocumentAD.Sections.SectionDomain
    $ADSectionsForest = Get-ObjectKeys -Object $Document.DocumentAD.Sections.SectionForest
    $ADSectionsDomain = Get-ObjectKeys -Object $Document.DocumentAD.Sections.SectionDomain

    $TimeDataOnly = [System.Diagnostics.Stopwatch]::StartNew() # Timer Start
    $CheckAvailabilityCommandsAD = Test-AvailabilityCommands -Commands 'Get-ADForest', 'Get-ADDomain', 'Get-ADRootDSE', 'Get-ADGroup', 'Get-ADUser', 'Get-ADComputer'
    if ($CheckAvailabilityCommandsAD -notcontains $false) {
        Test-ForestConnectivity
        $DataInformationAD = Get-WinADForestInformation -TypesRequired $TypesRequired

    }

    $TimeDataOnly.Stop()
    $TimeDocuments = [System.Diagnostics.Stopwatch]::StartNew() # Timer Start
    ### Starting WORD
    if ($Document.DocumentAD.ExportWord) {
        $WordDocument = Get-DocumentPath -Document $Document -FinalDocumentLocation $Document.DocumentAD.FilePathWord
    }
    if ($Document.DocumentAD.ExportExcel) {
        $ExcelDocument = New-ExcelDocument
    }
    ### Start Sections
    foreach ($DataInformation in $DataInformationAD) {
        foreach ($Section in $ADSectionsForest) {
            $WordDocument = New-DataBlock `
                -WordDocument $WordDocument `
                -Section $Document.DocumentAD.Sections.SectionForest.$Section `
                -Object $DataInformationAD `
                -Excel $ExcelDocument `
                -SectionName $Section `
                -Sql $Document.DocumentAD.ExportSQL
        }
        foreach ($Domain in $DataInformationAD.Domains) {
            foreach ($Section in $ADSectionsDomain) {
                $WordDocument = New-DataBlock `
                    -WordDocument $WordDocument `
                    -Section $Document.DocumentAD.Sections.SectionDomain.$Section `
                    -Object $DataInformationAD `
                    -Domain $Domain `
                    -Excel $ExcelDocument `
                    -SectionName $Section `
                    -Sql $Document.DocumentAD.ExportSQL
            }
        }
    }
    ### End Sections

    ### Ending WORD
    if ($Document.DocumentAD.ExportWord) {
        $FilePath = Save-WordDocument -WordDocument $WordDocument `
            -Language $Document.Configuration.Prettify.Language `
            -FilePath $Document.DocumentAD.FilePathWord `
            -Supress $True `
            -OpenDocument:$Document.Configuration.Options.OpenDocument
    }
    ### Ending EXCEL
    if ($Document.DocumentAD.ExportExcel) {
        $ExcelData = Save-ExcelDocument -ExcelDocument $ExcelDocument -FilePath $Document.DocumentAD.FilePathExcel -OpenWorkBook:$Document.Configuration.Options.OpenExcel
    }
    $TimeDocuments.Stop()
    $TimeTotal.Stop()
    Write-Verbose "Time to gather data: $($TimeDataOnly.Elapsed)"
    Write-Verbose "Time to create documents: $($TimeDocuments.Elapsed)"
    Write-Verbose "Time total: $($TimeTotal.Elapsed)"
}