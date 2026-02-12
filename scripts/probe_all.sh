#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FARDRUN="${FARDRUN:-}"

if [ -z "$FARDRUN" ]; then
  echo "FARDRUN is empty. Example:" 1>&2
  echo 'export FARDRUN="/Users/g.bogans/Downloads/FARD_v0.5/target/debug/fardrun"' 1>&2
  exit 2
fi
if [ ! -x "$FARDRUN" ]; then
  echo "FARDRUN is not executable: $FARDRUN" 1>&2
  exit 2
fi

cd "$ROOT"

rm -rf _out_probes
rm -rf gaspard/_probes

mkdir -p _out_probes
mkdir -p gaspard/_probes

printf "%-34s  %s\n" "ASSERTION" "STATUS"
printf "%-34s  %s\n" "---------" "------"

_run() {
  local name="$1"
  local prog="gaspard/_probes/probe__${name}.fard"
  local out="$ROOT/_out_probes/${name}"

  rm -rf "$out"
  "$FARDRUN" run --program "$prog" --out "$out" >/dev/null 2>&1 || true

  if test -f "$out/error.json"; then
    printf "%-34s  FAIL\n" "$name"
    sed -n '1,200p' "$out/error.json"
    return 1
  else
    printf "%-34s  OK\n" "$name"
    return 0
  fi
}

_expect_err() {
  local name="$1"
  local want="$2"
  local prog="gaspard/_probes/probe__${name}.fard"
  local out="$ROOT/_out_probes/${name}"

  rm -rf "$out"
  "$FARDRUN" run --program "$prog" --out "$out" >/dev/null 2>&1 || true

  if test -f "$out/error.json" && rg -n "$want" "$out/error.json" >/dev/null 2>&1; then
    printf "%-34s  OK_EXPECTED\n" "$name"
    return 0
  fi

  printf "%-34s  FAIL\n" "$name"
  if test -f "$out/error.json"; then
    sed -n '1,200p' "$out/error.json"
  else
    echo '{"code":"ERROR_EXPECTED","message":"missing error.json"}'
  fi
  return 1
}

_trace_head() {
  local name="$1"
  local out="$ROOT/_out_probes/${name}"
  echo
  echo "=== TRACE $name (module_resolve head) ==="
  rg -n '"t":"module_resolve"' "$out/trace.ndjson" | head -n 180 || true
}

# NOTE: probes live in gaspard/_probes/, so imports MUST be relative to ../

cat > gaspard/_probes/probe__dag_main_run_core.fard <<'P'
import("../dag_main/core") as Core
Core.run_core()
P
_run "dag_main_run_core"
_trace_head "dag_main_run_core"

cat > gaspard/_probes/probe__aux_a_build_summary.fard <<'P'
import("../dag_aux_a/summary") as S
S.build_summary()
P
_run "aux_a_build_summary"
_trace_head "aux_a_build_summary"

cat > gaspard/_probes/probe__aux_b_build_report.fard <<'P'
import("../dag_aux_b/report") as R
R.build_report()
P
_run "aux_b_build_report"
_trace_head "aux_b_build_report"

cat > gaspard/_probes/probe__tools_artifacts.fard <<'P'
import("../tools/artifacts") as A
A.run_artifacts()
P
_run "tools_artifacts"
_trace_head "tools_artifacts"

cat > gaspard/_probes/probe__tools_encode.fard <<'P'
import("../dag_main/core") as Core
import("../dag_aux_a/summary") as Sum
import("../dag_aux_b/report") as Rep
import("../tools/artifacts") as Art
import("../tools/encode") as Enc

let core = Core.run_core() in
let str  = Sum.build_summary() in
let num  = Rep.build_report() in
let art  = Art.run_artifacts() in
Enc.run_encode(core, str, num, art)
P
_run "tools_encode"
_trace_head "tools_encode"

cat > gaspard/_probes/probe__tools_qmark_ok.fard <<'P'
import("../tools/qmark_tests") as Q
Q.run_qmark_ok()
P
_run "tools_qmark_ok"
_trace_head "tools_qmark_ok"

cat > gaspard/_probes/probe__tools_qmark_err.fard <<'P'
import("../tools/qmark_tests") as Q
Q.run_qmark_err()
P
_run "tools_qmark_err"
_trace_head "tools_qmark_err"

echo
echo "=== tools artifacts written (if any) ==="
find "$ROOT/_out_probes" -path '*/artifacts/*' -type f | sort || true

cat > gaspard/_probes/probe__expect_import_cycle.fard <<'P'
import("../tests_cycles/a") as A
A.a()
P
_expect_err "expect_import_cycle" 'IMPORT_CYCLE'
_trace_head "expect_import_cycle"

cat > gaspard/_probes/probe__expect_lock_missing.fard <<'P'
import("../tests_lock/locked") as L
L.locked()
P
_expect_err "expect_lock_missing" 'ERROR_LOCK'
_trace_head "expect_lock_missing"

cat > gaspard/_probes/probe__gaspard_main.fard <<'P'
import("../gaspard") as G
G.main()
P
_run "gaspard_main"
_trace_head "gaspard_main"

echo
echo "=== OUTPUT INDEX ==="
find "$ROOT/_out_probes" -maxdepth 2 -type f | sort

echo
echo "DONE"
