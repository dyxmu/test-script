# WeAreDevs / Prometheus Lua Deobfuscator

Деобфускатор для Lua-скриптов, обфусцированных [WeAreDevs Obfuscator](https://wearedevs.net/obfuscator), основанным на [Prometheus](https://github.com/prometheus-lua/Prometheus).

## Возможности

- **Полная реконструкция исходников** — восстанавливает настоящий Lua код с переменными, вызовами API, колбэками
- **Поддержка Roblox** — стабы для game, Instance, Drawing, Enum, task, и всех сервисов
- **Расшифровка строк** — custom base64 + shuffled таблица строк
- **Обход anti-tamper** — использует полное окружение для обхода защиты Prometheus
- **Event/Connect** — восстанавливает структуру событий (MouseButton1Click, FocusLost и т.д.)
- **Поддержка exploit API** — syn, fluxus, crypt, WebSocket, writefile и т.д.

## Требования

- Python 3.6+
- Lua 5.1 (`lua5.1`)

```bash
# Ubuntu/Debian
sudo apt-get install lua5.1
```

## Использование

```bash
# Вывод в stdout
python3 deobfuscate.py obfuscated.lua

# Сохранить в файл
python3 deobfuscate.py obfuscated.lua output.lua
```

## Как работает

### 1. Расшифровка строк
Извлекает таблицу строк (octal escape sequences), применяет swap-операции, декодирует custom base64.

### 2. Full Source Reconstruction (`full_tracer.lua`)
Основной метод — запуск кода в sandbox с полной эмуляцией Roblox API:
- Все `game:GetService()` → автоматическое создание переменных
- `Instance.new()` → создание объектов с правильными именами
- `.Connect(function() ... end)` → выполнение колбэков и запись структуры
- Property assignments → `object.Property = value`
- Exploit API стабы (getgenv, writefile, request, etc.)

### 3. Legacy Tracer (`tracer.lua`)
Для простых скриптов с `print` — перехват вывода с распознаванием for-циклов и переменных.

## Пример

**Обфусцированный файл (624KB):**
```
return(function(...)local N={"\057\102\107\087...
```

**Восстановленный код:**
```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
...
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArqelRedSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui
...
textButton2.MouseButton1Click:Connect(function()
    -- callback code
end)
```

## Ограничения

- **Имена переменных** — Prometheus удаляет оригинальные имена. Деобфускатор использует имена на основе типов (`frame`, `textLabel`, `uICorner`)
- **Control flow** — if/else и while реконструируются только по execution path
- **Один путь выполнения** — трейсер проходит один execution path

## Файлы

- `deobfuscate.py` — Главный Python-скрипт (координация + анализ строк)
- `full_tracer.lua` — Полная реконструкция с Roblox стабами
- `tracer.lua` — Legacy трейсер для простых скриптов
- `example_output.lua` — Пример деобфусцированного кода (624KB → 460 строк)
