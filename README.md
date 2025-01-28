
[한국어](README_kr.md) 👈
# English

## dalbit-polyfill
Polyfill libraries for dalbit used transpiling luau to lua (especially Lua 5.3)

### Tests
Requires `lune` installed. We use [frktest](https://github.com/itsfrank/frktest) for tests. So make sure `frktest` package is installed (Packages are managed by `pesde`.)
```sh
lune run test
```

### TO-DOs
- [ ] Benchmarks `next` polyfill functions (between `luauNext` and `djb2Next`)

### Limitations
- Please do not depend on error messages. since we can't compare table and number(primitive types), polyfill's custom types such as `userdata` type will be shown as `table` when comparing numbers like this example code.
```luau
local a = newproxy() < 2 -- errors: "attempt to compare table < number"
-- correct error message: "attempt to compare userdata < number"
```
- Please do not depend on hash table's orders. while the polyfill is trying to use/imitate `Luau`'s hash table implementations, it might still have some critical edge cases with orders(especially with number hashing and pointer hashing. the order is not guaranteed as `Luau`'s one)
- `Lua 5.3` has integers so there may be slightly different behavior.
- There may still be differences from `Luau` due to differences in `Lua` version and environment.

### Special Thanks
- [Luau](https://github.com/luau-lang/luau) - Some implementations of the polyfill were inspired/ported from original `Luau`'s source code(especially [hash tables](https://github.com/luau-lang/luau/blob/master/VM/src/ltable.cpp))
- [Dekkonot](https://github.com/Dekkonot) - For [bitbuffer](https://github.com/dekkonot/bitbuffer/) and hashing function that [calculates `a * b` mod 32](https://github.com/Dekkonot/luau-hashing/blob/main/modules/xxhash32/init.luau) for polyfill's [luauNext](src/luauNext.luau) implementation.
- Contributors of [kaledis](https://github.com/orpos/kaledis) - For bugs/issues finding/solving(especially `bit32` implementations for `Lua 5.1`) and battle testing in their [cool project](https://github.com/orpos/kaledis).
- [frktest](https://github.com/itsfrank/frktest) - Super cool and simple test framework for lune.

# Implementations
### Globals
- [x] `typeof`
- [x] `unpack`
- [x] `newproxy`
- [x] `gcinfo`
- More details [here](libs/globals.luau)

### Libraries
- [x] `buffer`
- [x] `math`
- [x] `os`
- [x] `string`
- [x] `table`
- [x] `debug`
- [x] `bit32`
- [x] `utf8`
- [ ] `vector` (WIP)
