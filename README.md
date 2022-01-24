# Pingonator

![Powershell >= 7.2](https://img.shields.io/badge/Powershell-%3E=7.2-blue.svg)

## Parallel network check

*fast and furious*

![2022-01-14 213024](https://user-images.githubusercontent.com/47281323/149566817-fff15bd9-02ed-487e-b66b-02682a1f5150.png)


### System requirements
#### Minimum
- Powershell 7.0 for parallelizing work
#### Recommended
- Powershell 7.2 for ANSI escape sequences
- [xterm](https://en.wikipedia.org/wiki/Xterm)-based terminal
### Pingonator command syntax

>**.\pingonator.ps1** **-net** *network* [**-begin** *count*] [**-end** *count*] [**-count** *count*] [**-resolve**] [**-mac**] [**-latency**] [**-grid**] [**-file**] [**-ports** *ports*] [**-exclude** *ips*] [**-color**] 

|Options|Explanation|Default value|
|---|---|:---:|
|**-net** *network*|Network to scan (required). Like 192.168.0||
|**-begin** *count*|First number to scan [1..254]|1|
|**-end** *count*|Last number to scan [1..254]|254|
|**-count** *count*|Number of echo request to send [1..4]|1|
|**-resolve**|Disable resolve of hostname|False|
|**-mac**|Disable resolve of MAC address |False|
|**-latency**|Hide latency|False|
|**-grid**|Output to a grid view|False|
|**-file**|Export to CSV file|False|
|**-ports**|Detect open ports (comma or dash delimited) [0..65535,0..65535,0..65535-0..65535]||
|**-exclude**|Exlude hosts from check (comma or dash delimited) [0..255,0..255,0..255-0..255]||
|**-color**|Colors off|False|
|**-help**|Help screen|False|

### Examples

`.\pingonator.ps1 -net 10.10.0 -begin 20 -end 140 -count 2 -resolve -mac -latency -grid -file -ports 20-23,25,80 -exclude 1,23,41-49 -color`

`.\pingonator.ps1 -net 10.10.0 -begin 20`

`.\pingonator.ps1 -net 10.10.0`

