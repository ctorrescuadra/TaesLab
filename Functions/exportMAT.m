function log = exportMAT(obj, filename)
%exportMAT - Export cTaesLab object to MAT file.
%   Exports a cTaesLab object (or any object derived from cTaesLab) to a
%   MATLAB binary MAT file format. This function is used internally by
%   SaveResults and SaveTable for persisting analysis results.
%
%   MAT files provide:
%     - Binary format for efficient storage and loading
%     - Preservation of complete object state and properties
%     - Fast serialization/deserialization
%     - MATLAB-native format for workspace integration
%   Platform Compatibility:
%     - MATLAB: Fully supported using built-in save() function
%     - Octave: NOT supported - returns error (object serialization limitations)
%
%   Syntax:
%     log = exportMAT(obj, filename)
%
%   Input Arguments:
%     obj      - cTaesLab object or derived class instance
%                (e.g., cDataModel, cResultInfo, cTable, etc.)
%     filename - MAT output filename (must have .mat extension)
%                char array | string scalar
%
%   Output Arguments:
%     log - cMessageLogger object containing operation status
%           log.status = true  : File saved successfully
%           log.status = false : Error occurred during save
%
%   Examples:
%     % Example 1: Export analysis results
%     model = ThermoeconomicModel('Examples/rankine/rankine_model.json');
%     results = model.exergyAnalysis();
%     log = exportMAT(results, 'exergy_results.mat');
%     if log.status
%         fprintf('Results saved successfully\n');
%     end
%
%     % Example 2: Export data model
%     data = ReadDataModel('plant_model.json');
%     log = exportMAT(data, 'data_model.mat');
%
%     % Example 3: Export table object
%     model = ThermoeconomicModel('model.json');
%     costs = model.thermoeconomicAnalysis();
%     table = costs.getTable('dcost');
%     log = exportMAT(table, 'cost_table.mat');
%
%     % Example 4: Error handling
%     log = exportMAT(obj, 'output.mat');
%     if ~log.status
%         printLogger(log);  % Display error messages
%     end
%
%     % Example 5: Check platform compatibility
%     if isOctave()
%         fprintf('MAT export not supported in Octave\n');
%     else
%         log = exportMAT(results, 'results.mat');
%     end
%
%     % Example 6: String filename
%     log = exportMAT(obj, string('C:\output\results.mat'));
%
%   Limitations:
%     - Octave: Object serialization to MAT files is not implemented
%       Use exportJSON() or exportCSV() for Octave compatibility
%
%   Error Handling:
%     The function validates:
%     - Correct number of input arguments (2 required)
%     - obj is a valid cTaesLab object
%     - filename is valid and has .mat extension
%     - Platform is MATLAB (not Octave)
%     - File write operation succeeds
%
%   See also: importMAT, save, load, SaveResults, SaveTable, exportJSON
%
    log = cMessageLogger();   
    % Validate input arguments (count, object type, filename, extension)
    if nargin ~= 2 || ~isObject(obj, 'cTaesLab') || ...
            ~isFilename(filename) || ~cType.checkFileExt(filename, cType.FileExt.MAT)
        log.messageLog(cType.ERROR, cMessages.InvalidArgument, cMessages.ShowHelp);
        return;
    end    
    % Check platform compatibility (MAT export not supported in Octave)
    if isOctave()
        log.messageLog(cType.ERROR, cMessages.NoSaveFiles, 'MAT');
        return;
    end   
    % Save the cTaesLab object to MAT file
    try
        save(filename, 'obj');   % Save object using MATLAB's save function
    catch err
        % Log error details and file save failure
        log.messageLog(cType.ERROR, err.message);
        log.messageLog(cType.ERROR, cMessages.FileNotSaved, filename);
    end   
end