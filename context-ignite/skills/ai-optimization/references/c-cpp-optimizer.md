# C and C++ Optimizer Reference

Context Sage keeps the declaration, not the body. Headers are the public surface. `.c` / `.h` scan as C. `.cc`, `.cpp`, `.cxx`, `.hpp`, `.hh`, and `.hxx` scan as C++. `--lang cpp` also reads `.h`. The C program is [c/context_sage.c](../c/context_sage.c). The Rust packer calls it.

## Keep

- `struct`, `enum`, `union`, `class` names and the declaration line
- Function prototypes in headers, including `static inline` when that is the API
- C++ method declarations: qualifier, name, parameters, `const` / `override` / `noexcept`
- One-line purpose from the first comment

## Drop

- Function bodies, macro implementations longer than the declaration, license banners
- Generated build trees: `build/`, `CMakeFiles/`, `cmake-build*`
- `third_party/` and `vendor/`

## Example compressed form

```c
/* metre_parse.h — line to foot linkage */
struct MetrePlan { /* fields in source */ };
enum FootKind { Iamb, Trochee };
struct MetrePlan *parse_line(const char *text);
```

```cpp
// MetreView.hpp
class MetreView : public QWidget {
void paint(QPainter *painter) const override;
};
```
