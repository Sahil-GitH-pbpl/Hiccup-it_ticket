# Shared Users

Both modules use `hiccup_ticket.users` (the Hiccup `DB_NAME`). Asset models
qualify this schema explicitly through the asset MySQL connection, so both
databases must be on the same MySQL server and its account must have access.

Asset permissions are stored on the common user row:

| role_id | role | Asset role |
| --- | --- | --- |
| 1 | administrator | Administrator |
| 2 | technician | Technician |
| 3 | asset_manager | Asset Manager |
| 7 | employee | Employee |

Use Asset Management's Users page to update roles; it updates both fields in
one transaction. Manual DB updates must also keep both fields consistent.
Invalid combinations fail closed. Both bearer and Hiccup cookie authentication
read current role/status from the common DB; no user copy or reactivation occurs.
Hiccup/Infra privileges retain their own allowlists/designation rules and do not
inherit the asset role. Hiccup login emits the legacy staff role for asset roles.

## Deployment

1. Build the updated image and run `python -m scripts.migrate_shared_asset_users`
   with production DB settings before starting the new backend. This adds
   `role_id`, backs up previous assignments in `users_roles_before_shared_assets`,
   preserves existing asset assignments, initializes Hiccup admin IDs 124/125
   as Administrator and Infra admin ID 95 as Asset Manager, and defaults other
   legacy users to Employee. Reruns do not overwrite migrated assignments.
2. Switch backend and verify login, asset role management and inactive access.
3. Run `python -m scripts.migrate_shared_asset_users --archive-asset-users`.
   The old asset table is retained as `users_before_shared_assets`; the original
   `asset_management.users` name becomes a view of the common table.

Do not import `db/asset_management.sql` over a deployed shared-user system;
that historical dump contains the former standalone users table.
