#!/bin/bash
# Sanity check for an nextpyp-ood-interactive install.
# Run from the repo root: `bash scripts/check-prereqs.sh`

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAILED=1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

FAILED=0

# Load env if present
ENV_FILE="ood-app/template/env"
if [ -f "$ENV_FILE" ]; then
    # shellcheck disable=SC1090
    . "$ENV_FILE"
    pass "Sourced $ENV_FILE"
else
    warn "$ENV_FILE not found — using defaults. Copy env.example → env before deploy."
fi

NEXTPYP_INSTALL="${NEXTPYP_INSTALL:-/opt/nextpyp}"
NEXTPYP_PARTITION="${NEXTPYP_PARTITION:-compute}"

# --- Tools ---
for cmd in sinfo sbatch apptainer python3 curl ip; do
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "$cmd found at $(command -v "$cmd")"
    else
        if [ "$cmd" = "apptainer" ] && command -v singularity >/dev/null 2>&1; then
            pass "singularity found (apptainer alias) at $(command -v singularity)"
        else
            fail "$cmd not found on PATH"
        fi
    fi
done

# --- OOD ---
if [ -d /var/www/ood/apps/sys ]; then
    pass "OOD app directory /var/www/ood/apps/sys exists"
else
    warn "No /var/www/ood/apps/sys — are you running this on the OOD portal host?"
fi

# --- NextPYP install ---
for f in nextPYP.sif sharedExec/containers/pyp.sif templates/default.peb nextpyp-host-processor; do
    if [ -e "${NEXTPYP_INSTALL}/${f}" ]; then
        pass "Found ${NEXTPYP_INSTALL}/${f}"
    else
        fail "Missing ${NEXTPYP_INSTALL}/${f}"
    fi
done

# --- Slurm partition ---
if sinfo -h -p "${NEXTPYP_PARTITION}" -o "%c %m" >/dev/null 2>&1; then
    SIZING=$(sinfo -h -p "${NEXTPYP_PARTITION}" -o "%c %m" | sort -u | head -1)
    if [ -n "$SIZING" ]; then
        pass "Partition '${NEXTPYP_PARTITION}' visible: cpus/mem = $SIZING"
    else
        warn "Partition '${NEXTPYP_PARTITION}' visible but empty; fallbacks will be used"
    fi
else
    warn "sinfo can't see partition '${NEXTPYP_PARTITION}' — fallback sizing will kick in"
fi

# --- Firefox + XFCE (on the compute node this runs on, not portal) ---
if command -v firefox-esr >/dev/null 2>&1 || command -v firefox >/dev/null 2>&1; then
    pass "Firefox available"
else
    warn "No firefox / firefox-esr — install on every compute node in NEXTPYP_PARTITION"
fi

if command -v xfce4-session >/dev/null 2>&1; then
    pass "xfce4-session available"
else
    warn "No xfce4-session — install XFCE on compute nodes"
fi

echo
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}All required checks passed.${NC} Warnings are informational."
    exit 0
else
    echo -e "${RED}Some required checks failed.${NC} Fix them before deploying."
    exit 1
fi
