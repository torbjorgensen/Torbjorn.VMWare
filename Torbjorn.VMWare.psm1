<#
    
    .SYNOPSIS
        This function retrieves the amount of snapshots virtual machines on a vCenter Server system have.

    .DESCRIPTION
        This function retrieves the amount of snapshots for all virtual machines on a vCenter Server system. Returns VM Name, Host, 
        VM Folder, Power state and Snapshot count.

    .EXAMPLE
        Get-VMsWithSnapshots vcsa.example.com
        Get a list of all VMs on the vCenter Server vcsa.example.com

    .EXAMPLE
        Get-VMsWithSnapshots -Server vcsa.example.com | Where-Object Count -gt 0
        Get a list of all VMs on the vCenter Server vcsa.example.com that have snapshots
    
#>

function Get-VMsWithSnapshots {
    [CmdletBinding()]
    param (
        [parameter( Mandatory=$True,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$True,
                    HelpMessage="IP or Hostname to vCenter server" )]
        [string]$Server
    )


    BEGIN {
        Import-Module VMware.VimAutomation.Core

        # open connection to vcenter server
        try {
            Write-Verbose "Opening connection to vCenter Server at $Server"
            $vcsaConnection = Connect-VIServer -Server $Server -ErrorAction stop
        } catch {
            Write-Error "Could not connect to vCenter server at $Server"
        }
    }


    PROCESS {
        if ($Null -ne $vcsaConnection)
        {
            Write-Verbose "Getting list of VMs..."
            $vms = Get-VM

            foreach ($vm in $vms) {
                try {
                    Write-Verbose "Checking $vm for snapshots..."

                    # TODO: add sizeMB
                    $snapshots = Get-Snapshot $vm.Name
                    $count = $snapshots | Measure-Object | Select-Object -expand Count
                    $sizeMB = $snapshots | Select-Object -expand SizeMB | Measure-Object -sum | Select-Object -expand Sum

                    if ($count -is [int32] -and $count -gt 0)
                    {
                        # VM have snapshots
                        Write-Verbose " * $vm has $count snapshots"
                        $result = @{Name = $vm
                                    VMHost = $vm.VMHost
                                    Folder = $vm.Folder
                                    PowerState = $vm.PowerState
                                    SizeMB = $sizeMB
                                    Count = $count}
                    } else {
                        # VM have no snapshots
                        $result = @{Name = $vm
                                    VMHost = $vm.VMHost
                                    Folder = $vm.Folder
                                    PowerState = $vm.PowerState
                                    SizeMB = 0
                                    Count = 0}
                    }
                } catch {
                    # unable to get snapshot information
                    $result = @{Name = $vm
                                VMHost = $null
                                Folder = $null
                                PowerState = $null
                                SizeMB = 0
                                Count = 0}
                } finally {
                    $obj = New-Object -TypeName PSObject  -property $result
                    Write-Output $obj
                }
            }
        }
    }

    
    END {
        try {
            Write-Verbose "Diconnecting from vcenter server"
            Disconnect-VIServer -Server $vcsaConnection -Confirm:$False
        } catch {
            Write-Error "Unable to disconnect from vCenter server"
        }
    }
}

