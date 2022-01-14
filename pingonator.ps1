<#
.DESCRIPTION
    Pingonator
.EXAMPLE
    Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
    .\pingonator.ps1 -net 192.168.0 -start 1 -end 254 -count 1 -resolve 1 -mac 1 -latency 1 -grid 1 -ports 20-23,25,80 -exclude 3,4,9-12
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
    [int] $count = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)] 
    [int] $resolve = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $mac = 1,

    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $latency = 1,
    
    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $grid = 0,
    
    [parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [int] $file = 0,

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

if ($start -gt $end) {
    Write-Error "-start cannot be greater than -end";
    exit;
}

$ports_list = @()
#$ports = $ports -replace (' ', '')
foreach ($p in $ports) {
    if ($p -match '(^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$)|(^([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])-([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$)|((?<=,|^)([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])(?=,|$),?)|((?<=,|^)([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])-([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])(?=,|$),?)') {
        <# if (($p -match '^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{1,3}|[0-9])$') -or #>
        <# ($p -match '^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{0,3})-(?1)|(?1)(,(?1))+$')) { #>
        <# ($p -match '^(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{1,3}|[0-9])-(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{1,3}|[0-9])$')) { #>
    
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
        Write-Error "Not valid ip in exclude! Only [0..255]. Syntax: 1,23,248-254"
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
$range = $end - $start + 1 - $($exclude_list.Name).Count
[ref]$counter = 0
$now = Get-Date -UFormat "%Y/%m/%d-%H:%M:%S"
Write-Host "Starting at $now"

Write-Host "ICMP check $range IPs from $net.$start to $net.$end"
$ping_time = Measure-Command {
    $pingout = $start..$end | ForEach-Object -ThrottleLimit $range -Parallel {
        if (!($_ -in $($using:exclude_list))) {
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

    $pingout = $pingout | Sort-Object { $_.'IP Address' -as [Version] } 
    
    $pingout | Format-Table -Property @{name = "IP address"; Expression = { ColorValue $_.'IP address' 92 } },
    @{name = "Name"; Expression = { ColorValue $_.Name 93 } },
    @{name = "MAC address"; Expression = { ColorValue $_.'MAC address' 97 } },
    @{name = "Latency (ms)"; Expression = { if ($_.'Latency (ms)' -gt 100) { ColorValue $_.'Latency (ms)' 91 } else { ColorValue $_.'Latency (ms)' 93 } }; align = 'center' },
    @{name = "Open Ports"; Expression = { ColorValue $_.'Open ports' 92 }; align = 'center' } | Out-Default
}

if ($grid -eq 1) {
    $pingout | Out-GridView -Title "[$now] $live_ips live IPs from $range [$net.$start..$net.$end]"
}

if ($file -eq 1) {
    $file_name = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $delimetr = (Get-Culture).TextInfo.ListSeparator
    $pingout | Export-CSv -path .\$file_name.csv -NoTypeInformation -Delimiter $delimetr
}

Write-Host "Total $($PSStyle.Background.White)$($PSStyle.Foreground.Black) $live_ips $($PSStyle.Reset) live IPs from $range [$net.$start..$net.$end]"
$ping_time = $ping_time.ToString().SubString(0, 8)
Write-Host "Total ping time $ping_time"

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


