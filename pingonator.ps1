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

$live_ips = @()
$range = $end - $start + 1
[ref]$counter = 0
    
Write-Host "ICMP check IPs from $net.$start to $net.$end"
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
                $get_MAC = (arp -a $ip | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value
            }
            if ($using:latency -eq 1) {
                $ms = $ping.Latency
            }
            $ip_list = New-Object PSObject -property @{IP = $ip; Name = $Name; MAC = $get_MAC; Latency = $ms }
        }
        return $ip_list
    }

    <# [array]$a= $pingout | foreach-object {    
        [PSCustomObject]@{
            'IP'         = $_.IP
            'IP Address' = $_.Name
            'Scope Name' = $_.MAC
            'Comment'    = $_.Latency
        }
    }
  #>
 
    Write-Host "Total $($pingout.count) live IPs from $range [$start..$end]"
    $pingout |  Sort-Object { $_.IP -as [Version] } | foreach-object {    

        write-host $_.IP.PadRight(16, ' ') -NoNewline -ForegroundColor Green
        if ($_.Name) {
            write-host $_.Name.PadRight(27, ' ') -NoNewline -ForegroundColor Yellow 
        }
        else {
            write-host " ".PadRight(27, ' ') -NoNewline
        }
        if ($_.MAC) {
            write-host $_.MAC.PadRight(22, ' ').ToUpper() -NoNewline 
        }
        else {
            write-host " ".PadRight(22, ' ') -NoNewline
        }
        if ($_.Latency) {
            Write-Host $_.Latency -NoNewline -ForegroundColor Yellow 
        }      
        Write-Host "`r"
    } | Format-Table | Out-String
}

$ping_time = $ping_time.ToString().SubString(0, 8)
Write-Host "Total ping time $ping_time"

<# Write-Host 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); #>


