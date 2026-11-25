**МИНИСТЕРСТВО НАУКИ И ВЫСШЕГО ОБРАЗОВАНИЯ РОССИЙСКОЙ ФЕДЕРАЦИИ**  

_ФЕДЕРАЛЬНОЕ ГОСУДАРСТВЕННОЕ АВТОНОМНОЕ ОБРАЗОВАТЕЛЬНОЕ УЧРЕЖДЕНИЕ ВЫСШЕГО ОБРАЗОВАНИЯ_  

_НАЦИОНАЛЬНЫЙ ИССЛЕДОВАТЕЛЬСКИЙ УНИВЕРСИТЕТ ИТМО_
_Факультет прикладной информатики 

**ОТЧЕТ по практической работе №3

**по дисциплине «Введение в ОС Linux»**

**Тема: «Подсистема безопасности Linux: пользователи, права, SSH, процессы»**

**Выполнил:**   
Кетов Александр Антонович
Поток TIP 1.1

**Проверил:**
Береснев  Артем Дмитриевич

**Санкт-Петербург - 2026**

---

## Цель работы

Освоить базовые механизмы безопасности Linux: учётные записи и группы, права на файлы и каталоги, удалённый доступ по SSH (по паролю и по ключам), повышение привилегий через su и sudo; научиться наблюдать за процессами (PID, PPID, htop) и запускать их в фоне. Развить навыки bash, доработав скрипт инвентаризации.

---

## Ход работы

### Часть 1. Стенд и подключение по паролю

#### 1.1. Проверка наличия и состояния службы SSH

Проверим запущен ли SSH сервер:

```bash
systemctl status ssh
```

Вывод: 

```
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-11-13 00:52:18 +03; 4 days ago
 Invocation: b7021df0595547d2adb79f45f919b8e2
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 2952 (sshd)
      Tasks: 1 (limit: 2297)
     Memory: 3.4M (peak: 7.3M)
        CPU: 612ms
     CGroup: /system.slice/ssh.service
             └─2952 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"
```

Значит SSH сервер запущен.

Проверим на какой порт он слушает:

```bash
ss -tlpn
```

Находим в выводе следующие строки:

```
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess                                
LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=2952,fd=6))      
LISTEN 0      128             [::]:22           [::]:*    users:(("sshd",pid=2952,fd=7))
```

Таким образом SSH сервер запущен и слушает 22 порт.
#### 1.2. Создание учётной записи студента

```bash
adduser kaa-1
```

#### 1.3. Проброс порта в VirtualBox

Адрес хоста - 127.0.0.1, адрес гостя не назначен, порт хоста - 2222, порт гостя - 22.

#### 1.4. Изменение параметров sshd

При помощи редактора nano открываем файл `/etc/ssh/sshd_config` и добавляем в нем следующие строчки:

```
LoginGraceTime 30  
PermitRootLogin yes                
MaxAuthTries 2
```

Проверим результат командой `sshd -T`:

```
......
logingracetime 30
......
maxauthtries 2
......
permitrootlogin yes
......
```

#### 1.5. Проверка синтаксиса и перезапуск службы

В прошлом пункте вызов `sshd -T` завершился успешно, значит с синтаксисом конфигурационного файла все в порядке.

Пробуем подключиться к нашей ВМ под root:

```
ssh -p 2222 root@127.0.0.1  
>>> root@127.0.0.1's password:    
>>> Permission denied, please try again.
```

Это значит, что все еще действует старая политика `PermitRootLogin prohibit-password`. Перезапустим SSH сервер, чтобы новая конфигурация применилась:

```text
systemctl restart ssh
```

Состояние службы и прослушиваемый порт:

```text
systemctl status ssh
>>> ● ssh.service - OpenBSD Secure Shell server  
>>>    Loaded: loaded (/usr/lib/systemd/system/ssh.service; enabled; preset: enabled)  
>>>    Active: active (running) since Tue 2026-11-17 23:33:34 +03; 53s ago
```

```
ss -tlpn
>>> LISTEN 0      128          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=15098,fd=6))
```

Служба запущена и слушает нужный порт.

#### 1.6. Подключение с основного компьютера

Подключение под root:

```
ssh -p 2222 root@127.0.0.1
```

Подключение под учётной записью студента:

```
ssh -p 2222 kaa-1@127.0.0.1
```

После  первого подключения отпечаток ключа сервера был автоматически сохранен в `~/.ssh/known_hosts`.
#### 1.7. Анализ активных подключений на ВМ

Терминалы подключённых пользователей:

```text
root     sshd pts/2   2026-11-17 23:51 (10.0.2.2)  
kaa-1    sshd pts/1   2026-11-17 23:49 (10.0.2.2)
```

У `root` пользователя терминал `pts/2`, у `kaa-1` - `pts/1` (псевдотерминалы).

Адреса и порты обеих ssh-сессий:

```text
State          Recv-Q     Send-Q         Local Address:Port          Peer Address:Port     Process                                                                                    
ESTAB          0          36                 10.0.2.15:22                10.0.2.2:50650     users:(("sshd-session",pid=15653,fd=7),("sshd-session",pid=15643,fd=7))                   
    
ESTAB          0          0                  10.0.2.15:22                10.0.2.2:36960     users:(("sshd-session",pid=15546,fd=7),("sshd-session",pid=15508,fd=7))   
```

Ssh-сессии идут с одного адреса `10.0.2.2` с портов `36960` и `50650` на адрес `10.0.2.15` порт `22`. 
#### 1.8. Копирование файлов через scp

Хост => ВМ:

```text
scp -P 2222 file.txt kaa-1@127.0.0.1:~
```

Хост <= ВМ:

```text
scp -P 2222 kaa-1@127.0.0.1:~/app.log .
```

**Чек-лист части 1:**

- [x] Служба ssh работает, слушает порт 22, показано двумя способами
- [x] В выводе проверки конфигурации: PermitRootLogin yes, MaxAuthTries 2, LoginGraceTime 30
- [x] Два одновременных подключения видны в выводах who и ss
- [x] Копирование scp работает в обе стороны

---

### Часть 2. Пользователи и группы

#### 2.1. Скрипт script31

Код скрипта:

```bash
#!/usr/bin/env bash

if [[ $# != 2 ]]; then 
    echo "two arguments required"
    exit 1
fi

if [[ $(id --user) != 0 ]]; then
    echo "root privileges required"
    exit 1
fi


start=$2
final=$(( $start + $1 ))


for (( i = $start; i < $final; i++ )); do
    new_user="u${i}"
    password="DerParol${i}"

    # execute if new_user doesn't exist
    if ! id "$new_user" &> /dev/null; then
        useradd -m -s /bin/bash "$new_user"
        echo "${new_user}:${password}" | chpasswd
    fi
done
```

