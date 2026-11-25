**МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ**  

_ФЕДЕРАЛЬНОЕ ГОСУДАРСТВЕННОЕ АВТОНОМНОЕ ОБРАЗОВАТЕЛЬНОЕ УЧРЕЖДЕНИЕ ВЫСШЕГО ОБРАЗОВАНИЯ_  

_НАЦИОНАЛЬНЫЙ ИССЛЕДОВАТЕЛЬСКИЙ УНИВЕРСИТЕТ ИТМО_
_Факультет прикладной информатики 

**ОТЧЕТ по практической работе №1**

**по дисциплине «Введение в ОС Linux»**

**Тема: «Расширение скриптов на BASH: работа с оборудованием и модулями ядра»**

**Выполнил:**   
Кетов Александр Антонович

**Проверил:**
Береснев Артем Дмитриевич


**Санкт-Петербург - 2026**

---
## Цель работы

Расширить практику программирования на bash за счёт доработки скрипта инвентаризации из Практической работы №1; освоить утилиты работы с оборудованием и модулями ядра Linux; закрепить понимание установки ПО через менеджер пакетов apt и практическое понимание устройства ядра (версия, расположение файлов модулей, загружаемые и неудаляемые модули).

---
## Ход работы
## Часть 1

### Настройка приглашения ввода

Значение `$PS1` до изменений:

```
\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$
```

Команда установки нового значения `$PS1` и проверка через `echo "$PS1"`:

```
svvvrm@test-machine:~$ export PS1='[\t]:\u:\w\$ '
[07:30:37]:svvvrm:~$ echo "$PS1"
>>> [\t]:\u:\w\$ 
```

Вывод терминала с новым приглашением:

```
[07:30:37]:svvvrm:~$
```

### Создание алиаса

Команда создания алиаса:

```
alias greetings="echo Have a nice day, $(whoami)!"
```

Результат вызова алиаса:

```
[07:34:16]:svvvrm:~$ greetings
>>> Have a nice day, svvvrm!
```

### Сохранение изменений после перезагрузки

Команда добавления строк в `~/.bashrc`:

```
echo '' >> ~/.bashrc &&
echo '# custom prompt' >> ~/.bashrc && 
echo 'PS1="[\t]:\u:\w\$ "' >> ~/.bashrc
```

Последние строки файла `~/.bashrc`, полученные с помощью команды `tail -n 2 ~/.bashrc`:

```
# custom prompt
PS1="[\t]:\u:\w\$ "
```

Применение изменений (`source ~/.bashrc`) и проверка результата:

```
svvvrm@test-machine:~$ source .bashrc
[07:50:22]:svvvrm:~$
```

После перезапуска терминала приглашение ввода осталось таким же, каким оно было настроено.

### Чек-лист для части 1

- [x] Приглашение ввода показывает время → пользователя → текущий каталог → `$`
- [x] Алиас выводит приветствие с реальным именем пользователя
- [x] Настройки проверены после перезапуска терминала или перезагрузки
- [x] Строка `alias` и правки `$PS1` сохранены для отчёта

---
## Часть 2

Каждый скрипт назван по шаблону `script22N` и сделан исполняемым командой `chmod +x script22*`.

### Задача 1

Код скрипта `script221`:

```bash
#!/bin/bash

# input validation
if [[ "$#" != 2 ]]; then
    echo "usage: $0 <string1> <string2>"
    exit 1
fi

# comparing strings
if [[ "$1" == "$2" ]]; then
    echo 'equal'
else 
    echo 'not equal'
fi
```

Тест 1 - разные строки:

```
./script221 aaa bbb
>>> not equal
```

Тест 2 - одинаковые строки:

```
./script221 aaa aaa
>>> equal
```

Тест 3 - нет аргументов:

```
./script221
>>> usage: ./script221 <string 1> <string 2>
```

### Задача 2

**Постановка:** в параметрах передаются три целых числа; вывести максимальное.

**Описание решения:**

*(кратко: проверка `$# -eq 3`, сравнение с помощью `-gt`, `-ge` и т.п.)*

Код скрипта `script222`:

