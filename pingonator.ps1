<#
.DESCRIPTION
    Pingonator
.EXAMPLE
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
    .\pingonator.ps1 -net 192.168.0 -start 1 -end 254 -count 1 -resolve 1 -mac 1 -latency 1
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
    [int] $mac = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $latency = 1
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

function ColorValue {
    param (     
        [Parameter(Mandatory = $False)][string]$Column_Name,
        [Parameter(Mandatory = $False)][string]$color
    )
    $e = [char]27
    "$e[${color}m$($Column_Name)${e}[0m"
}

$live_ips = @()
$range = $end - $start + 1
[ref]$counter = 0
    
Write-Host "ICMP check $range IPs from $net.$start to $net.$end"
$ping_time = Measure-Command {
    $pingout = $start..$end | ForEach-Object -ThrottleLimit $range -Parallel {
        $ip_list = $using:live_ips
        $ip = $using:net + "." + $_
        $($using:counter).Value++
        $status = " " + $($using:counter).Value.ToString() + "/$using:range - $ip"
        Write-Progress -Activity "Ping" -Status $status -PercentComplete (($($using:counter).Value / $using:range) * 100)
        $ping = Test-Connection $ip -Count $using:count -IPv4 
        if ($ping.Status -eq "Success") {
            if ($using:resolve) {            
                try {
                    $Name = Test-Connection $ip -Count 1 -IPv4 -ResolveDestination | Select-Object -ExpandProperty Destination
                    <# $Name = Resolve-DnsName -Name $ip -DnsOnly -ErrorAction Stop | Select-Object -ExpandProperty NameHost #>
                }
                catch {
                    $Name = $null
                }
            }
            if ($using:mac -eq 1) {
                $MAC = (arp -a $ip | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value
                if ($MAC) {
                    $MAC = $MAC.ToUpper()
                }
            }
            if ($using:latency -eq 1) {
                $ms = $ping.Latency
            }
            $ip_list += [PSCustomObject] @{
                'IP address' = $ip
                'Name'       = $Name
                'MAC'        = $MAC
                'Latency'    = $ms
            }
        }
        return $ip_list
    } 
    
    $live_ips = $pingout.count
    $pingout | Sort-Object { $_.'IP Address' -as [Version] } | Format-Table -AutoSize -Wrap -Property @{name = "IP address"; Expression = { ColorValue $_.'IP address' 32 } },
    @{name = "Name"; Expression = { ColorValue $_.Name 33 } },
    @{name = "MAC address"; Expression = { ColorValue $_.MAC 37 } },
    @{name = "Latency (ms)"; Expression = { if ($_.Latency -gt 100) { ColorValue $_.Latency 31 } else { ColorValue $_.Latency 32 } }; align = 'center' } | Out-Default
}
Write-Host "Total " -NoNewline
Write-Host " $live_ips " -NoNewline -ForegroundColor Black -BackgroundColor Gray
Write-Host " live IPs from $range [$net.$start..$net.$end]"

$ping_time = $ping_time.ToString().SubString(0, 8)
Write-Host "Total ping time $ping_time"

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


