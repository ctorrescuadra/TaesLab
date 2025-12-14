function res = ValidateModelTables(filename, varargin)
%ValidateModelTables - Validate and convert tabular data model files.
%   Reads tabular data model files (CSV or XLSX) and validates the table
%   structure and content according to the rules defined in the cModelTable
%   class. This function is specifically designed for table-based formats and
%   can convert them to structured formats (JSON, XML) after validation.
%
%   The validation process checks:
%     - Required tables/sheets are present (Flows, Processes, States, etc.)
%     - Column names match expected field definitions
%     - Data types are correct for each field
%     - Flow keys and process definitions follow naming conventions
%     - Numeric data is valid and consistent
%
%   Unlike ReadDataModel (which creates cDataModel objects), this function
%   returns a cReadModel object containing the raw validated table data,
%   making it useful for format conversion and table structure verification.
%
%   Syntax:
%     res = ValidateModelTables(filename)
%     res = ValidateModelTables(filename, Name, Value)
%   
%   Input Arguments:
%     filename - Path to the tabular data model file
%       char array | string
%       Supported formats: Excel (.xlsx) or CSV directory (.csv)
%       Excel: Multi-sheet workbook with predefined sheet names
%       CSV: Directory containing multiple CSV files with naming convention
%
%   Name-Value Arguments:
%     Show - Display validated data tables in the console
%       true | false (default)
%       When true, prints all validated tables showing flows, processes,
%       exergy states, and resource costs in formatted tables.
%
%     SaveAs - Save validated model to a different format
%       char array | string (default: empty)
%       Converts the validated table data to a structured format (JSON or XML).
%       The output format is determined by the file extension (.json or .xml).
%       Useful for converting Excel/CSV models to JSON/XML for faster loading.
%
%   Output Arguments:
%     res - cReadModel object (cReadModelXLS or cReadModelCSV)
%       Contains the validated table data and validation messages. The status
%       property indicates success (true) or failure (false). Use isValid(res)
%       to check before proceeding with conversion or display.
%
%   Validation Rules:
%     Tables must follow the structure defined in Config/printformat.json:
%       - Flows table: key, type, description (optional)
%       - Processes table: key, fuel, product, description (optional)
%       - States/Samples tables: flow keys as columns with numeric data
%       - Resource costs: flow keys with cost values
%       - Waste Definition and Allocation tables.
%
%   Supported File Formats:
%     Input:
%       XLSX - Excel workbook with sheets: Flows, Processes, States, Costs
%       CSV  - Directory with files: flows.csv, processes.csv, states.csv, etc.
%     
%     Output (via SaveAs):
%       JSON - Hierarchical JSON structure with nested objects
%       XML  - Schema-based XML format with element validation
%
%   Examples:
%     % Example 1: Basic validation of Excel file
%     res = ValidateModelTables('Examples/rankine/rankine_model.xlsx');
%     if isValid(res)
%         fprintf('Valid model: %s\n', res.ModelName);
%     end
%
%     % Example 2: Validate and display tables
%     res = ValidateModelTables('Examples/tgas/tgas_model.xlsx', 'Show', true);
%     % Displays all validated tables in formatted output
%
%     % Example 3: Validate CSV and convert to JSON
%     res = ValidateModelTables('Examples/tgas/tgas_model.csv', ...
%                               'SaveAs', 'tgas_model.json');
%     % Converts validated CSV data to JSON format
%
%     % Example 4: Validate Excel and convert to XML
%     res = ValidateModelTables('Examples/bfgt/bfgt_model.xlsx', ...
%                               'SaveAs', 'bfgt_model.xml');
%     % Converts Excel model to XML format
%
%     % Example 5: Full validation with display and conversion
%     res = ValidateModelTables('Examples/vcr/vcr_model.xlsx', ...
%                               'Show', true, ...
%                               'SaveAs', 'vcr_validated.json');
%     % Validate, display tables, and save as JSON
%
%     % Example 6: Error handling for invalid table structure
%     res = ValidateModelTables('invalid_model.xlsx');
%     if ~isValid(res)
%         fprintf('Validation failed\n');
%         printLogger(res);  % Display validation errors
%     end
%
%   Common Use Cases:
%     - Validating Excel or CSV model files before analysis
%     - Converting Excel models to JSON for faster loading
%     - Verifying table structure and field definitions
%     - Debugging model data entry errors
%     - Creating JSON/XML versions of spreadsheet models
%
%   Error Handling:
%     The function returns a cReadModel object even on failure. Validation
%     errors are logged in the object and displayed automatically. Always
%     check isValid(res) or res.status before using the validated data.
%
%   Comparison with ReadDataModel:
%     ValidateModelTables:
%       - Input: XLSX, CSV only (tabular formats)
%       - Output: cReadModel object (raw table data)
%       - Purpose: Validation and format conversion
%       - Use when: Converting formats or validating table structure    
%     ReadDataModel:
%       - Input: JSON, XML, XLSX, CSV, MAT (all formats)
%       - Output: cDataModel object (validated model ready for analysis)
%       - Purpose: Loading models for thermoeconomic analysis
%       - Use when: Preparing models for computation
%
%   See also:
%     ReadDataModel, SaveDataModel, cReadModelTable, cReadModelXLS,
%     cReadModelCSV, cModelTable, cModelData
%
    res = cTaesLab();   
    % Validate required input argument
    if nargin < 1
        res.printError(cMessages.NarginError, cMessages.ShowHelp);
        return
    end
    % Validate filename format
    if ~isFilename(filename)
        res.printError(cMessages.InvalidInputFile);
        return
    end
    % Check file existence
    if ~exist(filename, 'file')
        res.printError(cMessages.FileNotFound, filename);
        return
    end  
    % Parse optional name-value arguments
    p = inputParser;
    p.addParameter('Show', false, @islogical);
    p.addParameter('SaveAs', cType.EMPTY_CHAR, @isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    param = p.Results;

    filename = char(filename);  
    % Read and validate the data model based on file extension
    [fileType, fileExt] = cType.getFileType(filename);
    switch fileType
        case cType.FileType.CSV
            res = cReadModelCSV(filename);
        case cType.FileType.XLSX
            res = cReadModelXLS(filename);
        otherwise
            res.printError(cMessages.InvalidFileExt, upper(fileExt));
            return
    end

    % Display validation messages and overall result
    printLogger(res)
    if res.status
        res.printInfo(cMessages.ValidDataModel, res.ModelName);
    else
        res.printError(cMessages.InvalidDataModelFile, filename);
    end

    % Display validated data tables if Show enabled and validation succeeded
    if param.Show && res.status
        printModelTables(res);
    end
    
    % Convert to structured format if SaveAs specified and validation succeeded
    if ~isempty(param.SaveAs) && res.status
        log = saveDataModel(res.ModelData, param.SaveAs);
        % Report save operation result
        if log.status
            log.printInfo(cMessages.InfoFileSaved, res.ModelName, param.SaveAs);
        else
            printLogger(log);
            log.printError(cMessages.ErrorFileNotSaved, param.SaveAs);
        end
    end
end

function log = saveDataModel(data, filename)
%saveDataModel - Save the validated model data in a structured format (JSON, XML)
%   Internal helper function to convert table data to JSON or XML format
    log = cMessageLogger();
    
    % Determine output format from file extension
    [fileType, fileExt] = cType.getFileType(filename);
    switch fileType
        case cType.FileType.JSON
            log = saveAsJSON(data, filename);
        case cType.FileType.XML
            log = saveAsXML(data, filename);
        otherwise
            log.printError(cMessages.InvalidFileExt, upper(fileExt));
    end
end