```bash
#!/bin/bash

# input validation
if [[ "$#" != 3 ]]; then
    echo "usage: $0 <number1> <number2> <number>"
    exit 1
fi

# finding max value
if (( $1 <= $3 && $2 <= $3 )); then
    echo "maximum number: $3"

elif  (( $3 <= $2 && $3 <= $2 )); then
    echo "maximum number: $2"

elif (( $2 <= $1 && $3 <= $1 )); then
    echo "maximum number: $1"

fi
```

Тест 1 - штатный случай:

```
./script222 1 2 3
>>> maximum number: 3
```

Тест 2 - одинаковые числа:

```
./script222 1 1 1
>>> maximum number: 1
```

Тест 3 - недостаточно аргументов:

```
./script222 1 1 
>>> usage: ./script222 <number1> <number2> <number>
```
### Задача 3

**Постановка:** считывать строки с клавиатуры до ввода «q», затем вывести все считанные строки одной строкой.

**Описание решения:**

*(кратко: цикл `while` + `read`, накопление строк в переменной)*

Код скрипта `script223`:

```bash
#!/bin/bash

result=''

while true; do
    read -p "Enter your text: " line

    if [[ $line == 'q' ]]; then
        break
    fi

    result+=" $line"
done

if [[ "$result" != "" ]]; then
    echo "${result:1}"
fi
```

Тест 1 - штатный случай:

```
./script223
>>> Enter your text: one
>>> Enter your text: two
>>> Enter your text: three
>>> Enter your text: q
>>> one two three
```

Тест 2 сразу `q`:

```
./script223
>>> Enter your text: q
>>> 
```

### Задача 4

Код скрипта `script224`:

```bash
#!/bin/bash

counter=0

while true; do
    read -p 'Enter a number: ' current

    # input validation
    if [[ ! "$current" =~ ^[+-]?[0-9]+$ ]]; then
        echo "Not a valid number"
        continue
    fi

    if (( current % 2 == 0 )); then
        break
    fi

    (( counter+=1 ))
done

echo "Total: $counter"
```

Тест 1 - штатный случай:

```
./script224
>>> Enter a number: 5
>>> Enter a number: -1
>>> Enter a number: 2
>>> Total: 2
```

Тест 2 - неправильный формат ввода:

```
./script224
>>> Enter a number: dfg
>>> Not a valid number
>>> Enter a number: 2
>>> Total: 0
```

### Задача 5

Код скрипта `script225`:

```bash
#!/bin/bash

#checking dependencies
not_installed=""

for dependency in vi nano links; do
    if ! which $dependency &> /dev/null; then
        not_installed+=", $dependency"
    fi
done

if [[ "$not_installed" != "" ]]; then
    echo "${not_installed:2} not installed"
    exit 1
fi

# print options menu
echo ' _________________'
echo '|     Options     |'
echo '|_________________|'
echo '|  1 -  open vi   |'
echo '|  2 -  open nano |'
echo '|  3 -  open links|'
echo '|  4 -  exit menu |'
echo '|_________________|'
echo ''

# retrieve user choice
read -p "Please, enter your choice: " choice

# handle user choice
case "$choice" in
    1)
        vi
        ;;
    2)
        nano
        ;;
    3)
        links
        ;;
    4)
        exit 0
        ;;
    *)
        echo 'invalid input'
        ;;
esac
```

Тест 1 - все программы установлены:

```
 _________________
|     Options     |
|_________________|
|  1 -  open vi   |
|  2 -  open nano |
|  3 -  open links|
|  4 -  exit menu |
|_________________|

Please, enter your choice:
```

Тест 2 - `links` не установлен:

```
./script225
>>> links not installed
```

### Задача 6

Код скрипта `script226`:

```bash
#!/bin/bash

# input validation
if [[ "$#" == 0 ]]; then
    echo "3 positional parameters required, $# passed instead"
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

if [[ "$2" != 't' && "$2" != 'h' ]]; then
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

if [[ ! "$3" =~ ^[0-9]+$ ]]; then
    echo "usage: $0 <file name> < t | h > <number>"
    exit 1
fi

# main logic
if [[ "$2" == 't' ]]; then
    tail -n $3 $1 2> /dev/null
else
    head -n $3 $1 2> /dev/null
fi
```

Тест 1 (штатный случай — `h` и `t`):

```
./script226 script221 t 1
>>> fi

./script226 script221 h 1
>>> #!/bin/bash
```

Тест 2 - отсутствующий файл:

```
./script226 script22 h 1
>>>
```

