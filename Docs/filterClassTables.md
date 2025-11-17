# Filter Class Tables

Use logical indexing to filter out rows where `DefiningClass` is `'handle'`:

````matlab
% Get all properties
tbl = getClassProperties('cTable');

% Filter out handle class properties
tbl = tbl(~strcmp(tbl.DefiningClass, 'handle'), :);
````

For methods:

````matlab
% Get all methods
tbl = getClassMethods('cTable');

% Filter out handle class methods
tbl = tbl(~strcmp(tbl.DefiningClass, 'handle'), :);
````

If you want to exclude multiple base classes (e.g., both `'handle'` and `'matlab.mixin.Heterogeneous'`):

````matlab
% Exclude multiple classes
tbl = tbl(~ismember(tbl.DefiningClass, {'handle', 'matlab.mixin.Heterogeneous'}), :);
````

Or, to keep only properties/methods defined in TaesLab classes (those starting with `'c'`):

````matlab
% Keep only TaesLab classes (starting with 'c')
tbl = tbl(startsWith(tbl.DefiningClass, 'c'), :);
````

````matlab
% Get properties of cTable
tbl = getClassProperties('cTable');
disp(tbl);

% Filter by GetAccess
publicProps = tbl(strcmp(tbl.GetAccess, 'public'), :);

% Find properties defined only in cTable (not inherited)
ownProps = tbl(strcmp(tbl.DefiningClass, 'cTable'), :);
````

````matlab
% Example 1: Get methods from an object instance
obj=ReadDataModel('cgam_model.json');
tbl = getClassMethods(obj);
disp(tbl);

% Example 2: Use class name directly
tbl = getClassMethods('cDataModel');
disp(tbl);

% Example 3: Filter by access level
tbl = getClassMethods('cDataModel');
publicMethods = tbl(strcmp(tbl.Access, 'public'), :);
disp(publicMethods);

% Example 4: Find methods defined in specific class (not inherited)
tbl = getClassMethods('cTable');
ownMethods = tbl(strcmp(tbl.DefiningClass, 'cDataModel'), :);
disp(ownMethods);
````
