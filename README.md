# Collection of my BG3 mods

# Useful commands

### JSON to Lua

```sh
perl -pe 's/"(\w+)"\s?:/$1=/; s/\[/\{/g; s/\]/\}/g' input.json > output.lua
```

### count lines of code (ToT)
```sh
rg "^(\s+\w+|\w)" -c -g '*.lua' -g '!**/Templates/**' -g '!OsirisEventDebug.lua' | awk -F':' '{sum += $2} END {print sum}'
```
