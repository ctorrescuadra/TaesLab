# Wiki Sidebar Management

This directory contains the sidebar configuration for the TaesLab GitHub Wiki.

## Files

- `_Sidebar.md` - Defines the navigation menu and page order for the wiki
- `deploy-sidebar.sh` - Automated deployment script
- `README.md` - This file

## Deploying to Wiki

### Automated Deployment (Recommended)

Run the deployment script from the repository root:

```bash
./Wiki/deploy-sidebar.sh
```

This script will automatically clone (or update) the wiki repository, copy the sidebar, and push the changes.

### Manual Deployment

If you prefer to deploy manually:

1. Clone the wiki repository:
   ```bash
   git clone https://github.com/ctorrescuadra/TaesLab.wiki.git
   ```

2. Copy the `_Sidebar.md` file to the wiki repository:
   ```bash
   cp Wiki/_Sidebar.md TaesLab.wiki/_Sidebar.md
   ```

3. Commit and push the changes:
   ```bash
   cd TaesLab.wiki
   git add _Sidebar.md
   git commit -m "Update sidebar"
   git push origin master
   ```

## Page Order

The current page order in the sidebar is:

1. **Home** - Introduction to TaesLab
2. **System Architecture** - Comprehensive technical documentation
3. **M-Matrix** - Mathematical characterization documentation

To modify the page order, edit the `_Sidebar.md` file in this directory and follow the deployment steps above.