#### 2.2. Запуск скрипта (создание u1–u5)

Команда запуска и вывод:

```text
./script31.sh 5 1
```

Проверка числа параметров:

```text
./script31.sh 5
>> two arguments required
```

Проверка прав (запуск под `kaa-1`):

```
./script31.sh 5 1
>> root privileges required
```

Повторный запуск не привел к повторному созданию пользователей или изменению паролей уже существующих пользователей.

#### 2.3. Группа project

Команды создания группы и добавления u1, u2 c проверкой членства:

```bash
addgroup project
usermod -aG project u1
id u1
>>> uid=1003(u1) gid=1003(u1) группы=1003(u1),1005(project)
usermod -aG project u2
id u2
>>> uid=1004(u2) gid=1004(u2) группы=1004(u2),1005(project)
```

#### 2.4. UID, GID и группы пользователей u1 и u2

Команда и вывод:

```text
id u1 u2
>>> uid=1003(u1) gid=1003(u1) группы=1003(u1),1005(project)
>>> uid=1004(u2) gid=1004(u2) группы=1004(u2),1005(project)
```

#### 2.5. Записи в passwd, group, shadow

Ищем группу `project`:

```bash
getent group | grep project
>>> project:x:1005:u1,u2
```

Ищем новых пользователей:

```bash
getent passwd | grep -E "^u[1-5]:"
>>> u1:x:1003:1003::/home/u1:/bin/sh
>>> u2:x:1004:1004::/home/u2:/bin/sh
>>> u3:x:1005:1006::/home/u3:/bin/sh
>>> u4:x:1006:1007::/home/u4:/bin/sh
>>> u5:x:1007:1008::/home/u5:/bin/sh
```

Назначение полей записи в /etc/passwd:

| Поле | Назначение                | Значение для u1 | Значение для u2 |
| ---- | ------------------------- | --------------- | --------------- |
| 1    | Читаемое имя              | u1              | u2              |
| 2    | Вид пароля                | x               | x               |
| 3    | UID                       | 1003            | 1004            |
| 4    | GID главной групппы       | 1003            | 1004            |
| 5    | Дополнительная информация | отсутствует     | отсутствует     |
| 6    | Домашний каталог          | /home/u1        | /home/u2        |
| 7    | Оболочка входа            | /bin/sh         | /bin/sh         |

Сравнение полей хешей u1 и u2 в /etc/shadow (без публикации полных хешей, при необходимости скрыть часть):

```bash
cat /etc/shadow | grep '^u[1-2]:'
>>> u1:$y$j9T$YN5LslyI1AzCAxBgcmeHD.$PlX9OdSGnZzysYrn1FCqNvTaO87Yj7EY64Cq3niHwYC:20775:0:99999:  
7:::  
>>> u2:$y$j9T$8U.ka4atBBGrLAZ3TR01m.$ZzdmNFSoiK7Tlf66LSHCW638dP6jH/Ypm5jY9cRfgp1:20775:0:99999:  
7:::
```

- Хэш пароля `u1`: `PlX9OdSGnZzysYrn1FCqNvTaO87Yj7EY64Cq3niHwYC`
- Соль `u1`: `YN5LslyI1AzCAxBgcmeHD.`
- Хэш пароля `u2`: `ZzdmNFSoiK7Tlf66LSHCW638dP6jH/Ypm5jY9cRfgp1`
- Соль `u2`: `8U.ka4atBBGrLAZ3TR01m.`
#### 2.6. Обновление членства в группе в открытой сессии

Ход эксперимента (вход u3, вход u1, добавление u3 в project, проверка в старой сессии, повторный вход):

| Шаг | Действие                             | Команда                              | Вывод / результат                                                                  |
| --- | ------------------------------------ | ------------------------------------ | ---------------------------------------------------------------------------------- |
| 1   | Вход под u3 на терминале ВМ          | `ssh -p 2222 u3@127.0.0.1` `su - u3` | Вход выполнен                                                                      |
| 2   | Вход под u1, проверка группы project | `su - u1` и `id`                     | Вход выполнен, пользователь находится в группе                                     |
| 3   | Добавление u3 в project              | `usermod -aG project u3` и `id u3`   | `u3` добавлен в `project`, uid=1005(u3) gid=1006(u3) группы=1006(u3),1005(project) |
| 4   | Проверка в уже открытой сессии u3    | `id`                                 | `uid=1005(u3) gid=1006(u3) группы=1006(u3)` т.е. не добавлен в группу `project`    |
| 5   | Повторный вход под u3 и проверка     | `su - u3` и `id`                     | uid=1005(u3) gid=1006(u3) группы=1006(u3),1005(project), т.е. добавлен в группу    |
Так произошло, потому что группы пользователя считываются из файла `/etc/group` только в момент авторизации, а так как u3 был авторизован до добавления в группу, то показывался старый список групп.

**Чек-лист части 2:**

- [x] script31 исполняемый, проверяет параметры и права, не падает при повторном запуске
- [x] Созданы u1–u5 и группа project, членство проверено
- [x] Могу объяснить, почему членство в группе в открытой сессии не обновляется

---

### Часть 3. Права на файлы и каталоги

#### 3.1. Каталог /DATA

Команды настройки:

```text
mkdir -p /DATA
chgrp project /DATA
chmod 775 /DATA
```

Проверка под  u1 (в группе):

```bash
su - u1
ls /DATA    # успешно
cd /DATA    # успешно
touch /DATA/file1 /DATA/file2  # успешно
echo "hello" > /DATA/file1   # успешно
cat /DATA/file1   # успешно
rm /DATA/file1   # успешно
```

Проверка под u4 (вне группы):

```bash
su - u4
ls /DATA      # успешно
>>> file1  file2
cd /DATA      # успешно
cat /DATA/file1    # успешно
touch /DATA/file3
>>> touch: невозможно выполнить touch для '/DATA/file3': Отказано в доступе
echo "hello" > /DATA/file1
>>> bash: /DATA/file1: Отказано в доступе
rm /DATA/file1
>>> rm: невозможно удалить '/DATA/file1': Отказано в доступе
```

#### 3.2. Каталог /DATA/sec1

Создаем `sec1`:

```text
mkdir -p /DATA/sec1
chmod 1777 /DATA/sec1
```

Устроим проверку под `u1` (`file2` принадлежит `u3`):

