==========================================
  PARADISE OBFUSCATOR (based by Prometheus)
==========================================

=== ЧТО СКАЧАТЬ НА ЧИСТУЮ WINDOWS ===

1. Lua 5.1 для Windows:
   https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/lua-5.1.5_Win64_bin.zip/download
   
   Распакуй в эту же папку (рядом с cli.lua).
   Должен быть файл lua5.1.exe в этой папке.

2. Всё. Больше ничего не нужно.

=== КАК ОБФУСЦИРОВАТЬ ===

Способ 1 (простой — один или несколько файлов):
   - Выдели один или несколько .lua файлов
   - Перетащи их на obfuscate.bat
   - Рядом с каждым файлом появится .obfuscated.lua

Способ 2 (через командную строку — один файл):
   lua5.1.exe cli.lua --config custom_config.lua --out output.lua input.lua

Способ 3 (через командную строку — несколько файлов):
   lua5.1.exe cli.lua --config custom_config.lua file1.lua file2.lua file3.lua

   Каждый файл получит свой .obfuscated.lua рядом с оригиналом.

Способ 4 (несколько файлов в отдельную папку):
   lua5.1.exe cli.lua --config custom_config.lua --outdir output_folder file1.lua file2.lua

   Все обфусцированные файлы попадут в output_folder/

=== НАСТРОЙКИ (custom_config.lua) ===

Текущий пайплайн:
   1. EncryptStrings     - шифрование строк
   2. SplitStrings       - разбивка строк на куски
   3. Vmify              - компиляция в кастомную VM
   4. ConstantArray      - все строки в таблицу
   5. NumbersToExpressions - числа в выражения (hex, scientific)
   6. WrapInFunction     - обёртка в функцию

Все строки автоматически в байт-escape формате (\89\100\84...).
AntiTamper ВЫКЛЮЧЕН (убивает скорость).

=== ЕСЛИ НУЖЕН КОММЕНТАРИЙ СВЕРХУ ===

Просто добавь в начало обфусцированного файла:
--[[ PARADISE OBFUSCATOR (based by Prometheus) ]] 

Или отредактируй obfuscate.bat чтобы добавлял автоматически.
