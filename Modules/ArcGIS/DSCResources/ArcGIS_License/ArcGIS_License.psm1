﻿$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ArcGIS Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ArcGIS.Common' `
            -ChildPath 'ArcGIS.Common.psm1'))

<#
    .SYNOPSIS
        Licenses the product (Server or Portal) depending on the params specified.
    .PARAMETER Ensure
        Take the values Present or Absent. 
        - "Present" ensures that Component in Licensed, if not.
        - "Absent" ensures that Component in Unlicensed (Not Implemented).
    .PARAMETER LicenseFilePath
        Path to License File 
    .PARAMETER LicensePassword
        Optional Password for the corresponding License File 
    .PARAMETER Version
        Optional Version for the corresponding License File 
    .PARAMETER Component
        Product being Licensed (Server or Portal)
    .PARAMETER ServerRole
        (Optional - Required only for Server) Server Role for which the product is being Licensed
    .PARAMETER AdditionalServerRole
        (Optional - Only valid for General Purpose Server) Additional Server Role for which the product is being Licensed
    .PARAMETER IsSingleUse
        Boolean to tell if Pro or Desktop is using Single Use License.
    .PARAMETER Force
        Boolean to Force the product to be licensed again, even if already done.

#>

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$LicenseFilePath
	)

	$null 
}
function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        $LicenseFilePath,
        
        [parameter(Mandatory = $false)]
		[System.Management.Automation.PSCredential]
        $LicensePassword,

        [parameter(Mandatory = $false)]
		[System.String]
		$Version,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

        [ValidateSet("Server","Portal","Desktop","Pro","Drone2Map","LicenseManager","Monitor")]
		[System.String]
		$Component,

		[ValidateSet("ImageServer","GeoEvent","GeoAnalytics","GeneralPurposeServer","HostingServer","NotebookServer","MissionServer","WorkflowManagerServer","KnowledgeServer","VideoServer")]
		[System.String]
        $ServerRole = 'GeneralPurposeServer',

        [parameter(Mandatory = $False)]    
        [System.Array]
        $AdditionalServerRoles,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsSingleUse,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
		$Force= $False
	)

	if(-not(Test-Path $LicenseFilePath)){
        throw "License file not found at $LicenseFilePath"
    }

    if($Ensure -ieq 'Present') {
        [string]$RealVersion = @()
        if(-not($Version)){
            try{
                $ErrorActionPreference = "Stop"; #Make all errors terminating
                $ComponentName = if($Component -ieq "LicenseManager"){ "License Manager" }elseif($Component -ieq "Server"){ if($ServerRole -ieq 'NotebookServer'){ "ArcGIS Notebook Server" }elseif($ServerRole -ieq 'MissionServer'){ "ArcGIS Mission Server" }elseif($ServerRole -ieq 'VideoServer'){ "ArcGIS Video Server" }else{ "ArcGIS Server" } } else{ $Component }
                $RealVersion = (Get-ArcGISProductDetails -ProductName $ComponentName).Version
            }catch{
                throw "Couldn't Find The Product - $Component"            
            }finally{
                $ErrorActionPreference = "Continue"; #Reset the error action pref to default
            }
        }else{
            $RealVersion = $Version
        }
        Write-Verbose "RealVersion of ArcGIS Software:- $RealVersion" 
        $RealVersion = $RealVersion.Split('.')[0] + '.' + $RealVersion.Split('.')[1] 
        $LicenseVersion = if($Component -ieq 'Pro' -or $Component -ieq 'Drone2Map' -or $Component -ieq 'LicenseManager'){ '10.6' }else{ $RealVersion }
        Write-Verbose "Licensing from $LicenseFilePath" 
        if(@('Desktop', 'Pro', 'Drone2Map', 'LicenseManager') -icontains $Component) {
            Write-Verbose "Version $LicenseVersion Component $Component" 
            Invoke-LicenseSoftware -Product $Component -LicenseFilePath $LicenseFilePath `
                        -Version $LicenseVersion -LicensePassword $LicensePassword -IsSingleUse $IsSingleUse -Verbose
        } else {
            Write-Verbose "Version $LicenseVersion Component $Component Role $ServerRole" 
            Invoke-LicenseSoftware -Product $Component -ServerRole $ServerRole -LicenseFilePath $LicenseFilePath `
                        -Version $LicenseVersion -LicensePassword $LicensePassword -IsSingleUse $IsSingleUse -Verbose
        }
    }else {
        throw "Ensure = 'Absent' not implemented"
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
        $LicenseFilePath,
        
        [parameter(Mandatory = $false)]
		[System.Management.Automation.PSCredential]
		$LicensePassword,

        [parameter(Mandatory = $false)]
		[System.String]
		$Version,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[ValidateSet("Server","Portal","Desktop","Pro","Drone2Map","LicenseManager","Monitor")]
		[System.String]
		$Component,

		[ValidateSet("ImageServer","GeoEvent","GeoAnalytics","GeneralPurposeServer","HostingServer","NotebookServer","MissionServer","WorkflowManagerServer","KnowledgeServer","VideoServer")]
		[System.String]
        $ServerRole = 'GeneralPurposeServer',

        [parameter(Mandatory = $False)]    
        [System.Array]
        $AdditionalServerRoles,

        [parameter(Mandatory = $false)]
        [System.Boolean]
        $IsSingleUse,
        
        [parameter(Mandatory = $false)]
        [System.Boolean]
		$Force = $False
	)

    [string]$RealVersion = @()
    $result = $false
    if(-not($Version)){
        try{
            $ErrorActionPreference = "Stop"; #Make all errors terminating
            $ComponentName = if($Component -ieq "LicenseManager"){ "License Manager" }elseif($Component -ieq "Server"){ if($ServerRole -ieq 'NotebookServer'){ "ArcGIS Notebook Server" }elseif($ServerRole -ieq 'MissionServer'){ "ArcGIS Mission Server" }elseif($ServerRole -ieq 'VideoServer'){ "ArcGIS Video Server" }else{ "ArcGIS Server" } } else{ $Component }
            $RealVersion = (Get-ArcGISProductDetails -ProductName $ComponentName).Version
        }catch{
            throw "Couldn't Find The Product - $Component"        
        }finally{
            $ErrorActionPreference = "Continue"; #Reset the error action pref to default
        }
    }else{
        $RealVersion = $Version
    }

    Write-Verbose "RealVersion of ArcGIS Software to be Licensed:- $RealVersion" 
    $RealVersion = $RealVersion.Split('.')[0] + '.' + $RealVersion.Split('.')[1] 
    $LicenseVersion = if($Component -ieq 'Pro' -or $Component -ieq 'LicenseManager'){ '10.6' }else{ $RealVersion }
    Write-Verbose "Version $LicenseVersion" 
    if($Component -ieq 'Desktop') {
        Write-Verbose "TODO:- Check for Desktop license. For now forcing Software Authorization Tool to License Pro."
    }
    elseif($Component -ieq 'Pro') {
        Write-Verbose "TODO:- Check for Pro license. For now forcing Software Authorization Tool to License Pro."
    }
    elseif($Component -ieq 'Drone2Map') {
        Write-Verbose "TODO:- Check for Drone2Map license. For now forcing Software Authorization Tool to License Pro."
    }
    elseif($Component -ieq 'LicenseManager') {
        Write-Verbose "TODO:- Check for License Manger license. For now forcing Software Authorization Tool to License."
    }
    else {
        if(-not($Force)){
            Write-Verbose "License Check Component:- $Component"
            $result = Test-LicenseForRole -LicenseVersion $LicenseVersion -Component $Component -ServerRole $ServerRole
            if($result){
                if($Component -ieq "Server"){
                    Write-Verbose "$Component is licensed correctly for $ServerRole"
                    foreach($AdditionalRole in $AdditionalServerRoles){
                        $result = Test-LicenseForRole -LicenseVersion $LicenseVersion -Component $Component -ServerRole $AdditionalRole
                        if($result -eq $False){
                            Write-Verbose "$Component is not licensed correctly for server role $AdditionalRole"
                            break
                        }
                    }
                }else{
                    Write-Verbose "$Component is licensed correctly"
                }
            }else{
                Write-Verbose "$Component is not licensed correctly"
            }
        }
    }
    
    if($Ensure -ieq 'Present') {
	    $result   
    }
    elseif($Ensure -ieq 'Absent') {        
        (-not($result))
    }
}

