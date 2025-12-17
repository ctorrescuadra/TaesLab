function obj = importMAT(filename)
%importMAT - Import cTaesLab object from MAT file.
%   Loads a cTaesLab object (or any derived class) from a MATLAB binary
%   MAT file that was previously saved using exportMAT(). This function
%   restores the complete object state including all properties and methods.
%
%   The import process:
%     1. Validates filename and extension
%     2. Loads MAT file contents using MATLAB's load() function
%     3. Extracts the first variable (should be the cTaesLab object)
%     4. Validates the loaded object
%     5. Returns the object or an invalid cTaesLab instance on error
%
%   Syntax:
%     obj = importMAT(filename)
%
%   Input Arguments:
%     filename - MAT file path containing saved cTaesLab object
%                char array | string scalar
%                File must exist and have .mat extension
%
%   Output Arguments:
%     obj - Loaded cTaesLab object (or derived class instance)
%           Returns invalid cTaesLab object if load fails
%           Check with isValid(obj) before use
%
%   Platform Compatibility:
%     - MATLAB: Fully supported using built-in load() function
%     - Octave: NOT supported - returns error (object deserialization limitations)
%
%   Examples:
%     % Example 1: Load previously saved results
%     results = importMAT('exergy_results.mat');
%     if isValid(results)
%         ShowResults(results);
%     end
%
%     % Example 2: Load data model
%     data = importMAT('data_model.mat');
%     if isValid(data)
%         model = ThermoeconomicModel(data);
%     end
%
%     % Example 3: Load and check object type
%     obj = importMAT('results.mat');
%     if isValid(obj) && isObject(obj, 'cResultInfo')
%         fprintf('Loaded result with %d tables\n', obj.NrOfTables);
%     end
%
%     % Example 4: Error handling
%     obj = importMAT('missing.mat');
%     if ~isValid(obj)
%         fprintf('Failed to load object\n');
%     end
%
%     % Example 5: Load table object
%     table = importMAT('cost_table.mat');
%     if isValid(table)
%         ShowTable(table);
%     end
%
%     % Example 6: String filename
%     obj = importMAT(string('C:\data\results.mat'));
%
%     % Example 7: Platform check
%     if isOctave()
%         fprintf('Use importJSON or importCSV instead\n');
%     else
%         obj = importMAT('results.mat');
%     end
%
%   Error Handling:
%     Returns an invalid cTaesLab object (isValid returns false) if:
%     - Wrong number of arguments
%     - Platform is Octave
%     - Invalid filename or wrong extension
%     - File does not exist or cannot be read
%     - File does not contain a valid cTaesLab object
%     Always check isValid(obj) before using the returned object.
%
%   See also: exportMAT, load, isValid, isObject, importJSON
%
    obj = cTaesLab();   
    % Validate input argument count
    if nargin ~= 1
        obj.printError(cMessages.NarginError, cMessages.ShowHelp);
        return;
    end   
    % Check platform compatibility (MAT import not supported in Octave)
    if isOctave()
        obj.printError(cMessages.FunctionNotAvailable, mfilename);
        return;
    end   
    % Validate filename and extension
    if ~isFilename(filename) || ~cType.checkFileExt(filename, cType.FileExt.MAT)
        obj.printError(cMessages.InvalidArgument, cMessages.ShowHelp);
        return;
    end  
    % Load MAT file and extract object
    try
        S = load(filename);  % Load MAT file structure      
        f = fieldnames(S);   % Get field names (variables in MAT file)
        var = S.(f{1});      % Extract first variable (assumed to be the cTaesLab object)
    catch err
        % Log error if file cannot be read
        obj.printError(err.message);
        obj.printError(cMessages.FileNotRead, filename);
        return;
    end   
    % Check loaded object is a valid cTaesLab instance
    if isValid(var)
        obj = var;
    else
        % Log error if loaded variable is not a valid cTaesLab object
        obj.printError(cMessages.InvalidMatFileObject, class(var), filename);
    end   
end