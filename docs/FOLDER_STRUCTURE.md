# Project Folder Structure

The tree below reflects the current repository layout (paths are relative to the repo root `federated_learning_secure_implementation/`).

```txt
.
├── docs/
│   ├── FOLDER_STRUCTURE.md
│   ├── how_to_run.md
│   ├── how_to_stop.md
│   ├── bug_fix_docs/
│   │   └── bug_1/
│   │       └── phase_1.1_fix_tls_handshake_and_certifcate_issues.md
│   ├── important_infos/
│   │   ├── high_level_development_plan.md
│   │   ├── important_information.md
│   │   ├── port_mapping.md
│   │   └── services_roles.md
│   ├── project_completion_tracker/
│   │   └── 1_overall_project_completion.md
│   └── project_instruction/
│       ├── phase-1-secure-flower-locally/
│       │   ├── phase_0_certificate_gen_instruction.md
│       │   ├── phase_1_update_toml_file_for_secure_deployment.md
│       │   ├── phase_1.1_secure_flower_simulation_superlink_tls.md
│       │   ├── phase_1.2_configure_and_launch supernode_securely.md
│       │   └── phase_1.3_enable_supernode_authentication.md
│       └── phase-2-/
├── flower-secure-fl/
│   ├── certificates/
│   │   ├── ca/              # Root CA certificate + key (ca.crt, ca.key, ca.srl)
│   │   ├── superlink/       # TLS materials for the SuperLink
│   │   │   ├── superlink.crt
│   │   │   ├── superlink.csr
│   │   │   ├── superlink.key
│   │   │   └── trusted_supernodes.csv
│   │   └── supernodes/      # Placeholder for node-specific cert/key pairs
│   ├── keys/                # Supernode authentication and encryption keys
│   │   ├── supernode1_auth
│   │   ├── supernode1_auth.pub
│   │   ├── supernode1_pkcs8.key
│   │   ├── supernode1_ssh.pub
│   │   ├── supernode1.key
│   │   ├── supernode1.pub
│   │   ├── supernode2_auth
│   │   ├── supernode2_auth.pub
│   │   ├── supernode2_pkcs8.key
│   │   ├── supernode2_ssh.pub
│   │   ├── supernode2.key
│   │   └── supernode2.pub
│   ├── flower_secure_fl/
│   │   ├── __init__.py
│   │   ├── client_app.py
│   │   ├── server_app.py
│   │   └── task.py
│   ├── final_model.pt
│   ├── pyproject.toml
│   ├── pyproject.toml.bak
│   ├── .gitignore
│   └── README.md
├── logs/                    # Directory for application logs
├── reference/               # Vendor documentation / reference material
├── scripts/
│   ├── certificate_gen.sh   # Helper script for generating TLS certificates
│   ├── run_secure_federation.sh  # Script to run secure federation
│   └── stop_secure_federation.sh # Script to stop secure federation
├── .git/
└── .gitignore
```

## Directory Highlights

- **docs/**: Comprehensive documentation organized by purpose:
  - **bug_fix_docs/**: Troubleshooting guides for specific issues encountered during development
  - **important_infos/**: High-level project information including development plans, port mappings, and service roles
  - **project_completion_tracker/**: Progress tracking and completion status documentation
  - **project_instruction/**: Step-by-step guides organized by project phases (Phase 1, Phase 2, etc.)
- **flower-secure-fl/**: The actual Flower application package. Run all CLI commands from here so relative paths like `./certificates/ca/ca.crt` work consistently.
  - **certificates/**: Holds the generated CA, SuperLink, and SuperNode credentials including trusted supernodes list
  - **keys/**: Supernode authentication and encryption keys for secure communication
  - **flower_secure_fl/**: Python package containing `server_app.py`, `client_app.py`, and shared logic (`task.py`)
- **logs/**: Directory for storing application runtime logs
- **scripts/**: Automation scripts including certificate generation, federation startup, and shutdown procedures
- **reference/**: External PDFs or manuals referenced during implementation

## Usage Guidelines

Use this structure as the authoritative reference when updating configuration paths (TOML, CLI flags, etc.) to avoid absolute-path issues. All documentation now assumes commands are executed inside `flower-secure-fl/` with the relative paths shown above.

## Key Components

- **SuperLink Certificate Files**: `superlink.crt`, `superlink.key`, `superlink.csr` for TLS authentication
- **Trusted Supernodes**: `trusted_supernodes.csv` maintains the list of authorized supernodes
- **Supernode Keys**: Individual key pairs for supernode1 and supernode2 including authentication and SSH keys
- **Automation Scripts**: Complete lifecycle management from certificate generation to federation startup and shutdown

This structure supports secure federated learning with proper authentication, encryption, and comprehensive documentation for all phases of deployment and operation.