```bash
touch /DATA/sec1/file1     # успешно
echo "hello" > /DATA/sec1/file1    # успешно
rm /DATA/sec1/file1     # успешно
rm /DATA/sec1/file2
>>> rm: невозможно удалить '/DATA/sec1/file2': Операция не позволена
mv /DATA/sec1/file2 /DATA/sec1/new_file2   
>>> mv: невозможно переместить '/DATA/sec1/file2' в '/DATA/sec1/new_file2': Операция не позволена
```

#### 3.3. Каталог /DATA/sec2

```text
mkdir -p /DATA/sec2
chown u1 /DATA/sec2
chmod 750 /DATA/sec2
addgroup sec2
usermod -aG sec2 u4
usermod -aG sec2 u5
chgrp sec2 /DATA/sec2
```

Для начала создаем каталог `sec2` и назначаем `u1` владельцем. Далее меняем права доступа так, чтобы владелец имел права на все, группа только права на чтение и выполнение, а остальным не давать никаких разрешений. Создаем группу `sec2` и добавляем в нее `u4` и `u5`, чтобы дать двум выбранным пользователям специальные права, после чего меняем группу каталога `sec2` на `sec2`.
#### 3.4. Каталог /DATA/sec3 и копия nano

Команды настройки:

```text
mkdir -p /DATA/sec3
cp $(which nano) /DATA/sec3/nano
chown u1 /DATA/sec3/nano
chmod 4555 /DATA/sec3/nano
```

Проверка под u3:

```text
/DATA/sec3/nano /DATA/sec2/file1
```

Открываем `/DATA/sec2/file1` в нашем `nano` и пишем изменения, после снова открываем файл с помощью `nano` и видим, что изменения сохранились.
#### 3.5. Анализ риска и поиск suid-файлов

Если владельцем suid-nano будет root, то любой пользователь сможет менять любые файлы в системе. Например, в /etc/passwd убрать "x" во второй колоне, и тем самым отключить авторизацию по паролю для root.

Список файлов с suid и запись о passwd:

```text
find /usr/bin -perm -4000
>>> /usr/bin/chfn  
>>> /usr/bin/sudo  
>>> /usr/bin/gpasswd  
>>> /usr/bin/newgrp  
>>> /usr/bin/pkexec  
>>> /usr/bin/mount  
>>> /usr/bin/su  
>>> /usr/bin/umount  
>>> /usr/bin/passwd  
>>> /usr/bin/fusermount3  
>>> /usr/bin/chsh  
>>> /usr/bin/ntfs-3g
```

Среди suid программ из данного вывода нетрудно заметить passwd.
#### 3.6. Итоговые права и владельцы

Вывод прав всех созданных каталогов и файлов:

```text
ls -ld /DATA
>>> drwxrwxr-x 5 root project 4096 ноя 19 23:34 /DATA

ls -l /DATA
>>> -rw-rw-r-- 1 u1   u1      0 ноя 19 19:37 file1  
>>> -rw-rw-r-- 1 u1   u1      0 ноя 19 19:37 file2  
>>> drwxrwxrwt 2 root root 4096 ноя 19 23:01 sec1  
>>> drwxr-x--- 2 u1   sec2 4096 ноя 19 23:39 sec2  
>>> drwxrwxr-x 2 root root 4096 ноя 19 23:34 sec3

ls -l /DATA/sec1
>>> -rw-rw-r-- 1 u3 root 0 ноя 19 22:36 file2

ls -l /DATA/sec2
>>> -rw-rw-r-- 1 u1 root 5 ноя 19 23:45 file1

ls -l /DATA/sec3
>>> -r-sr-xr-x 1 u1 root 303960 ноя 19 23:34 nano
```

**Чек-лист части 3:**

- [x] Проверки выполнены и для разрешённых, и для запрещённых действий
- [x] Могу объяснить права каждого каталога в восьмеричной и символьной записи
- [x] nano из /DATA/sec3 изменяет файлы в sec2 под произвольным пользователем
- [x] Могу объяснить опасность suid-файла, принадлежащего root

---

### Часть 4. Аутентификация по ключам SSH

#### 4.1. Создание пары ключей

Команда создания ключа:

```bash
ssh-keygen -t ed25519
```

Результат:

```
Generating public/private ed25519 key pair.  
Enter file in which to save the key (/home/svvvrm/.ssh/id_ed25519): /home/svvvrm/.ssh/test_  
vm_ed25519  
Enter passphrase for "/home/svvvrm/.ssh/test_vm_ed25519" (empty for no passphrase):    
Enter same passphrase again:    
Your identification has been saved in /home/svvvrm/.ssh/test_vm_ed25519  
Your public key has been saved in /home/svvvrm/.ssh/test_vm_ed25519.pub  
The key fingerprint is:  
SHA256:uP+pWTSscYZOsVd3NIlm4RcdNG5QoLkeqJAwOFeVp8g svvvrm@laptop  
The key's randomart image is:  
+--[ED25519 256]--+  
|     ....    +*B=|  
|  . .  . .  ++oo=|  
| o +. . +  o+..+.|  
|  o oE.o =....o. |  
|     o. S.Bo     |  
|      .+.B...    |  
|      ..o ..     |  
|       . o .     |  
|        +oo      |  
+----[SHA256]-----+
```

Найдем сгенерированные ключи:

```bash
ls -la .ssh | grep test_vm_ed25519
>>> -rw-------   1 svvvrm svvvrm  444 ноя 20 10:15 test_vm_ed25519 # приватный
>>> -rw-r--r--   1 svvvrm svvvrm   95 ноя 20 10:15 test_vm_ed25519.pub # открытый
```

#### 4.2. Передача открытого ключа на ВМ

Команды / способ передачи:

```bash
ssh-copy-id -p 2222 -i /home/svvvrm/.ssh/test_vm_ed25519.pub kaa-1@127.0.0.1
```

Проверка прав каталога ~/.ssh и файла authorized_keys:

```text
ls -ld /home/kaa-1/.ssh
>>> drwx------ 2 kaa-1 kaa-1 4096 ноя 20 10:23 /home/kaa-1/.ssh
ls -la /home/kaa-1/.ssh/authorized_keys
>>> -rw------- 1 kaa-1 kaa-1 95 ноя 20 10:23 /home/kaa-1/.ssh/authorized_keys
```

Как и ожидалось, у каталога ~/.ssh установлен режим 700, а у файла authorized_keys - режим 600. 

#### 4.3. Проверка входа по ключу

Команда для входа по ключу:

```bash
ssh -p 2222 -i /home/svvvrm/.ssh/test_vm_ed25519 kaa-1@127.0.0.1
```

Вход выполнен успешно:

```
Enter passphrase for key '/home/svvvrm/.ssh/test_vm_ed25519':    
Linux vbox 6.12.116+deb13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.116-1 (2026-11-07) x86_6  
4  
  
The programs included with the Debian GNU/Linux system are free software;  
the exact distribution terms for each program are described in the  
individual files in /usr/share/doc/*/copyright.  
  
Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent  
permitted by applicable law.  
Last login: Tue Nov 17 23:49:08 2026 from 10.0.2.2
```
#### 4.4. Изменение конфигурации sshd

Список изменённых параметров:

| Параметр               | Было | Стало                |
| ---------------------- | ---- | -------------------- |
| PermitRootLogin        | yes  | no                   |
| PubkeyAuthentication   | -    | yes                  |
| AuthorizedKeysFile     | -    | .ssh/authorized_keys |
| PasswordAuthentication | yes  | no                   |

Проверка конфигурации и перезапуск:

```text
sshd -T
>>> permitrootlogin no
>>> pubkeyauthentication yes
>>> authorizedkeysfile .ssh/authorized_keys
>>> passwordauthentication no
systemctl restart ssh
```

#### 4.5. Проверка ограничений

Вход под основным юзером через ключ:

```bash
ssh -p 2222 -i /home/svvvrm/.ssh/test_vm_ed25519 kaa-1@127.0.0.1    # успешно
```

Вход под рутом:

```bash
ssh -p 2222 root@127.0.0.1
>>> Received disconnect from 127.0.0.1 port 2222:2: Too many authentication failures    # Провал
```

Вход по паролю:

```bash
ssh -p 2222 -o PubkeyAuthentication=no kaa-1@127.0.0.1
>>> kaa-1@127.0.0.1: Permission denied (publickey). # провал
```
#### 4.6. Копирование script31 по scp с ключом

```bash
scp -P 2222 -i ~/.ssh/test_vm_ed25519 script31.sh kaa-1@127.0.0.1:~
```

**Чек-лист части 4:**

- [x] Вход по ключу работает, вход по паролю и вход root отклоняются
- [x] Права на ~/.ssh и authorized_keys проверены и объяснены
- [x] Команда scp с ключом сохранена
- [x] Список изменённых параметров sshd приведён

---

### Часть 5. su, sudo, процессы и фоновый запуск

#### 5.1. Наличие sudo

```bash
which sudo
>>> /usr/bin/sudo
```

#### 5.2. Группа sudo и сравнение su, su - и sudo

Добавление студента в группу sudo, проверка после нового входа:

```bash
usermod -aG sudo kaa-1
```

```bash
sudo -l
>>> Соответствие записей Defaults для kaa-1 на vbox:  
>>>    env_reset, mail_badpass,  
>>>   secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin, use_pty  
  
>>> Пользователь kaa-1 может выполнять следующие  
>>>       команды на vbox:  
>>>   (ALL : ALL) ALL

sudo id
>>> uid=0(root) gid=0(root) группы=0(root)
```

Сравнение окружения:

| Признак       | su                     | su -                    | sudo                    |
| ------------- | ---------------------- | ----------------------- | ----------------------- |
| Вывод pwd     | /home/kaa              | /root                   | /home/kaa-1             |
| Значение HOME | /root                  | /root                   | /root                   |
| вывод env     | HOME=/root, USER=kaa-1 | HOME=/root,  USER=root, | HOME=/root,  USER=root, |

PATH с `sudo`:

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

PATH с `su`:

```
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
```

PATH с `su -`:

```
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```
#### 5.3. Правило sudoers для u1

Содержимое файла /etc/sudoers.d/u1:

```text
u1 ALL=(root) /usr/bin/passwd [A-Za-z0-9._-]*, !/usr/bin/passwd root, !/usr/bin/passwd * root, !/usr/bin/passwd -*
```

Права:

```
chmod 0440 /etc/sudoers.d/u1
```
#### 5.4. Проверка ограничений и попытка обхода

| Проверка                                      | Команда                              | Ожидание  | Результат |
| --------------------------------------------- | ------------------------------------ | --------- | --------- |
| Смена пароля u2                               | `sudo passwd u2`                     | разрешено | разрешено |
| Смена пароля root                             | `sudo passwd` или `sudo passwd root` | запрещено | запрещено |
| Просмотр содержимого каталога root через sudo | `sudo ls /root`                      | запрещено | запрещено |
| Попытка обхода                                | `sudo passwd -d root`                | запрещено | запрещено |
#### 5.5. htop

Откроем htop и с помощью комбинации `shift + M` отсортируем процессы по памяти. Далее, клавишей `t` включим  древовидный режим. Нажмем `/` и введем `sshd`, чтобы найти нужный нам процесс. Он имеет PID 30347.
#### 5.6. Цепочка «родитель — потомок» до PID 1

Построенная цепочка:

| Уровень         | PID   | PPID  | Процесс                    |
| --------------- | ----- | ----- | -------------------------- |
| оболочка (bash) | 30386 | 30385 | bash                       |
| ssh session     | 30386 | 30347 | sshd-session: kaa-1@pts/1  |
| ssh session     | 30347 | 26971 | sshd-session: kaa-1 [priv] |
| ssh deamon      | 26971 | 1     | sshd                       |
| PID 1           | 1     | 0     | /sbin/init                 |

Полученная цепочка совпадает с выводом команды `pstree -sp 30386`:

```text
systemd(1)───sshd(26971)───sshd-session(30347)───sshd-session(30385)───bash(30386)───pstre+
```

#### 5.7. Сигналы SIGTERM и SIGKILL

Поиск процесса, его PID и PPID:

```bash
ps -eo pid,ppid,cmd | grep sleep
>>> 30632   30570 sleep 600
>>> 0662   30386 grep sleep
```

Таким образом PID равен 30632, а PPID - 30570.

Завершение сигналом SIGTERM:

```bash
kill 30632
```

Завершение сигналом SIGKILL:

```bash
kill -9 30706
```

Сигнал 15 `SIGTERM` - это мягкое завершение. Процесс получает запрос на остановку, может перехватить его, сохранить данные, закрыть соединения и освободить ресурсы. Используется по умолчанию командой `kill`.

Сигнал 9 `SIGKILL` - это принудительное мгновенное убийство процесса. Ядро ОС останавливает его сразу, без возможности перехвата, очистки или сохранения состояния.
#### 5.8. SIGSTOP и SIGCONT

Состояние (столбец STAT) до остановки, после остановки и после продолжения:

```bash
ps -eo pid,ppid,stat,cmd | grep sleep
>>> 30930   30570 S+   sleep 600

kill -SIGSTOP 30930
ps -eo pid,ppid,stat,cmd | grep sleep
>>>  30930   30570 T    sleep 600

kill -SIGCONT 30930
ps -eo pid,ppid,stat,cmd | grep sleep
>>>  30930   30570 S    sleep 600
```

#### 5.9. Скрипт script32

Текст скрипта:

```bash
#!/usr/bin/env bash

log_file=~/script32.log

while true; do
    date >> $log_file
    echo "PID: $$" >> $log_file
    echo "PPID: ${PPID}" >> $log_file
    echo >> $log_file
    
    sleep 2
done
```

#### 5.10. Управление заданиями

Последовательность действий и вывод:

```bash
# запуск скрипта в фоновом режиме
./script32.sh &
>>> [1] 31279

# Список заданий
jobs
>>> [1]+  Запущен          ./script32.sh &

# PID
echo $!
>>> 31279

# возврат задания на передний план
fg 1
>>> ./script32.sh

# остановка (ctrl + z)
>>> [1]+  Остановлен    ./script32.sh

# запуск в фоновом режиме
bg 1
>>> [1]+ ./script32.sh &

# завершение задания
kill %1
jobs
>>> [1]+  Завершено      ./script32.sh
```

#### 5.11. Эксперимент с SIGH

| Вариант запуска | Процесс жив после закрытия сессии? | Пишется ли файл лога? |
| --------------- | ---------------------------------- | --------------------- |
| Через &         | да                                 | да                    |
| Через nohup     | да                                 | да                    |
Ожидалось, что после завершения ssh сессии процесс, запущенный через `&` завершиться, однако, он как и вариант с nohup проигнорировал SIGNUP и поменял родителя на PID 1.
#### 5.12. PPID процесса при запуске через nohup

Значение PPID в варианте с nohup и в обычном запуске:

```bash
ps -eo pid,ppid,stat,cmd | grep script
>>> 32389       1 S    bash ./script32.sh # PPID 1
 
ps -eo pid,ppid,stat,cmd | grep script
>>> 33489   32959 S    bash ./script32.sh # PPID 32959
```

Так происходит, потому что при при обычном запуске родительским процессом программы является текущая оболочка.
При запуске с помощью `nohup` программа игнорирует сигнал `SIGHUP`, поэтому продолжает работу после завершения сессии. Когда родительский процесс завершается, процесс переподчиняется процессу `init`, в результате чего его PPID меняется на 1.

**Чек-лист части 5:**

- [x] u1 меняет пароль u2 через sudo, но не может сменить пароль root и не может запустить просмотр /root через sudo
- [x] Файл в /etc/sudoers.d/ проверен и имеет права 0440
- [x] Построена цепочка PID–PPID до PID 1, объяснён родитель оболочки
- [x] Разница в поведении фонового процесса с nohup и без объяснена (SIGHUP)
- [x] script32 исполняемый, после экспериментов его процессы завершены

---

### Часть 6. Аудит безопасности в скрипте инвентаризации

Код скрипта script_passport_v3.sh