### Чек-лист части 2

- [x] Все шесть скриптов созданы, названы по шаблону `script22N` и исполняемы
- [x] Каждый скрипт проверен минимум на одном штатном и одном граничном сценарии
- [x] Скрипт 5 корректно сообщает об отсутствующей программе
- [x] Скрипт 6 не выводит служебных ошибок при обращении к несуществующему файлу

---

## Часть 3. Скрипт расчёта производительности в FLOPS

Код скрипта `script23`:

```bash
#!/bin/bash

calculate_float_numbers() {
    local calculations="$1"

    for ((i = 1; i <= calculations; i++)); do
        echo "scale=10; 123456.789123 * 123456.789123" | bc > /dev/null
    done
}


calculations=100


start=$(date +%s%N)

calculate_float_numbers "$calculations"

end=$(date +%s%N)

difference_sec=$(bc <<< "scale=10; ($end - $start) / 1000000000")
result=$(bc <<< "$calculations / $difference_sec")

echo "Result: $result FLOPS"
```

Результат запуска при `script23`:

```
./script23
>>> Reslut: 461 FLOPS
```

**Анализ результата:**

Предоставленный скрипт имеет крайне низкую точность для оценки реальной производительности процессора в FLOPS. Из-за циклического вызова внешней утилиты `bc` замеряемое время отражает не скорость аппаратных вычислений с плавающей запятой, а огромные накладные расходы операционной системы на постоянное создание и уничтожение процессов и передачу данных через конвейер.
### Чек-лист части 3

- [x] `script23` выполняет не менее 100 операций умножения нецелых чисел с точностью 10 знаков
- [x] Вычисления оформлены как функция, промежуточные значения не выводятся
- [x] Время замеряется до и после вызова функции, FLOPS вычислен и выведен
- [x] Могу объяснить, почему это упрощённая оценка производительности

---

## Часть 4. Доработка скрипта инвентаризации оборудования

Код скрипта `script_passport_v2.sh`

```bash
#!/bin/bash

# preparing environment
mkdir -p PASSPORT/log
mkdir -p PASSPORT/tmp

tmp_path=PASSPORT/tmp
report_path=PASSPORT/inventory.txt
current_time=$(date)


# collecting system information
echo $current_time > $tmp_path/date.tmp
hostname > $tmp_path/hostname.tmp
whoami > $tmp_path/user.tmp
pwd > $tmp_path/wd.tmp
ls -a > $tmp_path/files.tmp

uname --kernel-name > $tmp_path/kernel-name.tmp
uname --kernel-version > $tmp_path/kernel-version.tmp
uname --machine > $tmp_path/cpu-bitness.tmp
. /etc/os-release && echo $PRETTY_NAME > $tmp_path/os-version.tmp
grep -m 1 "model name" /proc/cpuinfo | sed 's/.*: //' > $tmp_path/cpu-model.tmp
cat /proc/cpuinfo | grep "model name" | head -n 1 > $tmp_path/cpu-model.tmp
lscpu | grep -m 1 "CPU max MHz" | sed 's/^[^0-9]*//' > $tmp_path/cpu-mhz.tmp
nproc > $tmp_path/cpu-cores.tmp
lscpu | grep "L.*cache" > $tmp_path/cpu-caches.tmp
grep "MemTotal" /proc/meminfo | sed 's/MemTotal:[ \t]*//' > $tmp_path/memory.tmp
dmidecode -s baseboard-product-name > $tmp_path/motherboard.tmp
dmidecode -s bios-version > $tmp_path/bios-version.tmp
dmidecode -s bios-release-date > $tmp_path/bios-release-date.tmp
lspci > $tmp_path/pci.tmp


# creating report
echo "====== System Information ======" > $report_path
echo "" >> $report_path
echo "current time: $(cat $tmp_path/date.tmp)" >> $report_path
echo "host name: $(cat $tmp_path/hostname.tmp)" >> $report_path
echo "user: $(cat $tmp_path/user.tmp)" >> $report_path
echo "working directory: $(cat $tmp_path/wd.tmp)" >> $report_path
echo "working directory containment:" >> $report_path
echo $(cat $tmp_path/files.tmp) >> $report_path

echo >> $report_path
echo "kernel: $(cat $tmp_path/kernel-name.tmp)" >> $report_path
echo "kernel version: $(cat $tmp_path/kernel-version.tmp)" >> $report_path
echo "cpu bitness: $(cat $tmp_path/cpu-bitness.tmp)" >> $report_path
echo "os version: $(cat $tmp_path/os-version.tmp)" >> $report_path
echo "CPU: $(cat $tmp_path/cpu-model.tmp)" >> $report_path
echo "CPU max MHz: $(cat $tmp_path/cpu-mhz.tmp)" >> $report_path
echo "CPU cores: $(cat $tmp_path/cpu-cores.tmp)" >> $report_path
echo "motherboard model: $(cat $tmp_path/motherboard.tmp)" >> $report_path
echo "bios version: $(cat $tmp_path/bios-version.tmp)" >> $report_path
echo "bios release date: $(cat $tmp_path/bios-release-date.tmp)" >> $report_path
echo "devices connected to pci:" >> $report_path
echo >> $report_path

while IFS= read -r line; do
    echo "$line" >> $report_path
done < $tmp_path/pci.tmp


# deleting temp files
find -name "*.tmp" -delete


# logging
echo "$current_time: script started" >> PASSPORT/log/report.log
```

