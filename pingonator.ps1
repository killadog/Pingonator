<#
.SYNOPSIS 
Parallel network check
.EXAMPLE
Ping network 192.168.0.0 in range 192.168.0.1-192.168.0.254
PS> .\pingonator.ps1 -net 192.168.0 -begin 1 -end 254 -count 1 -resolve -mac -latency -grid -ports 20-23,25,80 -exclude 3,4,9-12 -color -progress -help
or
PS> .\pingonator.ps1 -net 192.168.0
.NOTES
Author: Rad
Date: December 9, 2021
URL: https://github.com/killadog/Pingonator 
#>
param (
    [parameter(Mandatory = $false)][string[]] $net ## Network(s) to scan. Required. Comma or dash delimited. Like 192.168.0 or 192.168.0-6,10.10.0
    , [parameter(Mandatory = $false)][ValidateRange(1, 254)][int] $begin = 1 ## First number to scan [1..254]
    , [parameter(Mandatory = $false)][ValidateRange(1, 254)][int] $end = 254 ## Last number to scan [1..254]
    , [parameter(Mandatory = $false)][ValidateRange(1, 4)][int] $count = 1 ## Number of echo request to send [1..4]
    , [parameter(Mandatory = $false)][switch] $resolve ## Disable resolve of hostname
    , [parameter(Mandatory = $false)][switch] $mac ## Disable resolve of MAC address
    , [parameter(Mandatory = $false)][switch] $latency ## Hide latency
    , [parameter(Mandatory = $false)][switch] $grid ## Output to a grid view
    , [parameter(Mandatory = $false)][switch] $file ## Export to CSV file
    , [parameter(Mandatory = $false)][string[]] $ports ## Detect open ports (comma or dash delimited) [0..65535,0..65535,0..65535-0..65535]
    , [parameter(Mandatory = $false)][string[]] $exclude ## Exlude hosts from check (comma or dash delimited) [0..255,0..255,0..255-0..255]
    , [parameter(Mandatory = $false)][switch] $color ## Colors off
    , [parameter(Mandatory = $false)][switch] $progress ## Progress bar off
    , [parameter(Mandatory = $false)][switch] $help ## This help screen
)

#Requires -Version 7.0

if (($color) -or (($PSVersionTable.PSVersion.Major -eq 7) -and ($PSVersionTable.PSVersion.Minor -lt 2))) {
    $PSStyle.OutputRendering = 'PlainText'
}
else {
    $PSStyle.OutputRendering = 'Ansi'
    $PSStyle.Progress.View = 'Minimal'
    $PSStyle.Progress.MaxWidth = 120
    $PSStyle.Formatting.TableHeader = $PSStyle.Foreground.BrightBlack + $PSStyle.Italic
}

if ($help -or !$net) {
    Get-Command -Syntax .\pingonator.ps1
    Get-Help .\pingonator.ps1 -Parameter * | Format-Table -Property @{name = 'Option'; Expression = { $($PSStyle.Foreground.BrightGreen) + "-" + $($_.'name') } },
    @{name = 'Type'; Expression = { $($PSStyle.Foreground.BrightWhite) + $($_.'parameterValue') } },
    @{name = 'Default'; Expression = { if ($($_.'defaultValue' -notlike 'String')) { $($PSStyle.Foreground.BrightWhite) + $($_.'defaultValue') } }; align = 'Center' },
    @{name = 'Explanation'; Expression = { $($PSStyle.Foreground.BrightYellow) + $($_.'description').Text } }
    exit
}

if ($net -notmatch '^(((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$|[,]|(-(25[0-5]|(2[0-4]|1\d|[1-9]|)\d),*))){3})+$') {
    $PSStyle.Formatting.Error = $PSStyle.Background.BrightRed + $PSStyle.Foreground.BrightWhite
    Write-Error "Not valid IP address! Syntax: 192.168.0 or 192.168.0,10.10.12-16"
    exit;
}

$net_from_range = @()
foreach ($n in $net) {
    if ($n -like "*-*") {
        $splitter = $n.split(".")
        $splitter2 = $splitter[2].split("-")
        $net_range = $splitter2[0]..$splitter2[1]
        foreach ($r in $net_range) {
            $net_from_range += $splitter[0] + "." + $splitter[1] + "." + $r
        }
    }
    else {
        $net_from_range += $n
    }
}
$net = $net_from_range | Select-Object -Unique

