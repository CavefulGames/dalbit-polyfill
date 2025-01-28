# 한국어

## dalbit-polyfill
Dalbit에서 Luau -> Lua(특히 Lua 5.3)로 트렌스파일링시 필요한 폴리필 라이브러리

### 노트
- 해당 라이브러리 소스코드는 Lua 5.3에서 동작하도록 설계되었으며, 개발시 정확한 타입체크를 위해 루아우 타입이 사용되어 `darklua` 변환없이는 일반 Lua에 의존하는 API는 Luau에서도 Lua 5.3에서도 실행 불가능한 상태입니다.

### 작동 방식
- Dalbit에서 이 저장소를 `git clone`(내부적으론 libgit2를 사용)하여 사용자 컴퓨터 캐시에 저장한 뒤 `darklua`를 사용하여 하나의 모듈로 번들링하여 주입시키는 방식으로 작동합니다.

### 한계점
- 오류 메시지에 의존하지 마세요. 테이블과 숫자(기본 유형)를 비교할 수 없으므로 이 예제 코드와 같이 숫자를 비교할 때 `userdata` 유형과 같은 폴리필의 사용자 정의 유형은 `table`로 표시됩니다.
```luau
local a = newproxy() < 2 -- 폴리필의 오류 메시지: "attempt to compare table < number"
-- 올바른 예상된 루아우의 오류 메시지: "attempt to compare userdata < number"
```
- 해시 테이블의 순서에 의존하지 마세요. 폴리필이 `Luau`의 해시 테이블 구현을 사용/모방하려고 하지만 순서와 관련하여 여전히 몇 가지 중요한 예외 사례가 있을 수 있습니다(특히 숫자 해싱 및 포인터 해싱의 경우. 순서는 `Luau`의 순서와 같이 보장되지 않음)

### 특별 감사
- [Luau](https://github.com/luau-lang/luau) - 폴리필의 일부 구현은 원래 `Luau`의 소스 코드에서 영감을 받거나 이식되었습니다(특히 [해시 테이블](https://github.com/luau-lang/luau/blob/master/VM/src/ltable.cpp))
- [Dekkonot](https://github.com/Dekkonot) - [bitbuffer](https://github.com/dekkonot/bitbuffer/) 및 폴리필의 [luauNext.luau](src/luauNext.luau) 해싱 함수 구현을 위한 [`a * b` mod 32를 계산하는](https://github.com/Dekkonot/luau-hashing/blob/main/modules/xxhash32/init.luau) 함수의 구현을 제공.
- [kaledis](https://github.com/orpos/kaledis)의 기여자 - 버그/문제 찾기/해결(특히 `Lua 5.1`을 위한 `bit32` 구현) 및 [멋진 프로젝트](https://github.com/orpos/kaledis)에서의 실제 테스트 진행.
- [frktest](https://github.com/itsfrank/frktest) - lune을 위한 멋지고 간단한 테스트 프레임워크.
