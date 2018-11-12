<#
    
    .SYNOPSIS
        Sends mail to someone when there are VMs with snapshots on a vCenter Server

    .DESCRIPTION
        Get list of Virtual Machines on a vCenter Server that have snapshots. If there are VMs with snapshots, send warning via e-mail.
    
    .NOTES
        Remember to configure the script by editing the $Config hashtable in the beginning of the script
    
#>

BEGIN {

    $Config = @{
        
        vcsaServer=""
        emailSender=""
        emailRepicent=""    
        smtpServer=""
        headerFile="headerTemplate.html"

    }

}


PROCESS {

    try {
        Import-Module Torbjorn.VMWare

        $vms = Get-VMsWithSnapshots -Server $Config.vcsaServer | Where-Object Count -gt 0
        $vmCount = $vms.Count

        if ($vmCount)
        {
            $vcsaServer = $Config.vcsaServer
            $emailRepicent = $Config.emailRepicent
            $time = Get-Date

            $Message = "There are $vmCount virtual machines with snapshots taking up valuable disk space!<p>"
            $Footer = "Collected from $vcsaServer at $time"
            $Subject = "VM Snapshot information"
            $Head = [string](Get-Content $Config.headerFile)
            $Body = [string]($vms | ConvertTo-Html -PreContent $Message -PostContent $Footer -Title $Subject -Head $Head)

            Send-MailMessage -To $Config.emailRepicent -From $Config.emailSender -Subject $Subject -BodyAsHtml -Body $Body -SmtpServer $Config.smtpServer
            Write-Host "Successfully sent mail to $emailRepicent with information which $vmCount VMs has snapshots."
        } else {
            Write-Host "No VMs have snapshots."  
        }
    } catch {
        Write-Error "There were errors occuring while running script..."
    }
}

END {

}
