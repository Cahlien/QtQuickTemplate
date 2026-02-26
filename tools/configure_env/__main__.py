"""Allow running as ``python -m configure_env``."""

from __future__ import annotations

from configure_env._wizard import main

if __name__ == "__main__":
    raise SystemExit(main())