function Invoke-LicenseSoftware
{
    [CmdletBinding()]
    param
    (
		[System.String]
        $Product, 

        [System.String]
        $ServerRole,
        
        [System.String]
		$LicenseFilePath, 
        
        [System.Management.Automation.PSCredential]
        $LicensePassword, 
        
		[System.String]
		$Version,
        
        [System.Boolean]
        $IsSingleUse
    )

    $SoftwareAuthExePath = "$env:SystemDrive\Program Files\Common Files\ArcGIS\bin\SoftwareAuthorization.exe"
    $LMReloadUtilityPath = ""
    if(@('Desktop','Pro','Drone2Map','LicenseManager') -icontains $Product) {
        $SoftwareAuthExePath = "$env:SystemDrive\Program Files (x86)\Common Files\ArcGIS\bin\SoftwareAuthorization.exe"
        if($IsSingleUse -or ($Product -ne 'LicenseManager')){
            if($Product -ieq 'Desktop'){
                $SoftwareAuthExePath = "$env:SystemDrive\Program Files (x86)\Common Files\ArcGIS\bin\softwareauthorization.exe"
            }elseif($Product -ieq 'Pro'){
                $InstallLocation = (Get-ArcGISProductDetails -ProductName "ArcGIS Pro" | Where-Object {$_.Name -ieq "ArcGIS Pro"}).InstallLocation
                $SoftwareAuthExePath = "$($InstallLocation)bin\SoftwareAuthorizationPro.exe"
            }
            elseif($Product -ieq 'Drone2Map'){
                $InstallLocation = (Get-ArcGISProductDetails -ProductName "ArcGIS Drone2Map" | Where-Object {$_.Name -ieq "ArcGIS Drone2Map"}).InstallLocation
                $SoftwareAuthExePath = "$($InstallLocation)bin\SoftwareAuthorizationPro.exe"
            }
        }else{
            $LMInstallLocation = (Get-ArcGISProductDetails -ProductName "License Manager").InstallLocation
            if($LMInstallLocation){
                $SoftwareAuthExePath = "$($LMInstallLocation)bin\SoftwareAuthorizationLS.exe"
                $LMReloadUtilityPath = "$($LMInstallLocation)bin\lmutil.exe"
            }
        }
    }else{
        $VersionArray = $Version.Split('.')
        if($Product -ieq "Server"){
            $ServerTypeName = "ArcGIS Server"
            if($ServerRole -ieq "NotebookServer"){ 
                $ServerTypeName = "ArcGIS Notebook Server" 
            }elseif($ServerRole -ieq "MissionServer"){ 
                $ServerTypeName = "ArcGIS Mission Server"
            }elseif($ServerRole -ieq "VideoServer"){ 
                $ServerTypeName = "ArcGIS Video Server"
            }
            $InstallLocation = (Get-ArcGISProductDetails -ProductName $ServerTypeName).InstallLocation
            if($VersionArray[0] -eq 11 -and $VersionArray[1] -ge 2){
                $SoftwareAuthExePath = "$($InstallLocation)tools\SoftwareAuthorization\SoftwareAuthorization.exe"
            }else{
                if(($ServerRole -ieq "NotebookServer" -or $ServerRole -ieq "MissionServer" -or $ServerRole -ieq "VideoServer") -and ($VersionArray[0] -eq 11 -or ($VersionArray[0] -eq 10 -and $VersionArray[1] -ge 8))){
                    if($ServerRole -ieq "MissionServer"){
                        $SoftwareAuthExePath = "$($InstallLocation)bin\SoftwareAuthorization.exe"
                    }else{
                        $SoftwareAuthExePath = "$($InstallLocation)framework\bin\SoftwareAuthorization.exe"
                    }
                }
            }
        }
    }
    Write-Verbose "Licensing Product [$Product] using Software Authorization Utility at $SoftwareAuthExePath" -Verbose
    
    $Params = '-s -ver {0} -lif "{1}"' -f $Version,$licenseFilePath
    if($null -ne $LicensePassword){
        $Params = '-s -ver {0} -lif "{1}" -password {2}' -f $Version,$licenseFilePath,$LicensePassword.GetNetworkCredential().Password
    }
    Write-Verbose "[Running Command] $SoftwareAuthExePath $Params" -Verbose
    
    [bool]$Done = $false
    [int]$AttemptNumber = 1
    $err = $null
    while(-not($Done) -and ($AttemptNumber -le 10)) {
        if(-not(Test-Path $SoftwareAuthExePath -PathType Leaf)){
            throw "$SoftwareAuthExePath not found"
        }
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $SoftwareAuthExePath
        $psi.Arguments = $Params
        $psi.UseShellExecute = $false #start the process from it's own executable file    
        $psi.RedirectStandardOutput = $true #enable the process to read from standard output
        $psi.RedirectStandardError = $true #enable the process to read from standard error
    
        $p = [System.Diagnostics.Process]::Start($psi)
        $p.WaitForExit()
        $op = $p.StandardOutput.ReadToEnd()
        if($p.ExitCode -eq 0) {
            if($op -and (($op.IndexOf('Error') -gt -1) -or ($op.IndexOf('(null)') -gt -1))) {
                $err = "[ERROR] - Attempt $AttemptNumber - Licensing for Product [$Product] failed. Software Authorization Utility returned $op"
                Write-Verbose $err
                Start-Sleep -Seconds (Get-Random -Maximum 61 -Minimum 30)
            }else{
                $Done = $True
                $err = $null
            }
        }else{
            $err = $p.StandardError.ReadToEnd()
            Write-Verbose $err
            if($err -and $err.Length -gt 0) {
                throw  "[ERROR] - Attempt $AttemptNumber - Licensing for Product [$Product] failed. Software Authorization Utility returned Output - $op. Error - $err"
            }
        }
        $AttemptNumber += 1
    }
    if($null -ne $err){
        throw $err
    }
    if($Product -ieq 'Desktop' -or $Product -ieq 'Pro' -or $Product -ieq 'Drone2Map') {
        Write-Verbose "Sleeping for 2 Minutes to finish Licensing"
        Start-Sleep -Seconds 120
    }
    if($Product -ieq 'LicenseManager'){
		Write-Verbose "Re-readings Licenses"
        if(-not(Test-Path $LMReloadUtilityPath -PathType Leaf)){
            throw "$LMReloadUtilityPath not found"
        }
        $psilm = New-Object System.Diagnostics.ProcessStartInfo
        $psilm.FileName = $LMReloadUtilityPath
        $psilm.Arguments = 'lmreread -c @localhost'
        $psilm.UseShellExecute = $false #start the process from it's own executable file    
        $psilm.RedirectStandardOutput = $true #enable the process to read from standard output
        $psilm.RedirectStandardError = $true #enable the process to read from standard error
        
        $plm = [System.Diagnostics.Process]::Start($psilm)
        $plm.WaitForExit()
        $oplm = $p.StandardOutput.ReadToEnd()
        if($p.ExitCode -eq 0) {
            Write-Verbose "License Manager tool operation successful - $oplm"
        }else{
            $errlm = $plm.StandardError.ReadToEnd()
            Write-Verbose $errlm
            if($errlm -and $errlm.Length -gt 0) {
                throw "License Manager tool failed to re-read licenses. Output - $oplm. Error - $errlm"
            }
        }
	}
    Write-Verbose "Finished Licensing Product [$Product]" -Verbose
}

