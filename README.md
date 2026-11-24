# Скины сервера — статический сайт для CustomSkinLoader

Текущий адрес: **https://nightwish8.github.io/_skin_site/** (источник для CSL — `.../_skin_site/csl/`).

Это готовый сайт скинов по спецификации **CustomSkinAPI R2**, который CustomSkinLoader (CSL) умеет читать.
Хостится бесплатно на GitHub Pages, сервер Minecraft не участвует вообще.

Структура:

```
index.html                 — страничка со списком игроков (не обязательна, но удобно)
players.json               — список ников для страницы
csl/<Ник>.json             — профиль игрока: какой файл текстуры надевать
csl/textures/<sha256>.png  — сами текстуры, имя = SHA-256 содержимого
tools/add-skin.ps1         — добавить/обновить скин (валидация, хэш, JSON)
tools/set-url.ps1          — прописать адрес Pages в клиентский конфиг CSL
.nojekyll                  — чтобы GitHub не трогал файлы через Jekyll
```

Важно: по спецификации CustomSkinAPI текстуры запрашиваются как `{ROOT}/textures/{id}`,
поэтому они лежат **внутри** папки `csl`, а не рядом с ней. Если положить их в `_skin_site/textures`,
CSL получит 404 и скин не применится.

## 1. Публикация (один раз)

1. Создать **публичный** репозиторий, например `mc-skins`
   (Pages для приватных репозиториев на бесплатном тарифе не работают).
2. Скопировать в него всё содержимое этой папки (в корень репозитория).
3. Запушить:
   ```
   git init
   git add .
   git commit -m "skins: initial"
   git branch -M main
   git remote add origin https://github.com/USER/mc-skins.git
   git push -u origin main
   ```
4. В репозитории: **Settings → Pages → Build and deployment → Source: Deploy from a branch**,
   ветка `main`, папка `/ (root)` → Save.
5. Через 1–2 минуты проверить в браузере:
   ```
   https://USER.github.io/mc-skins/csl/Nightwish.json
   https://USER.github.io/mc-skins/
   ```
   Первый адрес должен отдать JSON, второй — страничку со скинами.

## 2. Подключение клиентов

Прописать адрес в клиентском конфиге (он лежит в `1.12.2\_client_mods\CustomSkinLoader\CustomSkinLoader.json`):

```
.\tools\set-url.ps1 -User USER -Repo mc-skins
```

или вручную заменить в конфиге `"root"` первой записи на `https://USER.github.io/mc-skins/csl/`
(обязательно со слэшем на конце).

Дальше раздать игрокам два файла: сам мод CSL и папку `CustomSkinLoader` с этим конфигом
(кладётся в `.minecraft\CustomSkinLoader\`). Порядок в `loadlist` уже такой:
**ваш сайт → LocalSkin → Mojang → LittleSkin → TLauncher**, то есть ваш сайт главнее всех.

## 3. Обновление скина

```
.\tools\add-skin.ps1 -Nick Nightwish -Skin C:\skins\nightwish_256.png
git add . ; git commit -m "skin: Nightwish" ; git push
```

Скрипт сам: проверит размер (квадрат, кратный 64 — 64/128/256/512), посчитает SHA-256,
положит текстуру в `textures/`, перепишет `csl\Nightwish.json` и добавит ник в `players.json`.
Кейп: `-Cape C:\skins\cape.png` (64×32 или 128×64). Тонкая модель (Alex): `-Slim`.

**Важно:** имя JSON-файла = игровой ник один-в-один (`csl\Nightwish.json`), иначе CSL не найдёт профиль.
Поэтому ник менять не нужно и нельзя — меняется только содержимое файла.

Если Windows блокирует скрипты:

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\add-skin.ps1 -Nick Nightwish -Skin C:\skins\new.png
```

## 4. Кэш и задержки

- GitHub Pages отдаёт `Cache-Control: max-age=600` — новая версия появляется за ~10 минут.
- CSL кэширует профили у себя: `.minecraft\CustomSkinLoader\Cache`. Если скин «не обновился» —
  закрыть игру, удалить эту папку, запустить снова.
- Хэш в имени файла текстуры гарантирует, что браузер/CSL не подсунет старую картинку:
  новый скин = новый файл.

## 5. Ограничения

- HD работает: 128×128, 256×256 и больше (кратно 64). Прозрачность — включена в конфиге
  (`enableTransparentSkin`).
- «Объёмность» остаётся ванильной: второй слой + HD-текстура. Дополнительной геометрии тут нет.
- Скин видят только клиенты с CSL — ванильный клиент 1.12.2 рендерит лишь 64×64.
- Репозиторий публичный, значит скины видны всем в интернете. Не кладите туда лишнего.
- Никакого PHP/бэкенда: чтобы игроки сами загружали скины, нужен Blessing Skin Server
  (это уже отдельный хостинг), а этот сайт — просто статика, обновляемая админом.
