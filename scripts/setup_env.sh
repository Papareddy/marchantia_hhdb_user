# Source this from query.sh / batch_query.sh — auto-activate the conda env.
#
# Behavior:
#   - If hhsearch + pandas + matplotlib are already importable, do nothing.
#   - Else: source conda from $(conda info --base); create marchantia_hhdb env
#     from environment.yml if it doesn't exist (one-time, ~3 min); then activate.
#
# Honors $MARCHANTIA_HHDB_ENV (default "marchantia_hhdb") so users can override.

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ENV_NAME=${MARCHANTIA_HHDB_ENV:-marchantia_hhdb}

_have_deps() {
  command -v hhsearch >/dev/null 2>&1 \
    && python -c "import pandas, matplotlib" 2>/dev/null
}

if _have_deps; then
  return 0 2>/dev/null || exit 0
fi

# find conda
if ! command -v conda >/dev/null 2>&1; then
  if [ -n "${MINIFORGE_HOME:-}" ] && [ -f "$MINIFORGE_HOME/etc/profile.d/conda.sh" ]; then
    source "$MINIFORGE_HOME/etc/profile.d/conda.sh"
  elif [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniforge3/etc/profile.d/conda.sh"
  elif command -v module >/dev/null 2>&1; then
    module load devel/miniforge/24.9.2 2>/dev/null || true
  fi
fi

CONDA_BASE=$(conda info --base 2>/dev/null || true)
[ -z "$CONDA_BASE" ] && {
  echo "ERROR: conda not found. Install miniforge first:" >&2
  echo "  curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-\$(uname)-\$(uname -m).sh && bash Miniforge3-*.sh" >&2
  return 1 2>/dev/null || exit 1
}
source "$CONDA_BASE/etc/profile.d/conda.sh"

# create env if missing
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  echo "[setup] one-time env create: $ENV_NAME (takes ~3 min on a fresh machine)"
  if command -v mamba >/dev/null 2>&1; then
    mamba env create -f "$REPO_ROOT/environment.yml" -n "$ENV_NAME"
  else
    conda env create -f "$REPO_ROOT/environment.yml" -n "$ENV_NAME"
  fi
fi

conda activate "$ENV_NAME"
export HHLIB=${HHLIB:-$CONDA_PREFIX}

_have_deps || {
  echo "ERROR: env '$ENV_NAME' active but deps still missing — see environment.yml" >&2
  return 1 2>/dev/null || exit 1
}
unset _have_deps
