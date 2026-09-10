# ARCHITECTURE

How a NextPYP Desktop session comes up, end to end.

## Flow

```
   User's browser
        │
        ▼
   OOD Portal (Apache + mod_ood)
        │  (batch_connect → sbatch)
        ▼
   Slurm scheduler
        │
        ▼
   Compute node (allocated for the session)
   ┌────────────────────────────────────────────────┐
   │  script.sh.erb runs here                       │
   │                                                │
   │  ┌────────────┐  ┌──────────────────────┐      │
   │  │ TurboVNC   │  │ Host processor       │      │
   │  │  + XFCE    │  │ (outside container)  │      │
   │  └──────┬─────┘  └──────────┬───────────┘      │
   │         │                   │                  │
   │  ┌──────▼───────┐  ┌────────▼───────────┐      │
   │  │ Firefox      │  │ nextPYP.sif        │      │
   │  │ (autostart)  │──│  MicroMon web UI   │      │
   │  └──────────────┘  │  Listens on        │      │
   │                    │  NODE_IP:PORT      │      │
   │                    └────────┬───────────┘      │
   └─────────────────────────────┼──────────────────┘
                                 │
                     (submits Slurm jobs)
                                 │
                                 ▼
                       Other compute nodes
                       ┌──────────────────┐
                       │ pyp.sif          │
                       │ (processing:     │
                       │  MotionCor, CTF, │
                       │  particle pick,  │
                       │  refine, etc.)   │
                       │                  │
                       │ Calls back to    │
                       │ NODE_IP:PORT     │
                       └──────────────────┘
```

## Why the design is shaped this way

- **VNC + Firefox**, not a plain HTTP proxy: NextPYP's UI expects local file dialogs, drag-drop, and WebGL viewers. Wrapping the full desktop is simpler than proxying every WebSocket and file dialog through OOD.
- **`NODE_IP` bind instead of `127.0.0.1`**: upstream NextPYP binds the web server to `127.0.0.1` and hardcodes that into every batch script. Processing jobs on other Slurm nodes then cannot call back. This launcher binds to the routable IP of the desktop's node.
- **Per-session `config.toml`**: because the node the desktop lands on changes every session, `config.toml` is regenerated on every launch with the live IP and port.
- **Two containers, not one**: `nextPYP.sif` is the web UI; `pyp.sif` is the processing binary suite. Slurm jobs launch `pyp.sif` on remote nodes, which is why `sharedExec/containers/pyp.sif` must be on a filesystem visible everywhere.
- **Persistent user data outside session dir**: OOD deletes the session directory when a session ends. Putting projects and jobs under `$NEXTPYP_HOME` keeps them across sessions.

## File layout at runtime

```
$NEXTPYP_HOME/
├── local/          # database, logs, sockets
│   ├── db/
│   ├── logs/
│   │   ├── hostprocessor
│   │   └── container.log
│   └── sock/
├── shared/         # projects, jobs, user data
│   ├── batch/
│   ├── users/
│   ├── sessions/
│   └── ...
└── exec/           # config + container symlinks
    ├── config.toml
    ├── nextPYP.sif -> $NEXTPYP_INSTALL/nextPYP.sif
    └── containers/
        └── pyp.sif -> $NEXTPYP_INSTALL/sharedExec/containers/pyp.sif
```
