# BAC
Пакет для Debian / Ubuntu, позволяющий реализовать резервное копирование файлов (и целых директорий с файлами) критической инфраструктуры, в облако SELECTEL

### Установка пакетов

1) Устанавливаем пакет gpg - который требуется для шифрования архива резервной копии перед передачей в облако (на сервер и на свою клиентскую машину)
```bash
sudo apt update && sudo apt install gpg
```

После установки пакета генерируем ключи (на сервере и на своей клиентской машине)
```bash
gpg --gen-key
```

Далее, экспортируем свой PGP публичный ключ (на клиентской машине), он будет использован при шифровании архива, и затем закрытым ключем который соответствует этому открытому ключу, можно будет его расшифровать.

Просмотреть список всех ключей в системе можно командой:
```bash
gpg --list-key
```

Экспортируем свой PGP публичный ключ в файл
```bash
gpg --export -a "you@gmail.com" > ~/.ssh/gpgpub.key
```

Переносим этот файл на сервер, и там импортируем этот ключ
```bash
gpg --import /tmp/gpgpub.key
```

Подписываем импортированный ключ, приватным ключем сервера
```bash
gpg --sign-key you@gmail.com
```

Запоминаем email импортированного ключа, который является своего рода ID этого ключа, он понадобится при установке пакета bac.


2) Устанавливаем пакет s3cmd
В качестве хранилища предусмотрен провайдер SELECTEL
Следует предварительно настроить облако (создать контейнер, настроить правила доступа к контейнеру, создать сервисного пользователя и S3 ключи для этого пользователя) подробнее описано в файле "Работа с SELECTEL хранилищем.pdf"

Устанавливаем пакет
```bash
sudo apt update && sudo apt install s3cmd
```
Конфигурация s3cmd - доступ к хранилищу
```bash
s3cmd --configure
```

Указываем значения при запросах (основные, для остальных можно просто нажать Enter):
```config
Access Key YOUR_S3_KEY
Secret Key YOUR_S3_SECRET_KEY
Default Region [US]: ru-1
S3 Endpoint [s3.amazonaws.com]: s3.ru-1.storage.selcloud.ru
DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: s3.ru-1.storage.selcloud.ru
```
При запросе "Test access with supplied credentials? [Y/n]" указываем "Y" т.к требуется проверить соединение с облаком!
Если тест соединения с облаком прошел успешно, обязательно указываем "y" для сохранения конфигурации.
После сохранения настроек, будет выведен файл куда эти настройки сохранены.

3) Устанавливаем пакет bac_0.1-1_all.deb
Пакет который добавит сервис резервного копирования в систему, который в свою очередь будет запускать bash скрипт выполняющий всю работу по добавлению нужных файлов и директорий в архив резервной копии, шифрование этого архива и отправку его в сетевое хранилище. При установке пакета будут запрошены такие данные: 
- **"Enter your GPG key (email) which can decrypt the backup archive:"** - ID GPG ключа, это тот email нашего ключа с локальной машины, который был импортирован ранее 
- **"Enter cloud storeage container name:"** - имя контейнера в SELECTEL
- **"Enter user under which to run the service:"** - имя пользователя и группу под которым запускать сервис. Здесь укажите то что выводить команда id
также запрошено имя контейнера в SELECTEL, указываем его и жмем Enter.

Устанавливаем пакет командой:
```bash
sudo apt install ./bac_0.1-1_all.deb
```

После установки будет выведен перечень команд для запуска сервиса
```bash
sudo systemctl enable bac.timer
sudo systemctl start bac.timer
sudo systemctl enable bac.service
sudo systemctl start bac.service
sudo systemctl status bac.timer
```

Конфиги и файлы сервиса
- **/etc/bac.conf** - конфиг с перечнем файлов и директорий попадающих в резервную копию
- **/usr/bin/bac.sh** - скрипт выполняющий резервирование, шифрование и отправку в облако
-  **/etc/systemd/system/bac.timer** - сервис который запускается 1 раз в день
- **/etc/systemd/system/bac.service** - сервис запускающий скрипт bac.sh

ВАЖНО: для быстрого тестирования запуск сервиса в Unit файле bac.timer настроен на 1 раз в минуту, после того как вы убедились что файл резервной копии появился в контейнере (после запуска сервисов), следует изменить это значение на один раз в 24ч (или на любое другое). 

Требуется отредактировать файл Unit: 
```bash
sudo vim /etc/systemd/system/bac.timer
```

Указав там такое значение (например 24h)
И перезагрузить системные демоны, командой:
```bash
sudo systemctl daemon-reload
```

### Ошибки сервиса
Если видим что в облаке нет архва на нужную дату, при том что сервис активет, нужно смотреть журнал системы с фильтром по сервису
```bash
sudo journalctl -f -u bac.service
```