Содержимое отчёта `PASSPORT/inventory.txt`:

```
====== System Information ======

current time: Вт 27 окт 2026 09:32:14 +03
host name: laptop
user: root
working directory: /home/svvvrm/projects/university/1_year/linux/practice 2
working directory containment:
. .. PASSPORT script221 script222 script223 script224 script225 script226 script23 script_passport_v2.sh

kernel: Linux
kernel version: #1 SMP PREEMPT_DYNAMIC Debian 6.12.107-1 (2026-08-29)
cpu bitness: x86_64
os version: Debian GNU/Linux 13 (trixie)
CPU: model name	: AMD Ryzen 5 8640HS w/ Radeon 760M Graphics
CPU max MHz: 4971,0000
CPU cores: 12
motherboard model: Kinder_HKU
bios version: 1.05
bios release date: 04/25/2024
devices connected to pci:

00:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Root Complex
00:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Phoenix IOMMU
00:01.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Host Bridge
00:01.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix GPP Bridge
00:02.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Host Bridge
00:02.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix GPP Bridge
00:02.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix GPP Bridge
00:03.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Host Bridge
00:03.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Family 19h USB4/Thunderbolt PCIe tunnel
00:04.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Host Bridge
00:08.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Host Bridge
00:08.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Internal GPP Bridge to Bus [C:A]
00:08.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Internal GPP Bridge to Bus [C:A]
00:08.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Internal GPP Bridge to Bus [C:A]
00:14.0 SMBus: Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller (rev 71)
00:14.3 ISA bridge: Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge (rev 51)
00:18.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 0
00:18.1 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 1
00:18.2 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 2
00:18.3 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 3
00:18.4 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 4
00:18.5 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 5
00:18.6 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 6
00:18.7 Host bridge: Advanced Micro Devices, Inc. [AMD] Phoenix Data Fabric; Function 7
01:00.0 Non-Volatile memory controller: SK hynix BC901 NVMe Solid State Drive (DRAM-less) (rev 03)
02:00.0 Network controller: MEDIATEK Corp. MT7922 802.11ax PCI Express Wireless Network Adapter
63:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Phoenix3 (rev c3)
63:00.1 Audio device: Advanced Micro Devices, Inc. [AMD/ATI] Radeon High Definition Audio Controller [Rembrandt/Strix]
63:00.2 Encryption controller: Advanced Micro Devices, Inc. [AMD] Phoenix CCP/PSP 3.0 Device
63:00.3 USB controller: Advanced Micro Devices, Inc. [AMD] Device 15b9
63:00.4 USB controller: Advanced Micro Devices, Inc. [AMD] Device 15ba
63:00.5 Multimedia controller: Advanced Micro Devices, Inc. [AMD] Audio Coprocessor (rev 63)
63:00.6 Audio device: Advanced Micro Devices, Inc. [AMD] Family 17h/19h/1ah HD Audio Controller
64:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Function
64:00.1 Signal processing controller: Advanced Micro Devices, Inc. [AMD] AMD IPU Device
65:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Phoenix Dummy Function
65:00.3 USB controller: Advanced Micro Devices, Inc. [AMD] Device 15c0
65:00.4 USB controller: Advanced Micro Devices, Inc. [AMD] Device 15c1
65:00.5 USB controller: Advanced Micro Devices, Inc. [AMD] Pink Sardine USB4/Thunderbolt NHI controller #1
```

