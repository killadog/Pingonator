<#
.DESCRIPTION
    Parallel network check
.EXAMPLE
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
    .\pingonator.ps1 -net 192.168.0 -start 1 -end 254 -count 1 -resolve 1 -mac 1 -latency 1 -grid 1 -ports 20-23,25,80 -exclude 3,4,9-12
    or
    .\pingonator.ps1 -net 192.168.0
.NOTES
    Author: Rad
    Date: December 9, 2021
    URL: https://github.com/killadog/Pingonator
#>
param (
    [parameter(Mandatory = $false)]
    [string]$net = "192.168.0",
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $begin = 1,
    
    [parameter(Mandatory = $false)]
    [ValidateRange(1, 254)]
    [int] $end = 254,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 4)]
    [int] $count = 1,

    [parameter(Mandatory = $false)]
    [switch] $resolve,

    [parameter(Mandatory = $false)]
    [switch] $mac,

    [parameter(Mandatory = $false)]
    [switch] $latency,
    
    [parameter(Mandatory = $false)]
    [switch] $grid,
    
    [parameter(Mandatory = $false)]
    [switch] $file,

    [parameter(Mandatory = $false)]
    [string[]] $ports = 0,

    [parameter(Mandatory = $false)]
    [string[]] $exclude = 0
)

#Requires -Version 7.0
$PSStyle.Progress.View = 'Minimal'
$PSStyle.Progress.MaxWidth = 120

if ($net -notmatch '^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){3}$') {
    Write-Error "Not valid IP address! Syntax: 192.168.0"
    exit;
}

$ports_list = @()
if ($ports -ne 0) {
    #$ports = $ports -replace (' ', '')
    foreach ($p in $ports) {
        if ($p -match '(^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$)|(^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])-([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$)|((?<=,|^)([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])(?=,|$),?)|((?<=,|^)([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])-([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])(?=,|$),?)') {
            if ($p -like "*-*") {
                $splitter = $p.split("-")
                $splitter_array = $splitter[0]..$splitter[1]
                $ports_list += $splitter_array 
            }
            else {
                $ports_list += $p
            }
        }
        else {
            Write-Error "Not valid ports! Only [1..65535]. Syntax: 25,80,135,1096-2048"
            exit;    
        }
    }
    $ports_list = $ports_list | Select-Object -Unique
}

$exclude_list = @()
foreach ($e in $exclude) {
    #$e = $e -replace (' ', '')
    if (($e -match '^(25[0-5]|(2[0-4]|1\d|[1-9]|)\d)$') -or ($e -match '^(25[0-5]|(2[0-4]|1\d|[1-9]|)\d)-(25[0-5]|(2[0-4]|1\d|[1-9]|)\d)$')) {
        if ($e -like "*-*") {
            $splitter = $e.split("-")
            $splitter_array = $splitter[0]..$splitter[1]
            $exclude_list += $splitter_array 
        }
        else {
            $exclude_list += $e    
        }
    } 
    else {
        Write-Error "Not valid ip in -exclude! Only [0..255]. Syntax: 1,23,248-254"
        exit;    
    }
}
$exclude_list = $exclude_list | Select-Object -Unique

function ColorValue {
    param (     
        [Parameter(Mandatory = $False)][string]$Column_Name,
        [Parameter(Mandatory = $False)][string]$color
    )
    $e = [char]27
    "$e[${color}m$($Column_Name)${e}[0m"
}

$live_ips = @()
$range = [Math]::Abs($end - $begin) + 1 - $exclude_list.Name.count
[ref]$counter = 0
$now = Get-Date -UFormat "%Y/%m/%d-%H:%M:%S"

Write-Host "Starting at $now"
Write-Host "Checking $range IPs from $net.$begin to $net.$end"

