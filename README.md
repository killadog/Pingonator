# Pingonator
![Powershell >= 7.0](https://img.shields.io/badge/Powershell-%3E=7.0-blue.svg)

![2022-01-14 213024](https://user-images.githubusercontent.com/47281323/149566817-fff15bd9-02ed-487e-b66b-02682a1f5150.png)

Parallel network check

`.\pingonator.ps1 [-net <сеть>] [-start <число>] [-end <число>] [-count <число>] [-resolve] [-mac] [-latency] [-grid] [-file] [-ports <список портов>] [-exclude <список IP>]`

|Options|Explanation|Default value|
|---|---|:---:|
|-net|Netowrk to scan|192.168.0|
|-start|Start scan number [1..254]|1|
|-end|End scan number [1..254]|254|
|-count|Number of echo request to send [1..4]|1|
|-resolve|Disable resolve of hostname|False|
|-mac|Disable resolve of MAC address |False|
|-latency|Hide latency|False|
|-grid|Output to a grid view|False|
|-file|Export to CSV file|False|
|-ports|Check open ports (comma or hyphen) [0..65535,0..65535,0..65535-0..65535]||
|-exclude|Hosts exluded from check (comma or hyphen) [0..255,0..255,0..255-0..255]||

Examples:

`.\pingonator.ps1 -net 10.10.0 -start 20 -end 140 -count 2 -resolve -mac -latency -grid -file -ports 20-23,25,80 -exclude 1,23,41-49`

`.\pingonator.ps1 -net 10.10.0 -start 20`

`.\pingonator.ps1 -net 10.10.0`

`.\pingonator.ps1`
