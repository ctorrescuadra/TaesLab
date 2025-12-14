function CopyDataModel(inputFile, outputFile)
%CopyDataModel - Copy and convert a data model file to a different format.
%   Reads a data model file, validates its contents, and saves it in a different
%   format. This function is useful for converting between file formats, creating
%   backups, or generating optimized versions (e.g., MAT files for faster loading).
%
%   The function automatically detects input and output formats based on file
%   extensions and performs the necessary conversion. All supported formats
%   contain the same thermoeconomic model information: productive structure,
%   exergy states, resource costs, and waste definitions.
%
%   Format is automatically detected from the file extension (.json, .xml, .xlsx, .csv, .mat).
%
%   Syntax:
%     CopyDataModel(inputFile, outputFile)
%     CopyDataModel inputFile outputFile
%
%   Input Arguments:
%     inputFile - Path to the source data model file
%       char array | string
%
%     outputFile - Path to the destination data model file
%       char array | string
%
%   Supported File Formats:
%     Input and Output:
%       JSON  (.json) - Human-readable hierarchical structure, fast parsing
%       XML   (.xml)  - Schema-validated XML format, portable
%       XLSX  (.xlsx) - Multi-sheet Excel workbook, easy editing
%       CSV   (.csv)  - Directory of CSV files, simple structure
%       MAT   (.mat)  - MATLAB binary format, fastest loading (MATLAB only)
%
%   Examples:
%
%     % Example 1: Convert Excel to JSON for analysis
%     CopyDataModel('Examples/cgam/cgam_model.xlsx', 'cgam_model.json');
%     % Edit in Excel, then convert to JSON for faster processing
%     % JSON is platform-independent and version-control friendly
%
%     % Example 2: Convert JSON to MAT for faster loading
%     CopyDataModel('Examples/cgam/cgam_model.json', 'cgam_model.mat');
%     % Binary MAT file loads 5-10x faster than JSON
%
%     % Example 3: Create backup in different format
%     CopyDataModel('Examples/cgam/cgam_model.json', 'backup/cgam_backup.xlsx');
%     % Backup as Excel file for easy inspection
%
%     % Example 4: Convert to XML for schema validation
%     CopyDataModel('Examples/cgam/cgam_model.json', 'cgam_validated.xml');
%     % XML format provides schema-based validation
%
%     % Example 5: Command-line style invocation
%     CopyDataModel Examples/cgam/cgam_model.json cgam_copy.mat
%     % No quotes needed when called from command line
%
%   Common Use Cases:
%     - Format conversion (Excel ↔ JSON ↔ XML ↔ MAT)
%     - Creating fast-loading binary versions (JSON → MAT)
%     - Generating editable versions (JSON → Excel)
%     - Creating portable backups
%     - Version control preparation (Excel → JSON)
%
%   Live Script Demo:
%     <a href="matlab:open SaveDataModelDemo.mlx">Save Data Model Demo</a>
%
%   Performance Notes:
%     Loading times (approximate, for typical models):
%       MAT  : Fastest (binary format)
%       JSON : Fast (optimized parsing)
%       CSV  : Medium (multiple file reads)
%       XML  : Medium (schema validation overhead)
%       XLSX : Slower (Excel format complexity)
%
%   See also:
%     SaveDataModel, ReadDataModel, cDataModel, cReadModel,
%     ValidateModelTables, ImportDataModel
%
    log = cTaesLab();   
    % Validate input arguments: exactly 2 file paths required
    if (nargin ~= 2) || ~isFilename(inputFile) || ~isFilename(outputFile)
        log.printError(cMessages.InvalidArgument, cMessages.ShowHelp)
        return
    end

    % Read and validate the input data model.
    data = cDataModel.create(inputFile);
    if data.status   % Save to output file if input was successfully loaded
        SaveDataModel(data, outputFile);
    else      % Display validation errors if input file could not be loaded
        printLogger(data);
    end
end