function obj = ImportDataModel(filename)
%ImportDataModel - Load a cDataModel object from a MAT file.
%   Loads a previously saved cDataModel object from a MATLAB binary (MAT) file.
%   This is the fastest method for loading data models, typically 5-10x faster
%   than reading from JSON, XML, or Excel files. The MAT file must contain a
%   valid cDataModel object created with SaveDataModel or ReadDataModel.
%
%   This function is MATLAB-only and will not work in Octave. For cross-platform
%   compatibility, use ReadDataModel with JSON or XLSX files instead.
%
%   Syntax:
%     obj = ImportDataModel(filename)
%
%   Input Arguments:
%     filename - Path to MAT file containing a cDataModel object
%       char array | string
%       The file must have a .mat extension and contain a cDataModel object
%       that was previously saved using SaveDataModel or ReadDataModel with
%       the 'SaveAs' option.
%
%   Output Arguments:
%     obj - cDataModel object loaded from the MAT file
%       Contains the complete thermoeconomic data model including productive
%       structure, exergy states, resource costs, and waste definitions.
%       Check obj.status or use isValid(obj) to verify successful loading.
%
%   Platform Compatibility:
%     MATLAB : Fully supported
%     Octave : Not supported (MAT file format limitations)
%     Use ReadDataModel with JSON files for Octave compatibility.
%
%   Examples:
%     % Example 1: Basic import of MAT file
%     dataModel = ImportDataModel('Examples/cgam/cgam_model.mat');
%     if isValid(dataModel)
%         fprintf('Loaded model: %s\n', dataModel.ModelName);
%     end
%
%     % Example 2: Import and display validation messages
%     obj = ImportDataModel('myDataModel.mat');
%     printLogger(obj);  % Display status and any error messages
%
%     % Example 3: Import and perform analysis
%     model = ImportDataModel('Examples/cgam/cgam_model.mat');
%     if isValid(model)
%         results = ExergyAnalysis(model);
%         ShowResults(results);
%     end
%
%     % Example 4: Error handling for invalid file
%     obj = ImportDataModel('nonexistent.mat');
%     if ~isValid(obj)
%         fprintf('Failed to load MAT file\n');
%         printLogger(obj);
%     end
%
%     % Example 5: Compare loading speed (MAT vs JSON)
%     tic; modelMAT = ImportDataModel('cgam_model.mat'); t1 = toc;
%     tic; modelJSON = ReadDataModel('cgam_model.json'); t2 = toc;
%     fprintf('MAT: %.3f sec, JSON: %.3f sec (%.1fx faster)\n', t1, t2, t2/t1);
%
%   Common Use Cases:
%     - Fast loading of frequently used models
%     - Production environments requiring quick startup
%     - Batch processing multiple models
%     - Loading large models with many states/samples
%     - Reducing analysis script execution time
%
%   Workflow:
%     1. Create/Edit model in Excel or JSON
%     2. Load with ReadDataModel
%     3. Save as MAT with SaveDataModel or 'SaveAs' option
%     4. Use ImportDataModel for subsequent fast loading
%
%   Error Handling:
%     The function returns an invalid cDataModel object if:
%       - Running in Octave (MAT files not supported)
%       - File not found or path invalid
%       - File is not a valid MAT file
%       - MAT file does not contain a cDataModel object
%     Always check obj.status or use isValid(obj) before proceeding.
%
%   Performance Notes:
%     MAT files provide significant performance benefits:
%       - No parsing overhead (binary format)
%       - Instant object reconstruction
%       - Reduced memory allocation
%       - Typical speedup: 5-10x vs JSON, 10-20x vs Excel
%
%   Note:
%     Use printLogger(obj) to display the import status and any error messages.
%
%   See also ReadDataModel, SaveDataModel, CopyDataModel, isValid, printLogger,
%     cDataModel, ThermoeconomicModel
%
    obj = cTaesLab(cType.INVALID);   
    % Check platform compatibility: MAT files only work in MATLAB
    if isOctave
        obj.printError(cMessages.NoReadFiles, 'MAT');
        return
    end    
    % Validate input arguments
    if (nargin ~= 1)
        obj.printError(cMessages.InvalidArgument, cMessages.ShowHelp);
        return
    end
    % Validate filename format and extension
    if ~isFilename(filename) || ~cType.checkFileExt(filename, cType.FileExt.MAT)
        obj.printError(cMessages.InvalidInputFile, filename);
        return
    end  
    % Check file existence
    if ~exist(filename, 'file')
        obj.printError(cMessages.FileNotFound, filename);
        return
    end   
    % Load MAT file and extract the data model object
    try
        S = load(filename);
        f = fieldnames(S);
        var = S.(f{1});
    catch err
        obj.printError(err.message)
        obj.printError(cMessages.FileNotRead, filename);
    end   
    % Validate that the loaded variable is a cDataModel object
    if isObject(var, 'cDataModel')
        obj = var;
        obj.printInfo(cMessages.ValidDataModel, obj.ModelName);
    else
        obj.printError(cMessages.NoDataModel);
    end
end