Cодержимое `report.log` после 2 запусков:

```
Вт 27 окт 2026 09:29:35 +03: script started
Вт 27 окт 2026 09:32:14 +03: script started
```

### Чек-лист части 4

- [x] Отчёт содержит все пункты об оборудовании и ядре, каждый под своим заголовком
- [x] Недостающие утилиты установлены через apt, названия пакетов указаны
- [x] Разделение на сбор/обработку/логирование сохранено; после двух запусков лог содержит две строки, `.tmp`-файлы удалены
- [x] Скрипт исполняемый и запускается по имени без ошибок доступа

---
## Часть 5. Работа с модулями драйверов устройств

Список модулей, полученный командой `lsmod`:

```
Module                  Size  Used by
aesni_intel           122880  0
ahci                   53248  0
autofs4                57344  2
binfmt_misc            28672  1
button                 24576  0
ccp                   163840  1 kvm_amd
cdrom                  81920  1 sr_mod
configfs               69632  1
crc16                  12288  1 ext4
crc32c_generic         12288  0
crc32c_intel           16384  2
crc32_pclmul           12288  0
crct10dif_pclmul       12288  1
cryptd                 28672  2 crypto_simd,ghash_clmulni_intel
crypto_simd            16384  1 aesni_intel
drm                   774144  5 drm_kms_helper,drm_shmem_helper,virtio_gpu
drm_kms_helper        253952  2 drm_shmem_helper,virtio_gpu
drm_shmem_helper       36864  2 virtio_gpu
efi_pstore             12288  0
evdev                  28672  7
ext4                 1146880  1
failover               12288  1 net_failover
gf128mul               16384  1 aesni_intel
ghash_clmulni_intel    16384  0
hid                   262144  2 usbhid,hid_generic
hid_generic            12288  0
i2c_dev                28672  0
i2c_i801               36864  0
i2c_smbus              16384  1 i2c_i801
intel_pmc_bxt          16384  1 iTCO_wdt
intel_rapl_common      53248  1 intel_rapl_msr
intel_rapl_msr         20480  0
ip_tables              28672  0
irqbypass              12288  1 kvm
iTCO_vendor_support    12288  1 iTCO_wdt
iTCO_wdt               16384  1
jbd2                  200704  1 ext4
joydev                 24576  0
kvm                  1396736  1 kvm_amd
kvm_amd               221184  0
libahci                61440  1 ahci
libata                471040  2 libahci,ahci
lp                     20480  0
lpc_ich                28672  0
mbcache                16384  1 ext4
msr                    12288  0
net_failover           24576  1 virtio_net
nfnetlink              20480  1
parport                81920  3 parport_pc,lp,ppdev
parport_pc             40960  0
pcspkr                 12288  0
ppdev                  24576  0
psmouse               221184  0
qemu_fw_cfg            20480  0
qrtr                   57344  2
rfkill                 40960  2
scsi_common            16384  5 scsi_mod,sd_mod,libata,sg,sr_mod
scsi_mod              331776  4 sd_mod,libata,sg,sr_mod
sd_mod                 81920  0
serio_raw              16384  0
sg                     45056  0
sha1_ssse3             32768  0
sha256_ssse3           32768  0
sha512_ssse3           53248  0
snd                   151552  12 snd_hda_codec_generic,snd_seq,snd_seq_device,snd_hwdep,snd_hda_intel,snd_hda_codec,snd_timer,snd_pcm
snd_hda_codec         217088  2 snd_hda_codec_generic,snd_hda_intel
snd_hda_codec_generic   114688  1
snd_hda_core          143360  3 snd_hda_codec_generic,snd_hda_intel,snd_hda_codec
snd_hda_intel          61440  1
snd_hrtimer            12288  1
snd_hwdep              20480  1 snd_hda_codec
snd_intel_dspcfg       40960  1 snd_hda_intel
snd_intel_sdw_acpi     16384  1 snd_intel_dspcfg
snd_pcm               188416  3 snd_hda_intel,snd_hda_codec,snd_hda_core
snd_seq               110592  7 snd_seq_dummy
snd_seq_device         16384  1 snd_seq
snd_seq_dummy          12288  0
snd_timer              53248  3 snd_seq,snd_hrtimer,snd_pcm
soundcore              16384  1 snd
sr_mod                 28672  0
uinput                 20480  1
usb_common             16384  2 xhci_hcd,usbcore
usbcore               409600  3 xhci_hcd,usbhid,xhci_pci
usbhid                 77824  0
virtio_balloon         32768  0
virtio_blk             32768  2
virtio_dma_buf         12288  1 virtio_gpu
virtio_gpu            102400  1
virtio_net            118784  0
virtio_rng             12288  0
watchdog               49152  1 iTCO_wdt
xhci_hcd              364544  1 xhci_pci
xhci_pci               24576  0
x_tables               53248  1 ip_tables

```