function Test-LicenseForRole{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [System.String]
        $LicenseVersion,

        [System.String]
        $Component,

        [System.String]
        $ServerRole
    )
    
    $file = "$env:SystemDrive\Program Files\ESRI\License$($LicenseVersion)\sysgen\keycodes"
    if(Test-Path $file){ 
        $result = $true
        $KeyCodesFileContents = Get-Content $file

        $searchtexts = @()
        if($Component -ieq 'Portal') {
            $searchtexts = @('portal_', 'portal1_', 'portal2_')
        }
        elseif($Component -ieq 'Monitor') {
            $searchtexts = @('arcsysmon')
        }
        elseif($Component -ieq 'Server'){
            Write-Verbose "ServerRole:- $ServerRole"
            $searchtexts = $searchtexts = @('svr')
            if($ServerRole -ieq 'ImageServer') {
                $searchtexts = @('imgsvr')
            }
            if($ServerRole -ieq 'GeoEvent') {
                $searchtexts = @('geoesvr')
            }
            if($ServerRole -ieq 'WorkflowManagerServer') {
                $searchtexts = @('workflowsvr','workflowsvradv')
            }
            if($ServerRole -ieq 'GeoAnalytics') {
                $searchtexts = @('geoesvr')
            }
            if($ServerRole -ieq 'KnowledgeServer'){ 
                $searchtexts = @('knwldgsvr')
            }
            if($ServerRole -ieq 'NotebookServer') {
                $searchtexts = @('notebooksstdsvr','notebooksadvsvr')
            }
            if($ServerRole -ieq 'MissionServer') {
                $searchtexts = @('missionsvr')
            }
            if($ServerRole -ieq 'VideoServer') {
                $searchtexts = @('videosvr')
            }
        }
        
        # All of the search texts should exist in the keygen
        $TextFound = $False
        foreach($KeyCodeLine in $KeyCodesFileContents){
            if($null -ne ($searchtexts | Where-Object { $KeyCodeLine -imatch $_ })){
                Write-Verbose "License search keywords found."
                $TextFound = $True
                break
            }
        }
        if($TextFound -ieq $False){
            Write-Verbose "License search keywords not found."
            $result = $False
        }
        $result
    }else{
        $False
    }
}

Export-ModuleMember -Function *-TargetResource
