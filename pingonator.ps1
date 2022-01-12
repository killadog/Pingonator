<#
.DESCRIPTION
    Pingonator
.EXAMPLE
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
    .\pingonator.ps1 -net 192.168.0 -start 1 -end 254 -count 2 -resolve 1
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
    
    
    [ValidateRange(1, 254)]
    [int] $end = 254,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 4)]
    [int] $count = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)] 
    [int] $resolve = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $mac = 1
)

#Requires -Version 7.0

if ($net -notmatch '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){3}$') {
    Write-Error "Not valid IP address! Syntax: 192.168.0"
    exit;
}

if ($start -gt $end) {
    Write-Error "-start cannot be greater than -end";
    exit;
}

$live_ips = @()
$range = $end - $start + 1
$counter = [ref]0
    
Write-Host "ICMP check IPs from $net.$start to $net.$end"
$ping_time = Measure-Command {
    $pingout = $start..$end | ForEach-Object -ThrottleLimit $range -Parallel {
        $ips = $using:live_ips
        $ip = $using:net + "." + $_
        $ip_counter = $using:counter
        $ip_counter.Value++
        $status = "$($ip_counter.Value)/$using:range - $ip"
        Write-Progress -Activity "Ping" -Status $status -PercentComplete (($ip_counter.Value / $using:range) * 100)    
        $ping = Test-Connection $ip -Count $using:count -IPv4  | Select-Object -ExpandProperty Address
        if ($ping) {
            if ($using:mac -eq 1) {
                $get_MAC = (arp -a $ip | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value
            }
            if ($using:resolve) {            
                try {
                    <# $Name = Test-Connection $ip -Count 1 -IPv4 -ResolveDestination | Select-Object -ExpandProperty Destination #>
                    $Name = Resolve-DnsName -Name $ip -DnsOnly -ErrorAction Stop | Select-Object -ExpandProperty NameHost
                }
                catch {
                    $Name = $null
                }
            }
            $ips = New-Object PSObject -property @{IP = $ip; MAC = $get_MAC; Name = $Name }
        }
        return $ips
    }
    Write-Host "Total $($pingout.count) live IPs from $range [$start..$end]"
    <# $pingout |  Sort-Object { $_.IP -as [Version] } | Out-Default #>
    $pingout | foreach-object { 
        write-host $_.IP.trim().PadRight(16, ' ') -NoNewline -ForegroundColor Green
        <# Write-Host "$($_.IP) " -NoNewline -ForegroundColor Green #>
        if ($_.Name) { write-host $_.Name.trim().PadRight(27, ' ') -NoNewline -ForegroundColor Yellow }
        <# Write-Host "$($_.Name) " -NoNewline -ForegroundColor Yellow #>
        if ($_.MAC) { write-host $_.MAC.trim().PadRight(90, ' ') -NoNewline }
        Write-Host "`r"
        <# Write-Host $_.MAC -ForegroundColor White #>
    } | Format-List
}

$ping_time = $ping_time -join ""
$ping_time = $ping_time.SubString(0, 8)
Write-Host "Total ping time $ping_time"

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