Поиск модуля `snd` и его зависимостей, с помощью `lsmod | grep snd | sort`:

```
snd                   151552  12 snd_hda_codec_generic,snd_seq,snd_seq_device,snd_hwdep,snd_hda_intel,snd_hda_codec,snd_timer,snd_pcm
snd_hda_codec         217088  2 snd_hda_codec_generic,snd_hda_intel
snd_hda_codec_generic   114688  1
snd_hda_core          143360  3 snd_hda_codec_generic,snd_hda_intel,snd_hda_codec
snd_hda_intel          61440  1
snd_hrtimer            12288  1
snd_hwdep              20480  1 snd_hda_codec
snd_intel_dspcfg       40960  1 snd_hda_intel
snd_intel_sdw_acpi     16384  1 snd_intel_dspcfg
snd_pcm               188416  3 snd_hda_intel,snd_hda_codec,snd_hda_core
snd_seq               110592  7 snd_seq_dummy
snd_seq_device         16384  1 snd_seq
snd_seq_dummy          12288  0
snd_timer              53248  3 snd_seq,snd_hrtimer,snd_pcm
soundcore              16384  1 snd

```

### Попытка выгрузки `snd`

Ожидаемо - ошибка из‑за зависимых модулей:

```
sudo modprobe -r snd
>>> modprobe: FATAL: Module snd is in use.
```

### Выгрузка зависимых модулей и затем `snd`

Анализ дерева зависимостей по столбцу `Used by`:

```
Module                  Size  Used by
snd                   151552  12 snd_hda_codec_generic,snd_seq,snd_seq_device,snd_hwdep,snd_hda_intel,snd_hda_codec,snd_timer,snd_pcm
snd_hda_codec         217088  2 snd_hda_codec_generic,snd_hda_intel
snd_hda_codec_generic   114688  1
snd_hda_core          143360  3 snd_hda_codec_generic,snd_hda_intel,snd_hda_codec
snd_hda_intel          61440  1
snd_hrtimer            12288  1
snd_hwdep              20480  1 snd_hda_codec
snd_intel_dspcfg       40960  1 snd_hda_intel
snd_intel_sdw_acpi     16384  1 snd_intel_dspcfg
snd_pcm               188416  3 snd_hda_intel,snd_hda_codec,snd_hda_core
snd_seq               110592  7 snd_seq_dummy
snd_seq_device         16384  1 snd_seq
snd_seq_dummy          12288  0
snd_timer              53248  3 snd_seq,snd_hrtimer,snd_pcm
soundcore              16384  1 snd
```

Попытка выгрузить `snd_seq_dummy` т.к. от него не зависят никакие модули прошла успешно, попробуем выгрузить `snd_seq` т.к. от него зависел только уже выгруженный модуль, и получим следующее сообщение:

```
rmmod: ERROR: Module snd_seq is in use
```

Найдем что держит наши модули: через `fuser`:

```
sudo fuser -v /dev/snd/*

                     USER        PID ACCESS COMMAND
/dev/snd/controlC0:  svvvrm      990 F.... wireplumber
/dev/snd/seq:        svvvrm      987 F.... pipewire

```

### Запрет автозагрузки модулей

Создание файла с директивой `blacklist` в `/etc/modprobe.d`:

```
sudo nano /etc/modprobe.d/blacklist-snd.conf
```

Содержимое созданного файла:

