#!/usr/bin/env bash
# Fixed protocol: merged model, seed 42, Test 10500, 32768 tokens, concurrency 16.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# -ne 2 ]]; then
  echo 'Usage: bash scripts/run_test.sh /absolute/path/to/merged unique_run_tag' >&2
  exit 2
fi
MODEL=$(realpath -e -- "$1")
TAG=$2
export HF_HOME="${HF_HOME:-$PWD/.lab/hf}" PYTHONUNBUFFERED=1
export PY="${PY:-$PWD/.venv/bin/python}" SEQS=16
export HF_HUB_OFFLINE=1 HF_DATASETS_OFFLINE=1
mkdir -p outputs
exec 9>outputs/.evaluation.lock
flock -n 9 || { echo 'An evaluation is already running in this package.' >&2; exit 1; }
"$PY" scripts/protocol.py begin "$MODEL" "$TAG"
bash scripts/run_eval_dpo2e.sh "$TAG:42:32768:$MODEL:records/mmmu_test.json:1"
"$PY" scripts/protocol.py verify "$TAG"
