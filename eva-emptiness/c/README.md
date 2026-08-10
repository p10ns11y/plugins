# eva-tether (C)

Secure EVA permission classifier. Hooks prefer this binary over shell.

## Build

```bash
make                 # → ../bin/eva-tether
# flags: -std=c11 -Wall -Wextra -Werror -Wconversion -Wshadow -O2
```

Consent-gated from the plugin:

```text
/eva-tether-init --yes
```

## CLI

```bash
eva-tether [--mode=grok|cursor] < hook-json-on-stdin
```

- **grok**: deny JSON or empty allow  
- **cursor**: `permission` allow | ask | deny JSON  

Fail-open on I/O or bad args (exit 0; Cursor emits allow).

## Files

| File | Owns |
|------|------|
| `eva_tether.h` | Public status, mode, classify/emit API |
| `eva_tether.c` | Scanners + JSON emit |
| `main.c` | stdin → classify → emit |

## Not elomaxz (by design)

Hook path is one-shot, not an MVU loop. If the plugin later becomes a **graph flow manager** with many interactive actions, compose [elomaxz](https://github.com/p10ns11y/elomaxz) there and keep this classifier as a pure leaf. See skill ref `permission-tether.md` § Future.