$ports_list = @()
if ($ports -ne 0) {
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
if ($exclude) {
    foreach ($e in $exclude) {
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
}

$range = [Math]::Abs($end - $begin) + 1 - $exclude_list.Name.count
$now = Get-Date -UFormat "%Y/%m/%d-%H:%M:%S"
$file_name = Get-Date -UFormat "%Y%m%d-%H%M%S"
$gridout = @()
$delimeter = (Get-Culture).TextInfo.ListSeparator

Write-Host "Starting at $now`n"
$all_time = Measure-Command {
    ForEach ($n in $net) {
        [ref]$counter = 0    
        $live_ips = @()
        Write-Host "Checking $range IPs from $n.$begin to $n.$end"

        $ping_time = Measure-Command {
            $pingout = $begin..$end | ForEach-Object -ThrottleLimit $range -Parallel {
                if (!($_ -in $($using:exclude_list))) {
                    $ip_list = $using:live_ips
                    $ip = $using:n + "." + $_
                    if (!$using:progress) {
                        $($using:counter).Value++
                        $status = " " + $($using:counter).Value.ToString() + "/$using:range - $ip"
                        Write-Progress -Activity "Ping" -Status $status -PercentComplete (($($using:counter).Value / $using:range) * 100)
                    }
                    $ping = Test-Connection $ip -Count $using:count -IPv4 
                    if ($ping.Status -eq "Success") {
                        if (!$using:resolve) {            
                            try {
                                #$Name = Test-Connection $ip -Count 1 -IPv4 -ResolveDestination | Select-Object -ExpandProperty Destination
                                $Name = Resolve-DnsName -Name $ip -DnsOnly -ErrorAction Stop | Select-Object -ExpandProperty NameHost
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
                                Write-Progress -Completed -Activity "make progress bar dissapear"
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
   
            #$prop_number = @{name = 'Number'; Expression = { '{0}' -f $_ } }
            $prop_ip = @{name = 'IP address'; Expression = { $($PSStyle.Foreground.BrightGreen) + $_.'IP address' } }
            $prop_name = @{name = 'Name'; Expression = { $($PSStyle.Foreground.BrightYellow) + $_.Name } }
            $prop_mac = @{name = 'MAC address'; Expression = { $($PSStyle.Foreground.BrightWhite) + $_.'MAC address' } }
            $prop_latency = @{name = 'Latency (ms)'; Expression = { if ($_.'Latency (ms)' -gt 100) { $($PSStyle.Foreground.BrightRed) + $_.'Latency (ms)' } else { $($PSStyle.Foreground.BrightYellow) + $_.'Latency (ms)' } }; align = 'center' }
            $prop_ports = @{name = 'Open Ports'; Expression = { $($PSStyle.Foreground.BrightGreen) + $_.'Open ports' }; align = 'center' }
 
            <# [collections.arraylist]$Properties = @() #>
            $Properties = @()
            #$Properties += $prop_number
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
            if ($ports) {
                $Properties += $prop_ports
            }
            $pingout = $pingout | Sort-Object { $_.'IP Address' -as [Version] } 
            $pingout | Format-Table  -Property $Properties | Out-Default
        }

        if ($grid) {
            $gridout += $pingout
        }

        if ($file) {
            $pingout | Export-Csv -Append -path $env:TEMP\$file_name.csv -NoTypeInformation -Delimiter $delimeter
        }

        Write-Host "Total $($PSStyle.Background.White)$($PSStyle.Foreground.Black) $live_ips $($PSStyle.Reset) live IPs from $range [$n.$begin..$n.$end]"
        $ping_time = $ping_time.ToString().SubString(0, 8)
        Write-Host "Elapsed time $ping_time`n"
    }
}

$all_time = $all_time.ToString().SubString(0, 8)
Write-Host "All time: $all_time`n"

if ($grid) {
    $gridout | Out-GridView -Title "[$now] live IPs from $net"
}

if ($file) {
    Write-Host "CSV file saved to $($PSStyle.Foreground.Yellow)$env:TEMP\$file_name.csv$($PSStyle.Reset)"
    Start-Process $env:TEMP\$file_name.csv
}

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


