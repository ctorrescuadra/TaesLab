function SaveDataModel(arg, filename)
%SaveDataModel - Save thermoeconomic data model to file in various formats.
%   Exports a complete data model definition including productive structure, exergy
%   states, resource costs, and waste allocation to a file. This function provides
%   a convenient interface for persisting data models and converting between formats.
%   The target format is automatically determined from the file extension.
%
%   Supported formats include Excel spreadsheets (XLSX), multiple CSV files, JSON,
%   XML, and MATLAB binary files (MAT). The MAT format provides the fastest loading
%   times and is recommended for large models or frequent reuse.
%
%   The function validates both the input object and filename before attempting
%   the save operation. Status messages are displayed to confirm successful save
%   or report any errors encountered during the export process.
%   
%   Syntax:
%     SaveDataModel(arg, filename)
%
%   Input Arguments:
%     arg - Data model object to save
%       cDataModel | cThermoeconomicModel
%       The data model containing productive structure, exergy states, and cost
%       information. If a cThermoeconomicModel is provided, its internal DataModel
%       property is extracted and saved. Both object types contain the complete
%       model definition required for thermoeconomic analysis.
%
%     filename - Output file path with extension
%       char array | string
%       Full path or relative path to the output file. The file extension determines
%       the save format:
%         .xlsx - Excel workbook with multiple sheets (Flows, Processes, States, etc.)
%         .csv  - Directory with multiple CSV files (one per data table)
%         .json - JSON file with nested structure
%         .xml  - XML file with hierarchical structure
%         .mat  - MATLAB binary format (fastest loading, smallest size)
%       The parent directory must exist or an error will be reported.
%
%   Output:
%     (No output arguments)
%     Status messages are displayed in the console indicating success or failure.
%     Error messages include details about validation failures or file I/O issues.
%
%   File Format Details:
%     XLSX - Creates a workbook with sheets for each data table (ProductiveStructure,
%            ExergyStates, ResourcesCost, WasteDefinition, Format). Compatible with
%            Excel and other spreadsheet applications.
%
%     CSV  - Creates a directory with the base name of the file, containing separate
%            CSV files for each table. Useful for version control and text-based tools.
%
%     JSON - Single text file with hierarchical structure. Human-readable and widely
%            supported by other programming languages and tools.
%
%     XML  - Single text file with XML schema validation. Useful for integration
%            with XML-based systems and validation tools.
%
%     MAT  - Binary format optimized for MATLAB. Provides fastest loading and smallest
%            file size. Recommended for production use and large models.
%
%   Examples:
%     % Save data model to Excel format
%     data = ReadDataModel('plant_model.json');
%     SaveDataModel(data, 'plant_model.xlsx')
%
%     % Convert JSON to MAT for faster loading
%     model = ReadDataModel('Examples\rankine\rankine_model.json');
%     SaveDataModel(model, 'Examples\rankine\rankine_model.mat')
%
%     % Save thermoeconomic model's data
%     thermo = ThermoeconomicModel('plant_model.json');
%     SaveDataModel(thermo, 'plant_model_copy.json')
%
%   Live Script Demo:
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
%   See also ReadDataModel, cDataModel, cThermoeconomicModel
%
    log=cTaesLab();
    % Check Input Arguments:
    if (nargin~=2)
        log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
    end
    if isObject(arg,'cDataModel')
        data=arg;
    elseif isObject(arg,'cThermoeconomicModel')
        data=arg.DataModel;
    else
        log.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        log.printError(cMessages.InvalidOutputFile,filename);
        return
    end
    % Save the data model
    log=saveDataModel(data,filename);
    printLogger(log);
end