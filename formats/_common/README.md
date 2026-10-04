# Shared types

Types used by more than one format spec. Add a type here only when a second
format needs it; until then keep it inside the format's own spec.

Import with a relative path from a format spec:

```yaml
meta:
  imports:
    - ../_common/<name>
```

Not a format: `tools/run_tests.py` and `tools/compile.sh` skip this directory.