```bash
#!/usr/bin/env bash

set -euo pipefail
trap cleanup EXIT


cleanup() {
    find -name "*.tmp" -delete
}

die() {
    local error="$1"

    echo "$error" >&2
    exit 1
}

check_privileges() {
    if [[ $(id -u) == 0 ]]; then
        return 0
    fi

    if sudo -l &> /dev/null; then
        return 0
    fi

    die "${0}: root or sudo required: permission denied"
}

log_run() {
    local start_time="$1"
    local version="v3"

    echo "${start_time}: script_passport_${version}.sh started" >> PASSPORT/log/report.log
}

usage() {
    local script="$0"

    cat <<EOF
Usage: $script [OPTIONS] [FILE]

Description:
  This script creates system report

Options:
  -h, --help      show this page
EOF
}

run_privileged() {
    local command="$@"

    # root user
    if [[ $(id -u) == 0 ]]; then
        $command

    elif sudo -l &> /dev/null; then
        sudo $command
    
    else
        die "unable to run '${command}' in privileged mode"

    fi
}

check_tool() {
    local tool_name="$1"

    if [[ "$(run_privileged "which $tool_name")" == "" ]]; then
        die "${0}: ${tool_name}: dependency not installed, run 'apt install ${tool_name}' to install it"
    fi
}

write_tmp() {
    local name=$2
    local data=$4

    echo "$data" >> "${TMP_PATH}/${name}.tmp"
}

write_section() {
    local name="$2"
    local data="$(cat "${TMP_PATH}/${4}.tmp")"

    echo "${name}: ${data}" >> $REPORT_PATH
}

write_list() {
    local name="$2"
    local data="$4"

    echo "${name}:" >> $REPORT_PATH

    while IFS= read -r line; do
        echo "  - $line" >> $REPORT_PATH
    done < "$TMP_PATH/${data}.tmp"
}

write_header() {
    local header="$1"

    echo >> $REPORT_PATH
    echo "$header" >> $REPORT_PATH
    echo >> $REPORT_PATH
}

write_without_header() {
    local data="$(cat "${TMP_PATH}/${2}.tmp")"

    echo $data >> $REPORT_PATH
}


# 1. Checking if user needs help
if [[ "${1:-default}" == "-h" ]]; then
    usage
    exit 0
fi


# 2. Checking privileges
check_privileges


# 3. Preparing environment

# creating required directories
mkdir -p PASSPORT/log
mkdir -p PASSPORT/tmp

# defining constants
readonly CURRENT_TIME="$(date)"
readonly DEPENDENCIES='lslogins dmidecode lscpu lspci nproc'
readonly TMP_PATH='PASSPORT/tmp'
readonly REPORT_PATH="PASSPORT/${1:-inventory.txt}"

# checking DEPENDENCIES
for dependency in $DEPENDENCIES; do
    check_tool $dependency
done

# remove old report
rm -f $REPORT_PATH


# 4. Collecting system information
write_tmp --name date --data "$CURRENT_TIME"
write_tmp --name hostname --data "$(hostname)"
write_tmp --name user --data "$(whoami)"
write_tmp --name wd --data "$(pwd)"
write_tmp --name files --data "$(ls -a)"

write_tmp --name kernel-name --data "$(uname --kernel-name)"
write_tmp --name kernel-version --data "$(uname --kernel-version)"
write_tmp --name cpu-bitness --data "$(uname --machine)"
write_tmp --name os-version --data "$(. /etc/os-release && echo $PRETTY_NAME)"
write_tmp --name cpu-model --data "$(grep -m 1 "model name" /proc/cpuinfo | sed 's/.*: //')"
write_tmp --name cpu-mhz --data "$(lscpu | grep -m 1 "CPU max MHz" | sed 's/^[^0-9]*//')"
write_tmp --name cpu-cores --data "$(nproc)"
write_tmp --name memory --data "$(grep "MemTotal" /proc/meminfo | sed 's/MemTotal:[ \t]*//')"
write_tmp --name pci --data "$(lspci)"
write_tmp --name motherboard --data "$(run_privileged dmidecode -s baseboard-product-name)"
write_tmp --name bios-version --data "$(run_privileged dmidecode -s bios-version)"
write_tmp --name bios-release-date --data "$(run_privileged dmidecode -s bios-release-date)"

write_tmp --name sshd-permitrootlogin --data "$(run_privileged sshd -T | grep permitrootlogin | cut -d ' ' -f 2)"
write_tmp --name sshd-port --data "$(run_privileged sshd -T | grep -w port | cut -d ' ' -f 2)"
write_tmp --name sshd-logingracetime --data "$(run_privileged sshd -T | grep logingracetime | cut -d ' ' -f 2)"
write_tmp --name sshd-maxauthtries --data "$(run_privileged sshd -T | grep maxauthtries | cut -d ' ' -f 2)"
write_tmp --name sshd-passwordauth --data "$(run_privileged sshd -T | grep passwordauthentication | cut -d ' ' -f 2)"
write_tmp --name sshd-pubkeyauth --data "$(run_privileged sshd -T | grep pubkeyauthentication | cut -d ' ' -f 2)"
write_tmp --name top-5-processes --data "$(ps -eo pid,ppid,user,%mem,cmd --sort=-%mem | head -n 6)"
write_tmp --name suid-files --data "$(run_privileged find /usr/bin -type f -perm -4000)"
write_tmp --name suid-files --data "$(run_privileged find /usr/sbin -type f -perm -4000)"


# getting users information
usernames="$(getent passwd | cut -d ':' -f 1)"

# searching non system users
for username in $usernames; do
    uid="$(id -u "$username")"

    if (( uid < 1000 && uid != 0 )); then
        continue
    fi

    if (( uid == 65534 )); then
        continue
    fi

    groups="$(id -nG "$uid")"
    lastlog="$(lslogins -u "$uid" -o LAST-LOGIN --noheadings | head -n 1 | sed -E 's/^[^:]+:[[:space:]]+//')"
    lastchg="$(run_privileged passwd -S $username | cut -d " " -f 3)"

    write_tmp --name users --data "Name ${username:-''}; \
UID ${uid}; \
Groups ${groups:-''}; \
last log-in ${lastlog-''}; \
last password change ${lastchg-''}"

done

# searching users with no password
for username in $usernames; do
    uid="$(id -u "$username")"
    password_hash="$(run_privileged grep -E ^$username: /etc/shadow | cut -d : -f 2)"

    if [[ "$password_hash" == "" ]]; then
        write_tmp --name nopass-users --data "Username: $username; UID $uid"    
    fi
done
write_tmp --name nopass-users --data ""

# non root users with UID 0
for username in $usernames; do
    uid="$(id -u "$username")"

    if [[ "$uid" == "0" && "$username" != "root" ]]; then
        write_tmp --name pseudo-root-users --data "Username: $username; UID $uid"
    fi
done
write_tmp --name pseudo-root-users --data ""


# 5. Building report
write_header "======== System Information ========"

write_section --header "current time" --data date
write_section --header "host name" --data hostname
write_section --header "user" --data user
write_section --header "working directory" --data wd

write_list --header "working directory containment" --data files

write_section --header "Kernel" --data kernel-name
write_section --header "Kernel version" --data kernel-version
write_section --header "Cpu bitness" --data cpu-bitness
write_section --header "OS version" --data os-version
write_section --header "CPU" --data cpu-model
write_section --header "CPU max MHz" --data cpu-mhz
write_section --header "CPU cores" --data cpu-cores
write_section --header "Motherboard model" --data motherboard
write_section --header "BIOS version" --data bios-version
write_section --header "BIOS release date" --data bios-release-date

write_list --header "Devices connected to pci" --data pci

write_header "============== Users ==============="

write_list --header "Non system users" --data users

write_header "======== sshd configuration ========"

write_section --header "PermitRootLogin" --data sshd-permitrootlogin
write_section --header "Port" --data sshd-port
write_section --header "LoginGraceTime" --data sshd-logingracetime
write_section --header "MaxAuthTries" --data sshd-maxauthtries
write_section --header "PasswordAuthentication" --data sshd-passwordauth
write_section --header "PubkeyAuthentication" --data sshd-pubkeyauth

write_header "========= Top 5 processes =========="

write_list --header "Top 5 processes by memory usage" --data top-5-processes

write_header "========= Suspicious users ========="

write_list --header "Users with empty passwords" --data nopass-users
write_list --header "Non root users with UID 0" --data pseudo-root-users

write_header "=========== SUID files ============="

write_list --header "Suid files" --data suid-files

# 6. Deleting temporary files
cleanup

# 7. Logging
log_run "$CURRENT_TIME"
```

Проверка трёх сценариев запуска:

| Сценарий                   | Ожидаемое поведение | Фактический результат                                                     |
| -------------------------- | ------------------- | ------------------------------------------------------------------------- |
| Под root                   | Штатная работа      | Совпадает с ожидаемым                                                     |
| Под пользователем с sudo   | Штатная работа      | Совпадает с ожидаемым                                                     |
| Под пользователем без прав | Ошибка прав         | sh: 1: ./script_passport_v3.sh: Permission denied (Совпадает с ожидаемым) |


Сгенерированный отчёт:

