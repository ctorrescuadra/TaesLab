function data = ReadDataModel(filename, varargin)
%ReadDataModel - Read and validate a thermoeconomic data model file.
%   Loads a data model file into a cDataModel object with automatic format
%   detection and comprehensive validation. The function supports multiple file
%   formats (JSON, XML, XLSX, CSV) and provides optional debugging, display,
%   and persistence features.
%
%   The data model contains the complete definition of a thermoeconomic model:
%   productive structure (flows and processes), exergy states (thermodynamic
%   data for different operating conditions), resource costs, and waste allocation
%   strategies. All elements are validated during loading to ensure consistency.
%
%   Syntax:
%     data = ReadDataModel(filename)
%     data = ReadDataModel(filename, Name, Value)
%   
%   Input Arguments:
%     filename - Path to the data model file
%       char array | string
%       Supported formats: JSON (.json), XML (.xml), Excel (.xlsx), CSV directory
%       The file format is automatically detected from the extension.
%
%   Name-Value Arguments:
%     Debug - Display detailed validation information in the console
%       true | false (default)
%       When true, shows the validation process for each model element including
%       flows, processes, states, and cost data. Automatically enabled if the
%       model fails to load.
%
%     Show - Display data model tables in the console
%       true | false (default)
%       When true, prints formatted tables showing the productive structure,
%       exergy states, and resource costs after successful loading.
%
%     SaveAs - Save a copy of the data model to a file
%       char array | string (default: empty)
%       Creates a copy of the loaded model in the specified format. Typically
%       used to convert between formats or create MAT binary files for faster
%       loading. The output format is determined by the file extension.
%
%   Output Arguments:
%     data - cDataModel object containing the complete model information
%       Contains validated productive structure, exergy data, resource costs,
%       and waste definitions. The object's status property indicates whether
%       loading was successful. Use isValid(data) to check before proceeding.
%
%   File Format Structure:
%     All formats must define:
%       - ProductiveStructure: Flows (keys, types) and Processes (fuel/product)
%       - ExergyStates: One or more operating conditions with thermodynamic data
%       - FormatDefinition: Metadata about values and units used in the model 
%     Optionally, formats may include:
%       - ResourcesCost: (Optional) Cost data for resource flows
%       - WasteDefinition: (Optional) Waste cost allocation strategy
%
%   Supported File Formats:
%     JSON  (.json) - Hierarchical structure with nested objects
%     XML   (.xml)  - XML schema-based format with element validation
%     XLSX  (.xlsx) - Multi-sheet Excel workbook with predefined structure
%     CSV   (.csv)  - Directory of CSV files following naming convention
%     MAT   (.mat)  - Binary format via SaveDataModel function
%
%   Examples:
%     % Example 1: Basic loading from JSON file
%     data = ReadDataModel('Examples/rankine/rankine_model.json');
%     if isValid(data)
%         fprintf('Model loaded: %d flows, %d processes\n', ...
%                 data.NrOfFlows, data.NrOfProcesses);
%     end
%
%     % Example 2: Load with debugging information
%     data = ReadDataModel('Examples/tgas/tgas_model.xml', 'Debug', true);
%     % Displays detailed validation information for each element
%
%     % Example 3: Load and display data tables
%     data = ReadDataModel('Examples/bfgt/bfgt_model.xlsx', 'Show', true);
%     % Prints formatted tables showing flows, processes, and states
%
%     % Example 4: Load from Excel and save as JSON
%     data = ReadDataModel('Examples/vcr/vcr_model.xlsx', ...
%                          'SaveAs', 'vcr_backup.json');
%     % Converts Excel model to JSON format
%
%     % Example 5: Load from CSV directory with full options
%     data = ReadDataModel('Examples/tgas/tgas_model.csv', ...
%                          'Debug', true, 'Show', true, ...
%                          'SaveAs', 'tgas_optimized.mat');
%     % Debug validation, display tables, and save as MAT binary
%
%     % Example 6: Error handling for invalid file
%     data = ReadDataModel('nonexistent_model.json');
%     if ~isValid(data)
%         fprintf('Failed to load model\n');
%         printLogger(data);  % Display error messages
%     end
%
%   Live script demo:
%       <a href="matlab:open ReadDataModelDemo.mlx">Read Model Demo</a>
%
%   Common Use Cases:
%     - Loading plant models for thermoeconomic analysis
%     - Converting between file formats (Excel → JSON, JSON → MAT)
%     - Validating model structure and data consistency
%     - Creating binary MAT files for faster repeated loading
%     - Debugging model definition errors
%
%   Error Handling:
%     The function returns a cDataModel object even on failure. Always check
%     the status property or use isValid(data) before proceeding. Error messages
%     are logged in the object and can be displayed with printLogger(data).
%
%   Performance Notes:
%     - JSON files: Fast parsing, human-readable
%     - XML files: Schema validation, slower parsing
%     - XLSX files: Convenient editing, slower loading
%     - CSV files: Multiple files, fastest for large models
%     - MAT files: Fastest loading, binary format (via SaveAs)
%
%   See also:
%     SaveDataModel, ThermoeconomicModel, cDataModel, cReadModel,
%     cReadModelJSON, cReadModelXML, cReadModelXLS, cReadModelCSV,
%     isValid, printLogger, printResults
%

    data = cTaesLab();   
    % Validate required input argument
    if nargin < 1
        data.printError(cMessages.NarginError, cMessages.ShowHelp);
        return
    end   
    % Validate filename format
    if ~isFilename(filename)
        data.printError(cMessages.InvalidInputFile);
        return
    end   
    % Check file existence
    if ~exist(filename, 'file')
        data.printError(cMessages.FileNotFound, filename);
        return
    end   
    % Parse optional name-value arguments
    p = inputParser;
    p.addParameter('Debug', false, @islogical);
    p.addParameter('Show', false, @islogical);
    p.addParameter('SaveAs', cType.EMPTY_CHAR, @isFilename);
    try
        p.parse(varargin{:});
    catch err
        data.printError(err.message);
        return
    end
    param = p.Results;    
    % Read and validate data model from file
    data = cDataModel.create(filename);   
    % Display validation information if Debug enabled or loading failed
    if param.Debug || ~data.status
        printLogger(data);
    end   
    % Display data tables if Show enabled and loading succeeded
    if param.Show && data.status
        printResults(data);
    end   
    % Save a copy of the model if SaveAs specified and loading succeeded
    if ~isempty(param.SaveAs) && data.status
        SaveDataModel(data, param.SaveAs);
    end