$ping_time = Measure-Command {
    $pingout = $begin..$end | ForEach-Object -ThrottleLimit $range -Parallel {
        if (!($_ -in $($using:exclude_list))) {
            $ip_list = $using:live_ips
            $ip = $using:net + "." + $_
            $($using:counter).Value++
            $status = " " + $($using:counter).Value.ToString() + "/$using:range - $ip"
            Write-Progress -Activity "Ping" -Status $status -PercentComplete (($($using:counter).Value / $using:range) * 100)
            $ping = Test-Connection $ip -Count $using:count -IPv4 
            if ($ping.Status -eq "Success") {
                if (!$using:resolve) {            
                    try {
                        $Name = Test-Connection $ip -Count 1 -IPv4 -ResolveDestination | Select-Object -ExpandProperty Destination
                        <# $Name = Resolve-DnsName -Name $ip -DnsOnly -ErrorAction Stop | Select-Object -ExpandProperty NameHost #>
                    }
                    catch {
                        $Name = $null
                    }
                }
                if (!$using:mac) {
                    $MAC = (arp -a $ip | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value
                    if ($MAC) {
                        $MAC = $MAC.ToUpper()
                    }
                }
                if (!$using:latency) {
                    $ms = $ping.Latency
                }

                if ($($using:ports_list) -ne 0) { 
                    ForEach ($p in $($using:ports_list)) {
                        $check_port = Test-NetConnection -ComputerName $ip -InformationLevel Quiet -Port $p -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                        if ($check_port) {
                            $open_ports += "$p "
                        }
                    } 
                }

                $ip_list += [PSCustomObject] @{
                    'IP address'   = $ip
                    'Name'         = $Name
                    'MAC address'  = $MAC
                    'Latency (ms)' = $ms
                    'Open ports'   = $open_ports
                }
            }
        }
        return $ip_list
    } 
    
    $live_ips = $($pingout.'IP address').count
    
    $prop_ip = @{name = 'IP address'; Expression = { ColorValue $_.'IP address' 92 } } 
    $prop_name = @{name = 'Name'; Expression = { ColorValue $_.Name 93 } }
    $prop_mac = @{name = 'MAC address'; Expression = { ColorValue $_.'MAC address' 97 } }
    $prop_latency = @{name = 'Latency (ms)'; Expression = { if ($_.'Latency (ms)' -gt 100) { ColorValue $_.'Latency (ms)' 91 } else { ColorValue $_.'Latency (ms)' 93 } }; align = 'center' }
    $prop_ports = @{name = 'Open Ports'; Expression = { ColorValue $_.'Open ports' 92 }; align = 'center' }

    <# $prop_ip = @{name = 'IP address'; Expression = { $($PSStyle.Foreground.BrightGreen) + $_.'IP address' } }
    $prop_name = @{name = 'Name'; Expression = { $($PSStyle.Foreground.BrightYellow) + $_.Name } }
    $prop_mac = @{name = 'MAC address'; Expression = { ColorValue $_.'MAC address' 97 } }
    $prop_latency = @{name = 'Latency (ms)'; Expression = { if ($_.'Latency (ms)' -gt 100) { ColorValue $_.'Latency (ms)' 91 } else { ColorValue $_.'Latency (ms)' 93 } }; align = 'center' }
    $prop_ports = @{name = 'Open Ports'; Expression = { ColorValue $_.'Open ports' 92 }; align = 'center' }
 #>
    [collections.arraylist]$Properties = @()
    $Properties += $prop_ip
    if (!$resolve) {
        $Properties += $prop_name
    }
    if (!$mac) {
        $Properties += $prop_mac
    }
    if (!$latency) {
        $Properties += $prop_latency
    }
    if ($ports -ne 0) {
        $Properties += $prop_ports
    }
    $PSStyle.Formatting.TableHeader = $PSStyle.Foreground.BrightWhite + $PSStyle.Bold
    $pingout = $pingout | Sort-Object { $_.'IP Address' -as [Version] } 
    $pingout | Format-Table  -Property $Properties | Out-Default
}

if ($grid) {
    $pingout | Out-GridView -Title "[$now] $live_ips live IPs from $range [$net.$begin..$net.$end]" 
}

if ($file) {
    $file_name = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $delimeter = (Get-Culture).TextInfo.ListSeparator
    $pingout | Export-Csv -path .\$file_name.csv -NoTypeInformation -Delimiter $delimeter
    Write-Host "CSV file saved in $($PSStyle.Foreground.Yellow)$PSScriptRoot\$file_name.csv$($PSStyle.Reset)"
}

Write-Host "Total $($PSStyle.Background.White)$($PSStyle.Foreground.Black) $live_ips $($PSStyle.Reset) live IPs from $range [$net.$begin..$net.$end]"
$ping_time = $ping_time.ToString().SubString(0, 8)
Write-Host "Total ping time $ping_time"

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


