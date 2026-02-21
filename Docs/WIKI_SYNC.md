# Wiki Synchronization Guide

This document explains how to synchronize documentation between the main repository's `Docs/` folder and the GitHub Wiki.

## Files to Sync

The following documentation files should be kept synchronized with the GitHub Wiki:

1. **Exergy-Cost-Theory.md** - Mathematical foundations and equations for thermoeconomic analysis
2. **M-Matrix.md** - Mathematical characterization of M-matrices and convergence theory
3. **overview.md** (maps to **System-Arquitecture.md** in wiki) - TaesLab architecture overview

## Syncing Process

### Manual Sync (Current Method)

1. Clone the wiki repository:
   ```bash
   git clone https://github.com/ctorrescuadra/TaesLab.wiki.git
   ```

2. Copy updated files from `Docs/` to the wiki:
   ```bash
   cp Docs/Exergy-Cost-Theory.md TaesLab.wiki/
   cp Docs/M-Matrix.md TaesLab.wiki/
   ```

3. Commit and push to the wiki:
   ```bash
   cd TaesLab.wiki
   git add .
   git commit -m "Update documentation from main repository"
   git push origin master
   ```

### File Naming Conventions

- Main repo uses lowercase with hyphens: `exergy-cost-theory.md`
- Wiki uses PascalCase with hyphens: `Exergy-Cost-Theory.md`
- Ensure consistent naming when syncing

### Cross-References

When linking between wiki pages:
- In wiki: Use `[M-Matrix](M-Matrix)` format
- In main repo: Use `[M-Matrix](M-Matrix.md)` format

## Equation Formatting

All mathematical equations use LaTeX syntax with dollar sign delimiters:

- **Inline equations**: `$x = y + z$`
- **Display equations**: `$$x = y + z$$`

GitHub's wiki and markdown preview both support this syntax using MathJax rendering.

## Maintenance Notes

- Always update the main repository's `Docs/` folder first
- Then sync changes to the wiki
- Keep the `Home.md` in the wiki updated with links to new pages
- Test equation rendering in both locations

## Recent Updates

- **2026-02-15**: Added Exergy-Cost-Theory.md with comprehensive mathematical formulas
  - Unit consumption and efficiency equations
  - Matrix operator definitions (flow and process operators)
  - Cost calculation formulas (direct, generalized, and unit costs)
  - System-level metrics and irreversibility cost formation
  - Updated Home.md to link to new equations page
