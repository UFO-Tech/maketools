# ufotech/maketools

## Концепція

**maketools** — це механізм повторного використання Make-оточення між проєктами без копіпасти.

Make залишається центральним інструментом виконання.
Docker використовується лише як transport та installer.

Ідея проста:

* не вигадуємо новий велосипед
* не замінюємо Make
* не змушуємо розробника встановлювати додаткові тулзи
* розширюємо Make через підключені модулі

maketools встановлюється як окремий сервіс у `docker-compose` і при виконанні команди `update`:

* створює папку `.maketools` яку можна додати в `.gitignore`
* генерує root `Makefile` та підключає `Makefile.local.mk`, якщо перед цим в проєкті вже був `Makefile`, він стане `Makefile.local.mk`
* генерує `Makefile-config.yaml` для налаштування залежностей


---

## Як це працює

### 1. У docker-compose додається сервіс

```yaml
services:
  maketools:
    image: ufotech/maketools:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: ["init"]
    tty: true
```

### 2. Ініціалізація / оновлення

```bash
docker compose run --rm maketools update
```
або
```bash
make update
```
або
```bash
make u
```

Команда:

* зчитує `Makefile-config.yaml`
* очищує папку `.maketools`
* клонує external repositories
* збирає runtime-модулі
* наповнює папку `.maketools`

---

Перевірка роботи:
```bash
make help
```
Команда відобразить перелік усіх доступних команд

## Конфігурація (Makefile-config.yaml)

```yaml
version: 1

repositories:

require:
  - docker
  - my-custom-modules/docker2
```

### version
Обовʼязковий параметр, вказує версію схеми конфігурації.

### repositories
Не обовʼязковий параметр.
Список зовнішніх git-репозиторіїв з модулями для розширення переліку інструментів.

Кожен репозиторій має містити:

* `namespace` — унікальний префікс
* `url` — git-репозиторій з файлами `*.mk`
Приклад
```yaml
repositories:
  - namespace: my-custom-modules
    url: https://github.com/custom-vendor/maketools-modules.git
```

### require

Список модулів, які мають бути встановлені.

Модулі бувають:

* built-in (йдуть всередині образу)
* external (`<namespace>/<module>`)

---

## Модель модулів

Модуль — це звичайний `.mk` файл.

Ніякого runtime API.
Ніякого плагін-фреймворку.

`core.mk` просто підключає всі модулі:

```
include $(wildcard .maketools/requires/*.mk)
```

---

## Override модель

* `Makefile` — генерується автоматично
* `Makefile.local.mk` — для команд конкретного проєкту або розробника

maketools ніколи не змінює `Makefile.local.mk`.

---

## Принципи

* Повна детермінованість (кожен update — чистий rebuild)
* Відсутність lock-файлів
* Відсутність state
* Make — runtime
* Docker — installer

---

## Навіщо це потрібно

* не дублювати Makefile між проєктами
* централізовано підтримувати dev-команди
* легко підключати власні набори модулів
* масштабувати стандарт на рівні компанії

---

## Типовий workflow

```bash
git clone project

make update

make help
```

Готово.
