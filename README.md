# Internal Staff System – Hiccup Module (V1.0)

FastAPI + MySQL implementation of the pathology lab hiccup logging workflow with HTML/JS frontend served by FastAPI.

## Running locally

1. (Optional) create venv in ./venv and activate.
2. Install dependencies: `pip install -r requirements`.
3. Start API with reload: `uvicorn main:app --reload --port 7410`.
4. Open `http://localhost:7410/login`.

### Project layout
- `logs/` and `uploads/` are bind-mounted inside Docker and kept in-repo with `.gitkeep` placeholders.
- `venv/` is an optional local virtual environment location so the expected folder structure is present from the outset.

## Docker

```bash
docker-compose up --build
```

The backend listens on port 7410 and persists uploads/logs via bind mounts.

## Publishing to GitHub (configured for hiccup-system)

This workspace is already pointed at the repository provided (`https://github.com/Sahil-GitH-pbpl/hiccup-system.git`) via the `origin` remote. To publish:

1. Ensure you have GitHub credentials available in this environment (personal access token or SSH keys) **and that outbound GitHub access is allowed**. The current sandbox blocks outbound pushes (HTTP 403 on CONNECT), so perform the push from a machine with access if you see similar errors.
2. Push the current branch (default is `work`) to GitHub:
   ```bash
   git push -u origin work
   ```
3. If you want the branch to be `main` on GitHub, push with:
   ```bash
   git push -u origin work:main
   ```
4. If authentication or connectivity from this environment is blocked, clone the repository locally where you have access:
   ```bash
   git clone https://github.com/Sahil-GitH-pbpl/hiccup-system.git
   cd hiccup-system
   git remote add source /workspace/inventory-management-system
   git pull source work
   git push -u origin main
   ```

These steps keep the current history intact while publishing to the new GitHub repository you specified.