```text
======== System Information ========

current time: Вт 24 ноя 2026 19:48:23 +03
host name: vbox
user: root
working directory: /home/kaa-1
working directory containment:
  - .
  - ..
  - app.log
  - .bash_history
  - .bash_logout
  - .bashrc
  - .config
  - .face
  - .face.icon
  - file.txt
  - .local
  - nohup.out
  - PASSPORT
  - .profile
  - script31.sh
  - script32.log
  - script32.sh
  - script_passport_v3.sh
  - .ssh
  - .sudo_as_admin_successful
Kernel: Linux
Kernel version: #1 SMP PREEMPT_DYNAMIC Debian 6.12.116-1 (2026-11-07)
Cpu bitness: x86_64
OS version: Debian GNU/Linux 13 (trixie)
CPU: AMD Ryzen 5 8640HS w/ Radeon 760M Graphics
CPU max MHz: 
CPU cores: 1
Motherboard model: VirtualBox
BIOS version: VirtualBox
BIOS release date: 12/01/2006
Devices connected to pci:
  - 00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC [Natoma] (rev 02)
  - 00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
  - 00:01.1 IDE interface: Intel Corporation 82371AB/EB/MB PIIX4 IDE (rev 01)
  - 00:02.0 VGA compatible controller: VMware SVGA II Adapter
  - 00:03.0 Ethernet controller: Intel Corporation 82540EM Gigabit Ethernet Controller (rev 02)
  - 00:04.0 System peripheral: InnoTek Systemberatung GmbH VirtualBox Guest Service
  - 00:05.0 Multimedia audio controller: Intel Corporation 82801AA AC'97 Audio Controller (rev 01)
  - 00:06.0 USB controller: Apple Inc. KeyLargo/Intrepid USB
  - 00:07.0 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 08)
  - 00:0b.0 USB controller: Intel Corporation 82801FB/FBM/FR/FW/FRW (ICH6 Family) USB2 EHCI Controller
  - 00:0d.0 SATA controller: Intel Corporation 82801HM/HEM (ICH8M/ICH8M-E) SATA Controller [AHCI mode] (rev 02)

============== Users ===============

Non system users:
  - Name root; UID 0; Groups root; last log-in ноя17/23:51                      ; last password change 2026-11-12
  - Name svvvrm; UID 1000; Groups svvvrm sudo users; last log-in ноя19/00:25                      ; last password change 2026-11-12
  - Name kaa-1; UID 1001; Groups kaa-1 sudo users; last log-in 19:15                               ; last password change 2026-11-17
  - Name test; UID 0; Groups root; last log-in ноя17/23:51                      ; last password change 2026-11-18
  - Name u1; UID 1003; Groups u1 project; last log-in ; last password change 2026-11-18
  - Name u2; UID 1004; Groups u2 project; last log-in ; last password change 2026-11-22
  - Name u3; UID 1005; Groups u3 project; last log-in ноя19/18:50                      ; last password change 2026-11-19
  - Name u4; UID 1006; Groups u4 sec2; last log-in ; last password change 2026-11-19
  - Name u5; UID 1007; Groups u5 sec2; last log-in ; last password change 2026-11-19

======== sshd configuration ========

PermitRootLogin: no
Port: 22
LoginGraceTime: 30
MaxAuthTries: 2
PasswordAuthentication: no
PubkeyAuthentication: yes

========= Top 5 processes ==========

Top 5 processes by memory usage:
  -     PID    PPID USER     %MEM CMD
  -     862     837 Debian-+ 12.4 /usr/bin/gnome-shell
  -    1194     862 Debian-+  6.2 /usr/libexec/mutter-x11-frames
  -    1219       1 Debian-+  3.2 /usr/libexec/ibus-x11 --kill-daemon
  -     897     862 Debian-+  3.1 /usr/bin/Xwayland :1024 -rootless -noreset -accessx -core -auth /run/user/110/.mutter-Xwaylandauth.GATOZ3 -listenfd 4 -listenfd 5 -displayfd 6 -initfd 7 -byteswappedclients
  -    1269       1 Debian-+  1.9 /usr/libexec/xdg-desktop-portal-gnome

========= Suspicious users =========

Users with empty passwords:
  - Username: test; UID 0
  - 
Non root users with UID 0:
  - Username: test; UID 0
  - 

=========== SUID files =============

Suid files:
  - /usr/bin/chfn
  - /usr/bin/sudo
  - /usr/bin/gpasswd
  - /usr/bin/newgrp
  - /usr/bin/pkexec
  - /usr/bin/mount
  - /usr/bin/su
  - /usr/bin/umount
  - /usr/bin/passwd
  - /usr/bin/fusermount3
  - /usr/bin/chsh
  - /usr/bin/ntfs-3g
  - /usr/sbin/pppd
```

Содержимое лога после двух запусков:

```text
Вт 24 ноя 2026 19:44:03 +03: script_passport_v3.sh started
Вт 24 ноя 2026 19:48:23 +03: script_passport_v3.sh started
```

Сравнение lastlog2 и lslogins:

lastlog2
- Показывает только данные о последнем входе: имя, терминал или порт, время и откуда вошёл.
- Хранит записи в собственной базе SQLite. Она заполняется PAM-модулем при каждом новом входе (локальном или по SSH).
- Если пользователь ни разу не входил после установки пакета, записей нет. Для него будет "Never logged in" или пусто.
- Формат вывода простой и табличный, разбирать его в скрипте легко.

lslogins
- Это сводка по учётным записям из пакета util-linux. Показывает не только вход: UID, имя, число процессов, статус пароля, группы, домашний каталог, шелл, неудачные входы и т. д.
- Набор колонок настраивается, можно выбрать только нужные, а также отдельно обычных или системных пользователей и вывод по одной записи.
- Данные о входах берёт из системных журналов, а не из базы lastlog2.
- Вывод шире, и его нужно сильнее фильтровать при разборе в скрипте.

Параметры sshd заданые явно и взятые по умолчанию:

| Параметр               | Источник             |
| ---------------------- | -------------------- |
| PermitRootLogin        | /etc/ssh/sshd_config |
| Port                   | по умолчанию         |
| LoginGraceTime         | /etc/ssh/sshd_config |
| MaxAuthTries           | /etc/ssh/sshd_config |
| PasswordAuthentication | /etc/ssh/sshd_config |
| PubkeyAuthentication   | /etc/ssh/sshd_config |

**Чек-лист части 6:**

- [x] Скрипт проверяет права и корректно отказывает пользователю без прав
- [x] Не менее пяти фрагментов оформлено функциями, включая check_privileges, check_tool, write_section, log_run
- [x] Временные файлы удаляются при любом завершении (включая Ctrl+C)
- [x] Раздел «Пользователи» содержит группы, последний вход и дату смены пароля
- [x] Раздел «Параметры sshd» показывает эффективные значения
- [x] Отчёт содержит дополнительные разделы; после двух запусков в логе две строки

---

## Ответы на вопросы и задания

### 1. Зачем при создании SSH-ключа предлагается задать парольную фразу и от какой угрозы она защищает?

Парольная фраза шифрует закрытый ключ на диске. Если файл украли, без фразы им нельзя воспользоваться. Защищает она именно от кражи файла ключа, а не от перехвата соединения.

### 2. Зачем при первом подключении клиент показывает отпечаток ключа сервера? Что произойдёт, если отпечаток изменится?

