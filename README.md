# Pingonator
![Powershell >= 7.0](https://img.shields.io/badge/Powershell-%3E=7.0-blue.svg)

Parallel ping

`.\pingonator.ps1 [-net <сеть>] [-start <число>] [-end <число>] [-count <число>] [-resolve <0|1>]`

|Параметр|Описание|По умолчанию|
|---|---|---|
|-net|Сеть сканирования|192.168.0|
|-start|Начало диапазона сканирования [1..254]|1|
|-end|Конец диапазона сканирования [1..254]|254|
|-count|Число отправляемых запросов проверки связи [1..4]|1|
|-resolve|Разрешение имён [0..1]|1|
|-resolve|Разрешение MAC адреса [0..1]|1|

Примеры:

`.\pingonator.ps1 -net 10.10.0 -start 20 -end 140 -count 2 -resolve 1 -mac 1`

`.\pingonator.ps1 -net 10.10.0 -start 20`

`.\pingonator.ps1 -net 10.10.0`

`.\pingonator.ps1`