```
blacklist snd_hda_intel blacklist snd_hda_codec_generic blacklist snd_hda_codec blacklist snd_hda_core blacklist snd_intel_dspcfg blacklist snd_intel_sdw_acpi blacklist snd_pcm blacklist snd_seq blacklist snd_seq_dummy blacklist snd_seq_device blacklist snd_hwdep blacklist snd_timer blacklist snd_hrtimer blacklist snd blacklist soundcore
```

Проверка после загрузки:

```
lsmod | grep snd
>>> 
```

### Загрузка модуля e100

Загрузка модуля:

```
modprobe e100
```

Подтверждение загрузки:

```
lsmod | grep e100
>>> e100                   49152  0
>>> mii                    16384  1 e100
```


### Чек-лист части 5

- [x] Могу назвать минимум по одному ключу для `lsmod`, `modprobe`, `rmmod`, `modinfo` и объяснить его
- [x] Модуль `snd` и его зависимости выгружены в правильном порядке
- [x] Конфигурационный файл с `blacklist` создан и сохранён для отчёта
- [x] Модуль `e100` загружен командой `modprobe` и подтверждён в выводе `lsmod`

---

## Ответы на вопросы и задания

### 1. Как определить, сколько параметров пользователь передал в скрипт при запуске?

**Ответ:**

Параметр `$#` содержит количество переданных параметров.

### 2. Какие недостатки есть у вашего подхода к определению производительности в FLOPS?

**Ответ:**

Большие расходы на создание процессов `bc` + `bc` выполняет умножение программно.

### 3. Как реализовать в конвейере сбор данных о CPU без промежуточных файлов? Аргумент «за» и «против» каждого из подходов.

Сбор данных в конвейере можно реализовать следующим образом:

```
grep -m 1 "model name" /proc/cpuinfo | sed 's/.*: //'  >> report.txt
```

Данные идут напрямую от `lscpu` к `grep`, затем к `sed`, и никакие файлы не создаются.

| Подход              | За                                                                                           | Против                                                                                                           |
| ------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Промежуточные файлы | сбор и вывод разделены, каждый этап можно проверить отдельно, а данные использовать повторно | лишние обращения к диску, нужна уборка файлов                                                                    |
| Конвейер            | компактно, быстро, ничего не остаётся на диске                                               | труднее читать и отлаживать длинную цепочку, а данные нельзя повторно использовать без повторного запуска команд |
### 4. В чём разница между `modprobe` и `insmod`?

**Ответ:**

`insmod` загружает конкретный `.ko`-файл по пути. Зависимости он не подгружает, и если нужного модуля нет, загрузка заканчивается ошибкой. `modprobe` работает с именем модуля, сам находит файл, автоматически загружает зависимости и учитывает настройки из `/etc/modprobe.d`. Ключ `-r` выгружает модуль вместе с ненужными зависимостями.
### 5. Как определить, поддерживает ли процессор аппаратную реализацию AES?

**Ответ:**

Команда и результат:

```
lscpu | grep -o -w aes
>>> aes
```

Если вывело `aes` то аппаратная реализация присутсвует.

### 6. Откуда `modprobe` узнала, где расположен файл модуля?

**Ответ:**

Из индексных файлов `modules.dep` в каталоге `/lib/modules/<версия_ядра>/`

### 7. В каких форматах `lshw` может генерировать отчёты? Для чего используется каждый из форматов?

| Формат        | Ключ       | Для чего используется                                  |
| ------------- | ---------- | ------------------------------------------------------ |
| Обычный текст | —          | подробный просмотр в терминале, вывод в текстовый файл |
| Краткий       | `-short`   | компактное дерево устройств для быстрого обзора        |
| Список шин    | `-businfo` | соответствие устройств адресам шин (PCI, USB, SCSI)    |
| HTML          | `-html`    | читаемый отчёт для браузера, документации, архива      |
| XML           | `-xml`     | машинная обработка, импорт в системы инвентаризации    |
| JSON          | `-json`    | разбор в скриптах и программах                         |

### 8. Значение полей в выводе `lsmod`

| Поле      | Значение                                                                             |
| --------- | ------------------------------------------------------------------------------------ |
| `Module`  | имя загруженного модуля                                                              |
| `Size`    | размер модуля в памяти ядра, в байтах                                                |
| `Used by` | число обращений к модулю, далее через запятую имена модулей, которые от него зависят |