Это проверка подлинности сервера: вы подтверждаете, что подключаетесь именно к нужной машине, а не к подставной (атака MITM). Принятый ключ сохраняется в `~/.ssh/known_hosts`. Если отпечаток потом изменится, клиент выдаст предупреждение и откажется подключаться. Причина может быть безобидной (переустановка сервера) или опасной (подмена).

### 3. Если у двух пользователей одинаковые пароли, можно ли понять это по /etc/shadow? Почему?

Нет. Хеш считается со случайной солью, поэтому у одинаковых паролей записи разные.

### 4. Таблица атрибутов прав

| Атрибут    | Название             | Для файла                         | Для каталога                                                                       |
| ---------- | -------------------- | --------------------------------- | ---------------------------------------------------------------------------------- |
| r          | read (чтение)        | читать содержимое                 | получать список имён                                                               |
| w          | write (запись)       | изменять содержимое               | создавать, переименовывать, удалять записи (только вместе с x)                     |
| x          | execute (выполнение) | запускать как программу           | входить в каталог и обращаться к файлам по имени                                   |
| suid       | set user ID          | запуск с правами владельца файла  | обычно не используется                                                             |
| sgid       | set group ID         | запуск с правами группы-владельца | новые файлы наследуют группу каталога                                              |
| sticky bit | липкий бит           | обычно не используется            | удалять и переименовывать файлы могут только их владелец, владелец каталога и root |
### 5. Почему для удаления файла нужны права на каталог, а не на файл? Что меняет sticky bit?

Каталог хранит список имён файлов. Удаление убирает запись из этого списка, сам файл не меняется. Поэтому нужны `w` и `x` на каталоге. Sticky bit ограничивает это: даже при наличии `w` на каталоге можно удалять и переименовывать только свои файлы (плюс владелец каталога и root).

### 6. Команда ACL для выдачи всех прав конкретному пользователю. Как решить с помощью ACL задание 3 из Части 3?

Команда для одного пользователя:

```text
setfacl -m u:имя:rwx файл
```

Задание 3 (каталог `/DATA/sec2`) через ACL:

```text
setfacl -m u:u1:rwx /DATA/sec2
setfacl -m u:u4:rx,u:u5:rx /DATA/sec2
setfacl -m o::--- /DATA/sec2
```

Для новых файлов в каталоге добавляют умолчательные ACL с ключом `-d` с теми же правами.
### 7. Чем различаются su, su - и sudo? Почему для повседневной работы рекомендуют sudo?

- `su` переключает на другого пользователя, нужен пароль целевого пользователя. Окружение в основном сохраняется от текущего.
- `su -` запускает полноценный вход с окружением целевого пользователя (его домашний каталог, переменные и т. д.).
- `sudo` выполняет одну команду от имени другого пользователя, нужен пароль вызвавшего.

Для повседневной работы рекомендуют sudo, потому что пароль root не раздаётся, права можно выдавать точечно через sudoers, а каждое использование попадает в журнал. Это соответствует принципу наименьших привилегий.

### 8. Удалось ли обойти ограничение sudo из Части 5? Почему правила с подстановочными знаками считаются опасными?

Нет, хоть и было использовано множество вариантов с различными флагами. 

Подстановочные знаки опасны, потому что `*` в sudoers совпадает с любыми аргументами, включая пробелы и ключи команды. Запрет на конкретную форму вызова (например, смену пароля root) сравнивает строку аргументов буквально, и её можно обойти другой формой записи. Поэтому надёжнее разрешать только точные команды и избегать `*`.

### 9. Чем отличается SIGTERM от SIGKILL? Какой из сигналов процесс может перехватить?

SIGTERM просит процесс завершиться: он может перехватить сигнал, закрыть файлы и освободить ресурсы. SIGKILL убивает принудительно, ядром, без участия процесса. Перехватить можно только SIGTERM.

### 10. Что происходит с процессом, запущенным через &, при закрытии SSH-сессии? Почему nohup меняет поведение и почему изменился PPID?

При закрытии SSH-сессии оболочка получает SIGHUP и рассылает его своим заданиям, поэтому процесс, запущенный через `&`, завершается. `nohup` заставляет процесс игнорировать SIGHUP, поэтому он остаётся жить. После закрытия сессии его родитель (оболочка) завершился, и процесс "усыновляется" системой, поэтому PPID становится 1 (systemd), а не PID прежней оболочки.

### 11. Что такое зомби-процесс? Можно ли его убить сигналом SIGKILL и почему?

Это завершившийся процесс, у которого родитель ещё не прочитал код возврата (состояние Z). Он уже не выполняется и не потребляет память, остаётся только запись в таблице процессов. `kill -9` не поможет, потому что убивать уже нечего.

### 12. Чем отличается вывод проверки эффективной конфигурации sshd от строк в sshd_config? Пример параметра, у которого они различаются

`sshd -T` показывает эффективные значения, которые сервер реально использует: с учётом значений по умолчанию, вложенных файлов `sshd_config.d` и правила "первое найденное значение". `grep` по файлу показывает только строки, которые там есть. Различаются они, например, если параметр закомментирован, или если параметр в основном файле переопределён более ранним значением из `sshd_config.d`.

### 13. Какой риск возникает, если владелец исполняемого файла — root и на файл установлен suid?

Такая программа всегда запускается с правами root, независимо от того, кто её вызвал. Если в ней есть ошибка или она позволяет запускать другие команды или править файлы (как копия редактора), любой пользователь получает полный доступ к системе, то есть повышает привилегии до root.

---

## Вывод

В ходе работы были освоены базовые механизмы безопасности Linux на Debian 13. Настроен SSH-сервер, проверены подключения по паролю и копирование через scp, после чего вход по паролю и вход root были отключены, а доступ переведён на ключи Ed25519. При этом выяснилось, что эффективные значения параметров sshd нужно проверять отдельно от файла настроек, поскольку часть из них переопределяется вложенными файлами или берётся по умолчанию. Также были изучены учётные записи и группы, настроены каталоги с групповым доступом, sticky bit и suid, а на примере копии редактора с suid показан риск повышения привилегий. Освоены `su` и `sudo`, точечная настройка прав через `sudoers.d` и принцип наименьших привилегий.

Кроме того, была проведена работа с процессами: построены цепочки родитель - потомок до PID 1, процессами управляли сигналами и фоновыми заданиями, а эксперимент с `nohup` показал, как SIGHUP влияет на жизнь процесса и почему меняется его PPID. Скрипт инвентаризации доработан до версии v3 с разделением на функции, проверкой прав и разделами по безопасности. Полученные навыки применимы при администрировании серверов и автоматизации аудита безопасности.

---

