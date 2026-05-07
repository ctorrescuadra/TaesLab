# Manual Wiki Sync Instructions

## Summary

This PR has created comprehensive mathematical equations documentation for the Exergy Cost Theory. The documentation includes:
- **14 display equations** showing key formulas
- **55 inline equations** with mathematical notation
- Complete coverage of unit consumption, matrix operators, cost calculations, and system metrics

## Files Created

### Main Repository (Committed and Pushed)
- ✅ `Docs/Exergy-Cost-Theory.md` - Complete equations documentation
- ✅ `Docs/WIKI_SYNC.md` - Wiki synchronization guide
- ✅ `README.md` - Updated with documentation links

### Wiki Repository (Prepared but Not Pushed)
The following files have been created in `/home/runner/work/TaesLab/TaesLab.wiki/` but require manual push:
- 📝 `Exergy-Cost-Theory.md` - Wiki version (ready to push)
- 📝 `Home.md` - Updated with new documentation link (ready to push)

## To Complete the Wiki Sync

Since the automated process cannot push to the GitHub wiki repository, please complete these steps manually:

### Option 1: Using the Prepared Files

1. Navigate to the wiki repository directory:
   ```bash
   cd /home/runner/work/TaesLab/TaesLab.wiki
   ```

2. Verify the staged changes:
   ```bash
   git status
   # Should show:
   # - new file:   Exergy-Cost-Theory.md
   # - modified:   Home.md
   ```

3. Commit and push:
   ```bash
   git commit -m "Add Exergy Cost Theory equations page with comprehensive mathematical formulas"
   git push origin master
   ```

### Option 2: Using the Main Repository Files

Alternatively, you can sync from the main repository:

1. Clone the wiki if not already cloned:
   ```bash
   git clone https://github.com/ctorrescuadra/TaesLab.wiki.git
   ```

2. Copy files from main repository:
   ```bash
   cp Docs/Exergy-Cost-Theory.md TaesLab.wiki/
   ```

3. Update the wiki Home.md to add the link (see the prepared version for reference)

4. Commit and push:
   ```bash
   cd TaesLab.wiki
   git add .
   git commit -m "Add Exergy Cost Theory equations documentation"
   git push origin master
   ```

## Verification

After pushing to the wiki, verify that:

1. The [Wiki Home page](https://github.com/ctorrescuadra/TaesLab/wiki) shows the new documentation link
2. The [Exergy Cost Theory page](https://github.com/ctorrescuadra/TaesLab/wiki/Exergy-Cost-Theory) renders correctly
3. All LaTeX equations display properly with MathJax
4. Cross-references to M-Matrix page work correctly

## Equation Samples

The documentation includes equations like:

**Unit Consumption:**
```latex
$$k_p = \frac{F_p}{P_p}$$
```

**Process Operator:**
```latex
$$\mathbf{P} = (\mathbf{I} - \mathbf{K}_P)^{-1}$$
```

**Total Product Cost:**
```latex
$$\mathbf{C}_P = \mathbf{C}^E_P + \mathbf{C}^Z_P + \mathbf{C}^R_P$$
```

## Next Steps

1. ✅ Main repository documentation is complete and pushed
2. 📋 Manual wiki push required (see instructions above)
3. 📋 Verify equations render correctly on wiki
4. 📋 Consider adding example calculations or figures in future updates

## Reference

- Main documentation: [Docs/Exergy-Cost-Theory.md](Docs/Exergy-Cost-Theory.md)
- Sync guide: [Docs/WIKI_SYNC.md](Docs/WIKI_SYNC.md)
- Implementation: `Classes/cExergyCost.m`
- Analysis function: `Base/ThermoeconomicAnalysis.m`
