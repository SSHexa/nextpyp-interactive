# CycleCloud (optional, advanced)

**You probably don't need this.** Skip unless you're running Azure CycleCloud with the specific dual-filesystem topology described below.

## When this mode applies

Standard sites have one shared filesystem visible on every compute node. Azure CycleCloud sometimes runs a two-filesystem setup:

- The OOD portal exports its `/shared` (503 GB local disk) to compute nodes over NFS, mounted on those nodes as `/sched-shared`.
- CycleCloud's own scheduler VM has a smaller `/shared` (100 GB) auto-mounted on compute.
- Projects live on OOD's `/shared`, so compute nodes need `/sched-shared` visible to their containers.

Symptom that tells you you're in this mode: your Slurm compute nodes have a `/sched-shared` mount pointing at the OOD portal's data, and NextPYP jobs can't find input files even though they exist on the portal.

## Enabling

In `ood-app/template/env`:

```
CLUSTER_MODE=cyclecloud
```

That's it. When `CLUSTER_MODE=cyclecloud`, the launcher:

1. Adds `--bind /sched-shared:/sched-shared` to every `apptainer exec` call.
2. Adds `/sched-shared` to the `[pyp] binds` array in the generated `config.toml`.

Everything else in this repo works exactly the same. Every path in the required install path still comes from `NEXTPYP_INSTALL`, `NEXTPYP_HOME`, etc. — CycleCloud mode only adds the extra bind; it does not change any default path to a CC-specific location.

## Example CycleCloud-shaped `env`

```
NEXTPYP_INSTALL=/sched-shared/apps/nextpyp
NEXTPYP_HOME=/sched-shared/home/$USER/nextpyp
NEXTPYP_PARTITION=htc
NEXTPYP_BIND_MOUNTS=/shared,/scratch
CLUSTER_MODE=cyclecloud
```

## Not sure? Just try generic

If you're not certain your cluster is dual-filesystem, leave `CLUSTER_MODE=generic`. If NextPYP jobs fail with "input file not found" and the same file exists on the portal, then look here.
