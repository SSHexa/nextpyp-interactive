# nextpyp-ood-interactive

Browser-native launcher for [NextPYP](https://nextpyp.app/) as an Open OnDemand Interactive App.

Users click **Launch** in their OOD dashboard and land in a full XFCE desktop with NextPYP already running — no SSH, no manual container launch, no config editing.

## What this repo adds on top of upstream NextPYP

- **Runs behind an OOD dashboard button.** One-click launch, per-user session, browser-only workflow.
- **Cross-node Slurm jobs work.** Upstream binds the web server to `127.0.0.1`, so processing jobs spawned on other Slurm nodes can't call back. This launcher binds to the node's routable IP.
- **VM-size aware.** Slurm `cpusPerTask` / `memoryPerCpuGB` are queried from `sinfo` at every session launch, so resizing your compute nodes needs no config change.
- **Persistent per-user data.** Projects and jobs survive OOD session delete.
- **VNC + Firefox pre-configured.** Passwordless VNC via `-securitytypes None`, software WebGL via Mesa llvmpipe for NextPYP's plot / gallery / tilt-series viewers.

## Prerequisites

- Open OnDemand ≥ 3.0
- Slurm (any recent version)
- Apptainer or Singularity on every compute node
- A shared filesystem across the OOD portal and Slurm compute nodes (NFS, Lustre, BeeGFS, etc.)
- NextPYP containers (`nextPYP.sif` + `pyp.sif`) — download from [nextpyp.app](https://nextpyp.app/)

## Install (5 min)

```bash
git clone https://github.com/SSHexa/nextpyp-interactive
cd nextpyp-ood-interactive

# Configure for your site
cp ood-app/template/env.example ood-app/template/env
$EDITOR ood-app/template/env    # at minimum set NEXTPYP_INSTALL

# Sanity check
bash scripts/check-prereqs.sh

# Deploy
sudo rsync -a --exclude env.example ood-app/ /var/www/ood/apps/sys/bc_nextpyp_desktop/
```

Then reload OOD and the **NextPYP Desktop** tile appears under Interactive Apps.

## Docs

- [QUICKSTART.md](QUICKSTART.md) — 15-min happy path
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — full install with variations
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) — every env var
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the launcher works
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — common issues
- [docs/CYCLECLOUD.md](docs/CYCLECLOUD.md) — optional dual-filesystem mode

## License

MIT. See [LICENSE](LICENSE).

Upstream NextPYP is a product of the Bartesaghi lab at Duke University and carries its own license — see nextpyp.app.
