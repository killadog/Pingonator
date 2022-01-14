# Pingonator
![Powershell >= 7.0](https://img.shields.io/badge/Powershell-%3E=7.0-blue.svg)

Parallel ping

`.\pingonator.ps1 [-net <сеть>] [-start <число>] [-end <число>] [-count <число>] [-resolve <0|1>] [-mac <0|1>] [-latency <0|1>] [-grid <0|1>] [-file <0|1>] [-port <список портов>] [-exclude <список IP>]`

|Параметр|Описание|По умолчанию|
|---|---|---|
|-net|Сеть сканирования|192.168.0|
|-start|Начало диапазона сканирования [1..254]|1|
|-end|Конец диапазона сканирования [1..254]|254|
|-count|Число отправляемых запросов проверки связи [1..4]|1|
|-resolve|Разрешение имён узлов[0..1]|1|
|-mac|Разрешение MAC адреса узла[0..1]|1|
|-latency|Отклик узла в миллисекундах [0..1]|1|
|-grid|Вывод в Grid [0..1]|0|
|-file|Экспорт в CSV файл [0..1]|0|
|-port|Проверка открытых портов (через запятую) [0..65535]||
|-exclude|Узлы исключённые из проверки (через запятую) [0..255]||

Примеры:

`.\pingonator.ps1 -net 10.10.0 -start 20 -end 140 -count 2 -resolve 1 -mac 1 -latency 1 -grid 1 -file 1 -port 25,80 -exclude 1,23`

`.\pingonator.ps1 -net 10.10.0 -start 20`

`.\pingonator.ps1 -net 10.10.0`

`.\pingonator.ps1`