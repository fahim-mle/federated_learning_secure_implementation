# Project Folder Structure

The tree below reflects the current repository layout (paths are relative to the repo root `federated_learning_secure_implementation/`).

```txt
.
├── docs/
│   ├── FOLDER_STRUCTURE.md
│   ├── how_to_run.md
│   ├── phase_0_certificate_gen_instruction.md
│   ├── phase_1_update_toml_file_for_secure_deployment.md
│   ├── phase_1.1_secure_flower_simulation_superlink_tls.md
│   ├── phase_1.2_configure_and_launch supernode_securely.md
│   └── bug_fix_docs/
│       └── bug_1/
│           └── phase_1.1_fix_tls_handshake_and_certifcate_issues.md
├── flower-secure-fl/
│   ├── certificates/
│   │   ├── ca/              # Root CA certificate + key (ca.crt, ca.key, ca.srl)
│   │   ├── superlink/       # TLS materials for the SuperLink
│   │   └── supernodes/      # Placeholder for node-specific cert/key pairs
│   ├── flower_secure_fl/
│   │   ├── __init__.py
│   │   ├── client_app.py
│   │   ├── server_app.py
│   │   └── task.py
│   ├── final_model.pt
│   ├── pyproject.toml
│   ├── pyproject.toml.bak
│   └── README.md
├── reference/
│   └── FL_FLWR_OPS (1).pdf  # Vendor documentation / reference material
├── scripts/
│   └── certificate_gen.sh   # Helper script for generating TLS certificates
├── .venv/                   # Workspace-level virtual environment (Python 3.12)
├── .git/
└── .gitignore
```

## Directory Highlights

- **docs/**: Living documentation for each project phase plus troubleshooting notes (`bug_fix_docs/`). Use these guides when configuring TLS, SuperLink, or SuperNodes.
- **flower-secure-fl/**: The actual Flower application package. Run all CLI commands from here so relative paths like `./certificates/ca/ca.crt` work consistently.
  - **certificates/**: Holds the generated CA, SuperLink, and SuperNode credentials.
  - **flower_secure_fl/**: Python package containing `server_app.py`, `client_app.py`, and shared logic (`task.py`).
- **scripts/**: Utility scripts such as `certificate_gen.sh` to automate certificate creation.
- **reference/**: External PDFs or manuals referenced during implementation.
- **.venv/**: Project-wide virtual environment. Activate it (or prefix commands with `./.venv/bin/`) before running Flower CLIs.

Use this structure as the authoritative reference when updating configuration paths (TOML, CLI flags, etc.) to avoid absolute-path issues. All documentation now assumes commands are executed inside `flower-secure-fl/` with the relative paths shown above.
