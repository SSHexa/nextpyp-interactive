# TROUBLESHOOTING

Common issues, organised by symptom.

## Session starts but Firefox shows a blank page or connection refused

**Root cause:** the web server isn't reachable at `NODE_IP:PORT`.

Check:

1. Read the OOD session log (visible under **My Interactive Sessions**). Look for the line `NextPYP web bind: <ip>`. That's what the launcher chose.
2. From another node in the cluster, `curl http://<ip>:<port>/`. If it fails, the IP the launcher picked isn't reachable from other nodes.

**Fix:** set `NEXTPYP_BIND_IP` explicitly in `ood-app/template/env`. Pick the address on the interface your Slurm compute nodes share.

## Processing job on another compute node fails with "Connection refused"

**Root cause:** upstream NextPYP historically bound the web server to `127.0.0.1`. This launcher fixes that by binding to a routable IP. If you still hit the error, verify the running `config.toml`:

```bash
cat $NEXTPYP_HOME/exec/config.toml
```

The `[web] host = "..."` line should be an IP other nodes can reach. If it's `127.0.0.1`, either `NEXTPYP_BIND_IP` is set to `127.0.0.1` or the auto-detect failed on this node. Unset `NEXTPYP_BIND_IP` (or set a real IP) and relaunch.

## OOM kills / worker terminated

**Root cause:** NextPYP jobs are asking Slurm for more parallelism than the node has memory for.

Check what the launcher requested:

```bash
grep 'Slurm sizing' <session-log>
```

If `memPerCpuGB` looks low, either lower `cpusPerTask` in NextPYP's Slurm settings, or reduce split threads in the block being processed.

## Disk full errors in scratch

**Root cause:** NextPYP writes large temp files. This launcher points scratch at `/tmp/nextpyp_scratch` (node-local), so it's per-job and cleaned by Slurm epilogs.

**Fix:** ensure your compute nodes have enough `/tmp` for CSP-scale intermediates (rough rule: 10 GB per active tilt series).

## joblib / loky semaphore errors on NFS

**Root cause:** Python `joblib`/`loky` create POSIX semaphores. Some NFS setups don't support them properly. This launcher uses `/tmp` for scratch (node-local, fully POSIX), which incidentally avoids this class of error.

If you still see it, the semaphore is coming from a different code path — export inside the container:

```
JOBLIB_TEMP_FOLDER=/tmp
LOKY_PICKLED_MAIN_PATH=/tmp
```

## Firefox opens but plots/gallery/tilt-series viewers don't render

**Root cause:** WebGL failing under TurboVNC (no GPU).

The launcher already sets `LIBGL_ALWAYS_SOFTWARE=1`, `GALLIUM_DRIVER=llvmpipe`, and the required `webgl.*` Firefox prefs. If you still see a blank plot area, check that `firefox-esr` or `firefox` is actually installed on the compute node:

```bash
which firefox-esr firefox
```

## Sizing doesn't match my node

**Root cause:** `sinfo` returned nothing for your partition, and the fallback values are off.

Set both:

```
NEXTPYP_FALLBACK_CPUS=16
NEXTPYP_FALLBACK_MEM_MB=32000
```

to match your real compute node. Better: fix `sinfo` visibility.

## Screen locks in the middle of a run

**Root cause:** XFCE screensaver / power manager kicking in.

This launcher already disables both via `xfconf-query` and autostart `Hidden` entries. If you still see it, check that `xfce4-screensaver` and `xfce4-power-manager` aren't being re-enabled by your site's XFCE profile.

## App doesn't appear on the OOD dashboard

- Check the app directory exists and is readable: `ls /var/www/ood/apps/sys/bc_nextpyp_desktop/`
- Check `manifest.yml` is valid YAML: `ruby -ryaml -e 'YAML.load_file "/var/www/ood/apps/sys/bc_nextpyp_desktop/manifest.yml"'`
- Reload OOD: `sudo systemctl reload httpd` (or `apache2`)
