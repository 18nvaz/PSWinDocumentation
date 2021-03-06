function Get-WinGroups {
    param (
        [System.Object[]] $Groups,
        [System.Object[]] $Users,
        [string] $Domain
    )
    $ReturnGroups = @()
    foreach ($Group in $Groups) {
        $User = $Users | Where { $_.DistinguishedName -eq $Group.ManagedBy }
        $ReturnGroups += [ordered] @{
            'Group Name'            = $Group.Name
            #'Group Display Name' = $Group.DisplayName
            'Group Category'        = $Group.GroupCategory
            'Group Scope'           = $Group.GroupScope
            'Group SID'             = $Group.SID.Value
            'High Privileged Group' = if ($Group.adminCount -eq 1) { $True } else { $False }
            'Member Count'          = $Group.Members.Count
            'MemberOf Count'        = $Group.MemberOf.Count
            'Manager'               = $User.Name
            'Manager Email'         = $User.EmailAddress
            'Group Members'         = (Get-ADObjectFromDistingusishedName -ADCatalog $Data.DomainUsersFullList, $Data.DomainComputersFullList, $Data.DomainGroupsFullList -DistinguishedName $Group.Members -Type 'SamAccountName')
            'Group Members DN'      = $Group.Members
            "Domain"                = $Domain
        }
    }
    return Format-TransposeTable -Object $ReturnGroups
}