
# Gaspard Fard (FARD v0.5.0 / M2-closure fixture)

This is a **Gaspard-class universe**: one positive root DAG plus separate negative universes.

## Positive root
- Root module: `gaspard/gaspard.fard`

Expected runner outputs (contract-dependent):
- `trace.ndjson`
- `module_graph.json`
- `result.json`

## Negative universes (separate runs)
- Import cycle: `gaspard/tests_cycles/a.fard` or `gaspard/tests_cycles/b.fard` must yield `IMPORT_CYCLE`.
- Lock mismatch: `gaspard/tests_lock/locked.fard` with an intentionally mismatching lock entry must yield `LOCK_MISMATCH`.
- QMark unwind: `gaspard/tools/qmark_tests.fard` entry `run_qmark_err` is an expected failure run.

## Module count
- Total modules in this fixture: 23
