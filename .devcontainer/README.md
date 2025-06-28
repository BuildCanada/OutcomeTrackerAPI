# Dev Container Documentation

This project includes a complete dev container setup for consistent development environments.

## What's Included

- **Ruby 3.4.4**: Matches the project's Ruby version
- **PostgreSQL 16**: Database server in a separate container
- **VS Code Extensions**: Ruby LSP, GitHub Copilot, and other useful extensions
- **Development Tools**: Git, GitHub CLI, build tools
- **Auto Setup**: Database creation, migration, and seeding

## Getting Started

1. **Install Prerequisites**:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Open in Dev Container**:
   - Open the project in VS Code
   - Click "Reopen in Container" when prompted
   - Or use Command Palette: "Dev Containers: Reopen in Container"

3. **Wait for Setup**: The first build takes a few minutes

## Common Commands

Once inside the dev container, you can use these commands:

```bash
# Start the Rails server
rails server

# Database operations
rails db:migrate
rails db:seed
rails db:reset

# Run tests
rails test

# Rails console
rails console

# Helper script for common tasks
.devcontainer/dev-helper.sh reset    # Reset database
.devcontainer/dev-helper.sh server   # Start server
.devcontainer/dev-helper.sh console  # Rails console
```

## Port Forwarding

The following ports are automatically forwarded:
- **3000**: Rails application server
- **5432**: PostgreSQL database

## Database Connection

From within the dev container:
- **Host**: `db`
- **Database**: `outcome_tracker_api_development`
- **Username**: `postgres`
- **Password**: `postgres`

From your local machine:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `outcome_tracker_api_development`
- **Username**: `postgres`
- **Password**: `postgres`

## Environment Variables

The dev container automatically sets:
- `DATABASE_URL`: Points to the PostgreSQL container
- `POSTGRES_USER`: postgres
- `POSTGRES_PASSWORD`: postgres
- `POSTGRES_DB`: outcome_tracker_api_development

## Troubleshooting

### Container Won't Start
- Ensure Docker Desktop is running
- Try rebuilding: Command Palette → "Dev Containers: Rebuild Container"

### Database Connection Issues
- Check if the database container is running: `docker ps`
- Restart the containers: "Dev Containers: Rebuild Container"

### Slow Performance
- Ensure you have enough resources allocated to Docker Desktop
- Consider enabling file system caching in Docker settings

### Port Already in Use
- Check if you have local services running on ports 3000 or 5432
- Stop local PostgreSQL: `brew services stop postgresql` (on macOS)

## Customization

To modify the dev container:
1. Edit `.devcontainer/devcontainer.json` for VS Code settings
2. Edit `.devcontainer/Dockerfile` for system dependencies
3. Edit `.devcontainer/docker-compose.yml` for service configuration
4. Rebuild the container after changes

## Benefits

- ✅ **Consistency**: Same environment for all developers
- ✅ **Isolation**: No conflicts with local setup
- ✅ **Zero Configuration**: Everything pre-configured
- ✅ **Fast Onboarding**: New developers can start immediately
- ✅ **Reproducible**: Exact same setup every time
