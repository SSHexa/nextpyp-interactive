# CONFIGURATION

Every environment variable the launcher reads, in one table.

Set these in `ood-app/template/env` (copied from `env.example`) or via OOD's cluster/app configuration.

| Variable | Required | Default | When to change |
|---|---|---|---|
| `NEXTPYP_INSTALL` | ✅ Yes | `/opt/nextpyp` | Path to your NextPYP install directory. Must contain `nextPYP.sif`, `sharedExec/containers/pyp.sif`, `templates/`, `workflows/`, `nextpyp-host-processor`. |
| `NEXTPYP_HOME` | No | `$HOME/nextpyp` | Per-user data root. Must be on a shared filesystem. Change if `$HOME` is portal-local. |
| `NEXTPYP_PARTITION` | No | `compute` | Slurm partition for NextPYP jobs. Must match `sinfo -p <name>`. |
| `NEXTPYP_BIND_MOUNTS` | No | `/scratch` | Comma-separated list of host paths bound into containers. Include everything users need to read/write. |
| `NEXTPYP_BIND_IP` | No | (auto-detected) | Force a specific IP for the web server. Useful when auto-detect picks the wrong interface (multi-NIC nodes, VPN). |
| `NEXTPYP_FALLBACK_CPUS` | No | `4` | Used when `sinfo` returns no CPU count. Set to a value your typical compute node has. |
| `NEXTPYP_FALLBACK_MEM_MB` | No | `8192` | Used when `sinfo` returns no memory count. |
| `CLUSTER_MODE` | No | `generic` | Set to `cyclecloud` to enable Azure CycleCloud dual-filesystem binds. See [CYCLECLOUD.md](CYCLECLOUD.md). |

## Using the pre-patched pyp.sif on NFS clusters

If your shared filesystem is NFS, Duke's stock `pyp.sif` will crash on any
parallel-processing job with a `FileNotFoundError` in `joblib/externals/loky/
backend/synchronize.py`. Root cause: `joblib`'s default `loky` backend uses
POSIX semaphores, which NFS does not implement correctly. Every parallel
step of every NextPYP block fails.

We host a pre-patched `pyp.sif` on GitHub Container Registry with a one-line
fix (switches `joblib.Parallel` to the `threading` backend, sidestepping
semaphores entirely). The patch is loky-only — it does not touch the
scientific code. See the source patch details in the repo history.

**Pull it** (once per install, not per user):

```bash
apptainer pull "${NEXTPYP_INSTALL}/sharedExec/containers/pyp.sif" \
  oras://ghcr.io/sshexa/nextpyp-pyp-patched:v0.7.2-loky-gzip
```

This replaces Duke's stock `pyp.sif` with the patched one at the same
location. No config changes needed — the launcher uses whatever sits there.

**Tags available:**

| Tag | Size | Compression | When to use |
|---|---|---|---|
| `v0.7.2-loky-gzip` | ~42 GB | gzip | Faster to build, slower to download. Available now. |
| `v0.7.2-loky-xz` | ~22 GB | xz | Slower to build, faster to download. May not be available yet — check the [Packages page](https://github.com/SSHexa/nextpyp-interactive/pkgs/container/nextpyp-pyp-patched). |
| `latest` | — | — | Points at the current recommended tag. |

**If your cluster uses Lustre, BeeGFS, GPFS, or local storage** (not NFS),
Duke's stock `pyp.sif` from `curl https://nextpyp.app/install | bash` works
unchanged. You can skip this section.

**How to tell:** run `mount | grep " on /shared "` (or wherever your shared
FS is). `type nfs4` or `type nfs` → use our patched sif. Anything else →
Duke's is fine.

## Precedence

1. Values in `ood-app/template/env` (sourced at launch)
2. Values inherited from the OOD Slurm job environment
3. Defaults hardcoded in `script.sh.erb`

## Verifying the auto-detected IP

If the launcher picks a wrong-looking IP for `NODE_IP`, check what it saw:

```bash
ip -4 route get 1.1.1.1
```

The `src` field is the IP the launcher will use. If that's wrong for your topology, set `NEXTPYP_BIND_IP` explicitly.

## Verifying Slurm sizing

Before deploy:

```bash
sinfo -h -p compute -o "%c %m"
```

Should print CPUs and memory-MB per node. If empty, the launcher falls back to `NEXTPYP_FALLBACK_CPUS` and `NEXTPYP_FALLBACK_MEM_MB` — set those to sensible values for your partition.
