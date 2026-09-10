# DEPLOYMENT

Full deployment guide with topology variations.

## Standard OOD + Slurm + shared FS

The default setup [QUICKSTART.md](../QUICKSTART.md) covers. Recap:

1. Install NextPYP containers under `NEXTPYP_INSTALL` on a shared filesystem.
2. Edit `ood-app/template/env`.
3. Edit `ood-app/form.yml`'s `cluster:` field.
4. Rsync `ood-app/` to `/var/www/ood/apps/sys/bc_nextpyp_desktop/`.

## OOD cluster config

Your `/etc/ood/config/clusters.d/<name>.yml` must have a `batch_connect` block for `vnc`:

```yaml
v2:
  metadata:
    title: "My Cluster"
  login:
    host: "portal.example.org"
  job:
    adapter: "slurm"
    cluster: "my-cluster"
    bin: "/usr/bin"
  batch_connect:
    vnc:
      script_wrapper: |
        module purge
        %s
      set_host: "host=$(hostname -A | awk '{print $1}')"
```

## Where user data goes

`NEXTPYP_HOME` (default `$HOME/nextpyp`) needs to be on a filesystem visible to every compute node. Common patterns:

| Site layout | `NEXTPYP_HOME` |
|---|---|
| NFS home dirs mounted everywhere | `$HOME/nextpyp` (default — no change) |
| Home dirs are local to portal only | Point at a shared scratch mount, e.g. `/scratch/$USER/nextpyp` |
| Multi-tenant shared project spaces | `/projects/$USER/nextpyp` |

## Bind mounts

`NEXTPYP_BIND_MOUNTS` is the list of host paths NextPYP jobs need read/write access to inside the container. Comma-separated. Typical:

```
NEXTPYP_BIND_MOUNTS=/scratch,/data,/projects
```

Anything users store raw movies in, and any writable output area.

## Multiple partitions

Edit `ood-app/form.yml` to expose partition as a dropdown:

```yaml
bc_queue:
  widget: select
  label: "Partition"
  options:
    - ["General compute", "compute"]
    - ["Big memory", "himem"]
    - ["GPU (unused for NextPYP)", "gpu"]
```

The launcher will use `bc_queue` at submit time and query `sinfo` for that partition at runtime.

## Updates

```bash
cd nextpyp-ood-interactive
git pull
sudo rsync -a --exclude env.example ood-app/ /var/www/ood/apps/sys/bc_nextpyp_desktop/
```

Your local `env` isn't overwritten because it's excluded.
