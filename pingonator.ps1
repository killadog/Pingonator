<#
.DESCRIPTION
    Pingonator
.EXAMPLE
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
    .\pingonator.ps1 -net 192.168.0 -start 1 -end 254
    or
    .\pingonator.ps1 -net 192.168.0
.NOTES
    Author: Rad
    Date:   December 9, 2021    
#>
param (
    [parameter(Mandatory = $false)]
    [string]$net = "192.168.0",
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $start = 1,
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $end = 254,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 4)]
    [int] $count = 1
)
if ($start -gt $end) {
    Write-Error "-start cannot be greater than -end";
    exit;
}

$live_ips = @()
$range = $end - $start + 1
$counter = [ref]0
    
Write-Host "ICMP check IPs from $net.$start to $net.$end"
$pingout = $start..$end | ForEach-Object -ThrottleLimit $range -Parallel {
    $ips = $using:live_ips
    $ip = $using:net + "." + $_
    $ip_counter += $using:counter
    $ip_counter.Value++
    $status = "$($ip_counter.Value)/$using:range - $ip"
    Write-Progress -Activity "Ping" -Status $status -PercentComplete (($ip_counter.Value / $using:range) * 100)    
    $ping = Test-Connection $ip -Count $using:count -IPv4  | Select-Object -ExpandProperty Address
    if ($ping) {
        $MAC = (arp -a $ip | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value
        $Name = Test-Connection $ip -Count 1 -IPv4 -ResolveDestination | Select-Object -ExpandProperty Destination
        $ips = New-Object PSObject -property @{IP = $ip; MAC = $MAC; Name = $Name }
    }
    return $ips
} 
    
Write-Host "Total $($pingout.count) live IPs from $range [$start..$end]:"
$pingout | Select-Object ip, name, mac | Sort-Object { $_.IP -as [Version] }
    

