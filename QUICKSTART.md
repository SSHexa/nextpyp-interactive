# QUICKSTART

15-minute path from clone to a working **NextPYP Desktop** tile on your OOD dashboard.

Assumes you already have:

- Open OnDemand ≥ 3.0 running on a portal host
- A Slurm cluster with at least one compute partition
- Apptainer (or Singularity) on every compute node
- A shared filesystem visible to portal + compute
- Both NextPYP containers on that filesystem (`nextPYP.sif` and `pyp.sif`)

## 1. Get NextPYP itself in place

From [nextpyp.app](https://nextpyp.app/), obtain:

- `nextPYP.sif` (web/MicroMon container, ~1 GB)
- `sharedExec/containers/pyp.sif` (processing container, ~25 GB)
- The `templates/`, `workflows/`, and `nextpyp-host-processor` files

Put them under a single directory, e.g. `/opt/nextpyp/`:

```
/opt/nextpyp/
├── nextPYP.sif
├── nextpyp-host-processor
├── templates/default.peb
├── workflows/
└── sharedExec/containers/pyp.sif
```

## 2. Clone this repo

```bash
git clone https://github.com/SSHexa/nextpyp-interactive
cd nextpyp-ood-interactive
```

## 3. Configure

```bash
cp ood-app/template/env.example ood-app/template/env
$EDITOR ood-app/template/env
```

At minimum set:

- `NEXTPYP_INSTALL=/opt/nextpyp` (or wherever you put the containers)
- `NEXTPYP_PARTITION=compute` (your Slurm partition name)

The rest have sensible defaults.

## 4. Sanity check

```bash
bash scripts/check-prereqs.sh
```

Should print all-green. If something's missing it tells you what.

## 5. Set the OOD cluster name

Edit `ood-app/form.yml` and set `cluster:` to the name of your OOD cluster
config (the base filename in `/etc/ood/config/clusters.d/`). For a cluster
config file `slurm.yml`, use `cluster: "slurm"`.

## 6. Deploy

```bash
sudo mkdir -p /var/www/ood/apps/sys/bc_nextpyp_desktop
sudo rsync -a --exclude env.example ood-app/ /var/www/ood/apps/sys/bc_nextpyp_desktop/
sudo chown -R root:root /var/www/ood/apps/sys/bc_nextpyp_desktop
```

## 7. Launch

- Reload your OOD dashboard
- Under **Interactive Apps** → **Cryo-EM** → **NextPYP Desktop**
- Pick wall time and click **Launch**
- Wait for **Running** → click the noVNC button
- Firefox opens to `http://<node-ip>:<port>/` automatically

If it doesn't come up, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).
