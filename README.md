# Pingonator
![Powershell >= 7.0](https://img.shields.io/badge/Powershell-%3E=7.0-blue.svg)

![2022-01-14 213024](https://user-images.githubusercontent.com/47281323/149566817-fff15bd9-02ed-487e-b66b-02682a1f5150.png)

Parallel ping

`.\pingonator.ps1 [-net <сеть>] [-start <число>] [-end <число>] [-count <число>] [-resolve] [-mac] [-latency] [-grid] [-file] [-ports <список портов>] [-exclude <список IP>]`

|Параметр|Описание|По умолчанию|
|---|---|:---:|
|-net|Сеть сканирования|192.168.0|
|-start|Начало диапазона сканирования [1..254]|1|
|-end|Конец диапазона сканирования [1..254]|254|
|-count|Число отправляемых запросов проверки связи [1..4]|1|
|-resolve|Отключить разрешение имён узлов|False|
|-mac|Отключить разрешение MAC адреса узла|False|
|-latency|Не показывать отклик узла в миллисекундах|False|
|-grid|Вывод в Grid|False|
|-file|Экспорт в CSV файл|False|
|-ports|Проверка открытых портов через запятую (или диапазона через дефис) [0..65535,0..65535,0..65535-0..65535]||
|-exclude|Узлы через запятую (или диапазоны через дефис) исключённые из проверки [0..255,0..255,0..255-0..255]||

Примеры:

`.\pingonator.ps1 -net 10.10.0 -start 20 -end 140 -count 2 -resolve -mac -latency -grid -file -ports 20-23,25,80 -exclude 1,23,41-49`

`.\pingonator.ps1 -net 10.10.0 -start 20`

`.\pingonator.ps1 -net 10.10.0`

`.\pingonator.ps1`
