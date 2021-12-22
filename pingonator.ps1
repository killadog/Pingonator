<#
.DESCRIPTION
    Pingonator
.PARAMETER net
    network
.PARAMETER start
    start
.PARAMETER end
    start
.EXAMPLE
    .\pings.ps1 -net 192.168.0 -start 1 -end 254
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
.NOTES
    Author: Rad
    Date:   December 9, 2021    
#>
param (
    [parameter(Mandatory = $false)]
    [string]$net = "192.168.13",
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $start = 1,
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $end = 254
)

$live_ips = @()
$range = $end - $start + 1
$counter = [ref]0

Write-Host "ICMP check IPs from $net.$start to $net.$end]:"
$pingout = $start..$end | ForEach-Object -ThrottleLimit ($end - $start + 1) -Parallel {
    $ips = $using:live_ips
    $ip = $using:net + "." + $_
    $ip_counter = $using:counter
    $ip_counter.Value++
    $status = "$($ip_counter.Value)/$using:range - $ip"
    Write-Progress -Activity "Ping" -Status $status -PercentComplete (($ip_counter.Value / $using:range) * 100)    
    $cmd = Test-Connection $ip -Count 1 -IPv4  | Select-Object -ExpandProperty Address
    if ($cmd) {
        $ips += $ip
    }
    return $ips
} 

Write-Host "Total $($pingout.count) live IPs from $range [$start..$end]:"
$list = $pingout | Sort-Object { $_ -as [Version] } | Out-String
Write-Host $list -ForegroundColor Green
