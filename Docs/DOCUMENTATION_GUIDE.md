# TaesLab Documentation Generation Guide

This guide explains how to create and maintain documentation for the TaesLab toolbox using inline documentation and the utilities in `Docs/Utilities`.

## Table of Contents

1. [Overview](#overview)
2. [Inline Documentation Standards](#inline-documentation-standards)
3. [Documentation Utilities](#documentation-utilities)
4. [Workflow for Generating Documentation](#workflow-for-generating-documentation)
5. [File Formats and Export Options](#file-formats-and-export-options)
6. [Examples](#examples)

---

## Overview

TaesLab uses a **two-level documentation system**:

1. **Inline documentation** - MATLAB help comments in `.m` files (H1 lines and detailed help)
2. **Automated extraction** - Utilities that read inline docs and generate formatted documentation

The documentation workflow is:

```
Inline Docs  Utilities  Structured JSON  Formatted Output
 (*.m files)   (extract)   (Contents.json)   (MD/PDF/HTML/LaTeX)
```

---

## Inline Documentation Standards

### Function Documentation Format

All functions must follow this structure:

```matlab
function output = FunctionName(input, varargin)
%FunctionName - Brief one-line description (H1 line).
%   Extended description providing context and purpose.
%   Additional details about what the function does.
%
%   Syntax:
%     output = FunctionName(input)
%     output = FunctionName(input, Name, Value)
%
%   Input Arguments:
%     input - Description of input parameter
%       data type | allowed values
%
%   Name-Value Arguments:
%     ParameterName - Description of parameter
%       allowed values (default: value)
%
%   Output Arguments:
%     output - Description of return value
%
%   Examples:
%     % Example 1: Basic usage
%     result = FunctionName('myfile.json');
%
%     % Example 2: With options
%     result = FunctionName('myfile.json', 'Debug', true);
%
%   See also RelatedFunction1, RelatedFunction2, RelatedClass
%
```

**Key Elements:**
- **H1 line**: `%FunctionName - Brief description` (used for Contents listings)
- **Syntax section**: Shows all valid calling patterns
- **Input/Output sections**: Type information and descriptions
- **Examples**: Practical usage demonstrations
- **See also**: Related functions/classes

### Class Documentation Format

```matlab
classdef cClassName < cParentClass
%cClassName - Brief one-line description.
%   Extended description of class purpose and functionality.
%   Additional context about when to use this class.
%
%   cClassName properties:
%     PropertyName1 - Brief property description
%     PropertyName2 - Brief property description
%
%   cClassName methods:
%     cClassName      - Constructor description
%     methodName1     - Method description
%     methodName2     - Method description
%
%   See also cRelatedClass1, cRelatedClass2
%
    properties (Access=public)
        PropertyName1  % Brief inline comment
        PropertyName2  % Brief inline comment
    end
    
    methods
        function obj = cClassName(input)
        %cClassName - Constructor description
        %   Detailed explanation of constructor.
        %
        %   Syntax:
        %     obj = cClassName(input)
        %
        %   Input Arguments:
        %     input - Description
        %
        %   Output Arguments:
        %     obj - cClassName object
        %
        end
    end
end
```

**Class Naming Convention**: All classes start with lowercase `c` prefix (e.g., `cDataModel`, `cExergyModel`)

---

## Documentation Utilities

The `Docs/Utilities/` folder contains tools for automated documentation generation:

### 1. `buildContents.m`

**Purpose**: Extract function/class descriptions from a folder

**Syntax**:
```matlab
tbl = buildContents()                    % Current folder
tbl = buildContents(folder)              % Specific folder
buildContents(folder, filename)          % Save to file
```

**Output**: `cTableData` object with Name and Description columns

**Example**:
```matlab
% Extract descriptions from Base folder
tbl = buildContents('Base');

% Save as different formats
buildContents('Base', 'Base_Functions.txt');
buildContents('Base', 'Base_Functions.xlsx');
buildContents('Base', 'Base_Functions.json');
buildContents('Base', 'Base_Functions.md');
```

### 2. `groupContents.m`

**Purpose**: Organize functions into groups using Excel template

**Syntax**:
```matlab
groupContents()                              % Use default Contents.xlsx
groupContents(inFile, outFile)               % Specify files
```

**Input**: `Contents.xlsx` with structure:
- **Index sheet**: Folder definitions (Name, Description, Content, Groups)
- **Content sheets**: Function listings with Group assignments
- **Groups sheets**: Group definitions (Id, Name, Description)

**Output**: `Contents.json` with hierarchical structure:
```json
{
  "FolderName": {
    "Name": "folder_name",
    "Description": "Folder description",
    "Groups": [
      {
        "Name": "group_name",
        "Description": "Group description",
        "Files": [
          {"Name": "FunctionName", "Description": "Function description"}
        ]
      }
    ]
  }
}
```

**Example**:
```matlab
% Generate Contents.json from Contents.xlsx
groupContents('Docs/Utilities/Contents.xlsx', 'Docs/Utilities/Contents.json');
```

### 3. `BuildDocuments.m`

**Purpose**: Generate formatted documentation from `Contents.json`

**Syntax**:
```matlab
[tables, log] = BuildDocuments(folder, filename)
```

**Input Arguments**:
- `folder` - Folder name from Contents.json (e.g., 'Base', 'Functions', 'Classes')
- `filename` - Output filename (extension determines format)

**Supported Formats**:
- `.mhlp` - MATLAB help format (Contents.m style)
- `.txt` - Plain text tables
- `.md` - Markdown tables
- `.tex` - LaTeX tables

**Example**:
```matlab
% Generate Markdown documentation for Base functions
BuildDocuments('Base', 'base_functions.md');

% Generate LaTeX documentation for Classes
BuildDocuments('Classes', 'classes_documentation.tex');

% Generate MATLAB help file
BuildDocuments('Functions', 'Contents.m');
```

### 4. `getClassInfo.m`

**Purpose**: Extract class properties and methods using metaclass introspection

**Syntax**:
```matlab
[res, tbl] = getClassInfo(className, info)
[res, tbl] = getClassInfo(className, info, filename)
```

**Input Arguments**:
- `className` - Name of the class (string or char)
- `info` - Type of information:
  - `cType.ClassInfo.PROPERTIES` - Public properties
  - `cType.ClassInfo.METHODS` - Public methods
- `filename` - (optional) File to save results

**Output**:
- `res` - `cTableData` object with extracted information
- `tbl` - MATLAB table with columns: Name, Description, DefiningClass, Access

**Example**:
```matlab
% Get properties of cThermoeconomicModel
[res, tbl] = getClassInfo('cThermoeconomicModel', cType.ClassInfo.PROPERTIES);

% Get methods and save to file
[res, tbl] = getClassInfo('cExergyModel', cType.ClassInfo.METHODS, 'cExergyModel_methods.txt');

% Print in console
getClassInfo('cDataModel', cType.ClassInfo.PROPERTIES);
```
---

## Workflow for Generating Documentation

### Complete Documentation Workflow

```

 1. Write inline docs in .m files                               
─
                     
                     
─
 2. Run buildContents on folder                                  
     Extracts H1 lines from all .m files                        

                     
                     

 3. Create/update Contents.xlsx                                  
     Organize functions into groups                             

                     
                     

 4. Run groupContents                                            
     Generates Contents.json with hierarchy                     
─
                     
                     
─
 5. Run BuildDocuments for each folder                           
     Generate formatted docs (MD/PDF/LaTeX/etc)                 
─
```

### Step-by-Step Process

#### Step 1: Write Inline Documentation

Ensure all `.m` files have proper H1 lines:

```matlab
function result = MyFunction(input)
%MyFunction - Brief description of what it does.
%   Extended description...
```

#### Step 2: Extract Function Descriptions

```matlab
% Navigate to project root
cd('c:/Users/ctorr/Documents/Proyectos/TaesLab')

% Extract descriptions from each folder
buildContents('Base', 'Docs/Utilities/base_contents.xlsx');
buildContents('Functions', 'Docs/Utilities/functions_contents.xlsx');
buildContents('Classes', 'Docs/Utilities/classes_contents.xlsx');
```

#### Step 3: Organize into Groups

1. Open `Docs/Utilities/Contents.xlsx`
2. **Index sheet**: Define folders
   ```
   | Name      | Description                  | Content        | Groups        |
   |-----------|------------------------------|----------------|---------------|
   | Base      | TaesLab Base Functions       | BaseContent    | BaseGroups    |
   | Functions | TaesLab Utility Functions    | FunctionsContent| FunctionsGroups|
   ```

3. **Content sheets**: Assign group numbers
   ```
   | Name           | Description              | Group |
   |----------------|--------------------------|-------|
   | ReadDataModel  | Reads a data model file  | 1     |
   | ExergyAnalysis | Get exergy analysis      | 2     |
   ```

4. **Groups sheets**: Define groups
   ```
   | Id | Name | Description                    |
   |----|------|--------------------------------|
   | 1  | rdmb | Read Data Models               |
   | 2  | trb  | Thermoeconomic Results         |
   ```

#### Step 4: Generate Contents.json

```matlab
cd('Docs/Utilities')
groupContents('Contents.xlsx', 'Contents.json');
```

#### Step 5: Generate Formatted Documentation

```matlab
% Generate documentation for each folder
BuildDocuments('Base', '../base_functions.md');
BuildDocuments('Functions', '../utility_functions.md');
BuildDocuments('Classes', '../classes_info.md');

% Generate MATLAB help files
BuildDocuments('Base', '../../Base/Contents.m');
BuildDocuments('Functions', '../../Functions/Contents.m');
```

#### Step 6: Generate Class Documentation

```matlab
% Extract class information
classes = {'cDataModel', 'cThermoeconomicModel', 'cExergyModel', ...
           'cExergyCost', 'cDiagnosis', 'cProductiveStructure'};

for i = 1:length(classes)
    className = classes{i};
    
    % Get properties
    filename = sprintf('Docs/%s_properties.md', className);
    getClassInfo(className, cType.ClassInfo.PROPERTIES, filename);
    
    % Get methods
    filename = sprintf('Docs/%s_methods.md', className);
    getClassInfo(className, cType.ClassInfo.METHODS, filename);
end
```

---

## File Formats and Export Options

### Supported Export Formats

| Extension | Format           | Use Case                              |
|-----------|------------------|---------------------------------------|
| `.mhlp`   | MATLAB Help      | Contents.m files for `help` command   |
| `.txt`    | Plain Text       | Simple readable format                |
| `.md`     | Markdown         | GitHub, documentation sites           |
| `.tex`    | LaTeX            | Academic papers, professional docs    |
| `.json`   | JSON             | Structured data, web applications     |
| `.xlsx`   | Excel            | Spreadsheet editing and organization  |
| `.csv`    | CSV              | Data interchange                      |
| `.html`   | HTML             | Web viewing                           |
| `.mat`    | MATLAB Data      | Native MATLAB storage                 |

### Format-Specific Features

#### MATLAB Help (.mhlp)
```matlab
BuildDocuments('Base', 'Contents.m');
```
Output format:
```matlab
%
% Read Data Models
%  ReadDataModel        - Reads a data model file.
%  ImportDataModel      - Get a cDataModel object from a previous saved MAT file.
%
```

#### Markdown (.md)
```matlab
BuildDocuments('Base', 'base_functions.md');
```
Output format:
```markdown
## Read Data Models

| Function | Description |
|----------|-------------|
| ReadDataModel | Reads a data model file. |
| ImportDataModel | Get a cDataModel object from a previous saved MAT file. |
```

#### LaTeX (.tex)
```matlab
BuildDocuments('Base', 'base_functions.tex');
```
Output includes formatted tables with LaTeX markup.

---

## Examples

### Example 1: Document New Base Function

1. **Write the function with proper inline docs**:

```matlab
function res = MyNewAnalysis(data, varargin)
%MyNewAnalysis - Perform custom thermoeconomic analysis.
%   This function analyzes the plant model and returns custom metrics.
%
%   Syntax:
%     res = MyNewAnalysis(data)
%     res = MyNewAnalysis(data, 'State', stateName)
%
%   Input Arguments:
%     data - cDataModel object containing plant data
%
%   Name-Value Arguments:
%     State - Name of the state to analyze (default: first state)
%
%   Output Arguments:
%     res - cResultInfo object with analysis results
%
%   Example:
%     data = ReadDataModel('rankine_model.json');
%     results = MyNewAnalysis(data, 'State', 'design');
%
%   See also ExergyAnalysis, ThermoeconomicAnalysis
%
    % Function implementation...
end
```

2. **Extract and update documentation**:

```matlab
% Re-extract Base folder contents
cd('Docs/Utilities')
buildContents('../../Base', 'base_temp.xlsx');

% Manually add to Contents.xlsx in appropriate group

% Regenerate Contents.json
groupContents('Contents.xlsx', 'Contents.json');

% Generate updated documentation
BuildDocuments('Base', '../base_functions.md');
BuildDocuments('Base', '../../Base/Contents.m');
```

### Example 2: Document New Class

1. **Write the class with inline docs**:

```matlab
classdef cMyAnalysis < cResultId
%cMyAnalysis - Custom analysis class for specific calculations.
%   This class performs specialized thermoeconomic analysis.
%
%   cMyAnalysis properties:
%     CustomMetric1 - First custom metric
%     CustomMetric2 - Second custom metric
%
%   cMyAnalysis methods:
%     cMyAnalysis     - Create instance
%     calculateMetric - Perform calculation
%
%   See also cExergyModel, cResultId
%
    properties (Access=public)
        CustomMetric1  % First custom metric value
        CustomMetric2  % Second custom metric value
    end
    
    methods
        function obj = cMyAnalysis(data)
        %cMyAnalysis - Constructor
        %   Creates analysis object from data model.
        %
        %   Syntax:
%     obj = cMyAnalysis(data)
        %
        %   Input Arguments:
        %     data - cExergyData object
        %
        %   Output Arguments:
        %     obj - cMyAnalysis object
        %
            % Constructor implementation...
        end
    end
end
```

2. **Generate class documentation**:

```matlab
% Extract properties
getClassInfo('cMyAnalysis', cType.ClassInfo.PROPERTIES, 'Docs/cMyAnalysis_properties.md');

% Extract methods
getClassInfo('cMyAnalysis', cType.ClassInfo.METHODS, 'Docs/cMyAnalysis_methods.md');

% Update Contents.xlsx and regenerate
cd('Docs/Utilities')
buildContents('../../Classes', 'classes_temp.xlsx');
% Add to Contents.xlsx manually
groupContents('Contents.xlsx', 'Contents.json');
BuildDocuments('Classes', '../classes_info.md');
```

### Example 3: Complete Documentation Update

```matlab
% Full documentation regeneration script
cd('c:/Users/ctorr/Documents/Proyectos/TaesLab/Docs/Utilities')

% Step 1: Extract all folder contents
buildContents('../../Base', 'base_extracted.xlsx');
buildContents('../../Functions', 'functions_extracted.xlsx');
buildContents('../../Classes', 'classes_extracted.xlsx');

% Step 2: Manually merge into Contents.xlsx and organize groups

% Step 3: Generate Contents.json
groupContents('Contents.xlsx', 'Contents.json');

% Step 4: Generate all documentation formats
folders = {'Base', 'Functions', 'Classes'};

for i = 1:length(folders)
    folder = folders{i};
    
    % Markdown for GitHub/Docs
    BuildDocuments(folder, sprintf('../%s_reference.md', lower(folder)));
    
    % MATLAB help files
    BuildDocuments(folder, sprintf('../../%s/Contents.m', folder));
    
    % LaTeX for papers
    BuildDocuments(folder, sprintf('../%s_reference.tex', lower(folder)));
end

% Step 5: Generate key class documentation
keyClasses = {'cDataModel', 'cThermoeconomicModel', 'cExergyModel', 'cExergyCost'};

for i = 1:length(keyClasses)
    cls = keyClasses{i};
    getClassInfo(cls, cType.ClassInfo.PROPERTIES, sprintf('../%s_properties.md', cls));
    getClassInfo(cls, cType.ClassInfo.METHODS, sprintf('../%s_methods.md', cls));
end

fprintf('Documentation generation complete!\n');
```

---

## Best Practices

### 1. Keep H1 Lines Concise
The H1 line appears in Contents listings:
```matlab
%FunctionName - Brief description (keep under 80 chars).
```

### 2. Use Consistent Terminology
- **Data model** - Input file representation
- **State** - Operating condition
- **Sample** - Cost configuration
- **Flow** - Energy stream
- **Process** - Component/operation

### 3. Include Examples
Every public function should have at least one example:
```matlab
%   Example:
%     data = ReadDataModel('rankine_model.json');
%     results = ExergyAnalysis(data);
```

### 4. Cross-Reference Related Items
Use "See also" section:
```matlab
%   See also ReadDataModel, cDataModel, ThermoeconomicAnalysis
```

### 5. Update Documentation Regularly
After adding/modifying functions:
1. Update inline docs
2. Re-run `buildContents`
3. Update `Contents.xlsx` groupings
4. Regenerate `Contents.json`
5. Rebuild formatted documentation

### 6. Validate Generated Files
After running `BuildDocuments`:
- Check that all functions are listed
- Verify group organization makes sense
- Test MATLAB help: `help FolderName`
- Preview Markdown/HTML output

---

## Troubleshooting

### Issue: Function not appearing in Contents

**Solution**: Check that H1 line follows pattern:
```matlab
%FunctionName - Description.
```
Not:
```matlab
% FunctionName - Description  (extra space)
%FunctionName: Description     (wrong delimiter)
```

### Issue: Missing descriptions

**Solution**: Ensure `buildContents` can read the file:
```matlab
tbl = buildContents('Base');
% Check tbl.Data for "(No Description)" entries
```

### Issue: Group assignment not working

**Solution**: Verify Contents.xlsx structure:
- Index sheet has correct sheet references
- Content sheets have "Group" column with numeric values
- Groups sheets have "Id" column matching Group numbers

### Issue: Class info extraction fails

**Solution**: 
- MATLAB only (not Octave)
- Class must be on path
- Check class name spelling

---

## Summary

TaesLab documentation workflow:

1. **Write** proper inline documentation in all `.m` files
2. **Extract** descriptions using `buildContents.m`
3. **Organize** functions into groups via `Contents.xlsx`
4. **Generate** structured data with `groupContents.m`
5. **Build** formatted documentation using `BuildDocuments.m`
6. **Extract** class details with `getClassInfo.m`

This system ensures documentation stays synchronized with code and can be exported to multiple formats for different audiences.
