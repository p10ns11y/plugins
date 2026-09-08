#!/usr/bin/env python3
"""Run SkillEvaluator after dropping empty loader-reset env vars.

SkillEvaluator 0.2.1 writes BASH_ENV="" (and other loader names) into every
Harbor task so Docker clears them. Local mode then rejects the key itself,
so install() dies on `opencode --version` before any trial starts.
"""

from __future__ import annotations

import sys
from pathlib import Path

import runpy

runpy.run_path(str(Path(__file__).with_name("se_local_patch.py")))

from skillevaluator.cli import cli

sys.argv[0] = "skillevaluator"
cli()
