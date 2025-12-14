function res = ProductiveStructure(data, varargin)
%ProductiveStructure - Extract and display productive structure information from a data model.
%   Analyzes a thermoeconomic data model and generates tables describing the
%   productive structure of the plant: flows (energy streams), processes
%   (equipment/components), and their interconnections. This function provides
%   a clear overview of the system topology without performing any exergy or
%   cost calculations.
%
%   The productive structure defines the architecture of the plant,
%   showing how flows connect processes and identifying fuel/product
%   relationships. This is used for understanding system topology before
%   conducting thermoeconomic analysis.
%
%   Syntax:
%     res = ProductiveStructure(data)
%     res = ProductiveStructure(data, Name, Value)
%
%   Input Arguments:
%     data - Data model containing plant structure and configuration
%       cDataModel object
%       Must be a valid data model created by ReadDataModel or ThermoeconomicModel.
%
%   Name-Value Arguments:
%     Show - Display productive structure tables in console
%       true | false (default)
%       When true, prints formatted tables showing flows, processes, and
%       their relationships. Useful for quick inspection and verification.
%
%     SaveAs - Export productive structure to external file
%       char array | string (default: empty)
%       Saves structure tables to file. Supported formats: XLSX, CSV, HTML, JSON, XML.
%       Format is determined by file extension. Useful for documentation and reporting.
%
%   Output Arguments:
%     res - cResultInfo object containg the productive structure info.
%
%   ResultInfo:
%     cProductiveStructure (cType.ResutId.PRODUCTIVE_STRUCTURE)
%
%   Generated Tables:
%     flows - Flow definitions and classifications     
%     processes - Process definitions and fuel/product relationship       
%     streams - Productive Groups definition
%
%   Examples:
%     % Example 1: Extract productive structure from CGAM model
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveStructure(data);
%     if isValid(res)
%         fprintf('Structure extracted: %d flows, %d processes\n', ...
%                 res.NrOfFlows, res.NrOfProcesses);
%     end
%
%     % Example 2: Display structure tables in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveStructure(data, 'Show', true);
%     % Prints formatted tables with all flows and processes
%
%     % Example 3: Export structure to Excel file
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveStructure(data, 'SaveAs', 'cgam_structure.xlsx');
%     % Creates Excel file with separate sheets for flows and processes
%
%     % Example 4: Save structure as HTML report
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveStructure(data, ...
%                               'Show', true, ...
%                               'SaveAs', 'structure_report.html');
%     % Displays tables and saves HTML report with formatted tables
%
%     % Example 5: Access specific structure information
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveStructure(data);
%     if isValid(res)
%         flowsTable = res.getTable('flows');
%         printTable(flowsTable)
%     end
%
%   Common Use Cases:
%     - Verifying plant topology after data entry
%     - Documenting system structure for reports
%     - Understanding flow-process relationships before analysis
%     - Comparing structures of different plant configurations
%     - Generating structure diagrams and tables for publications
%
%   Workflow Integration:
%     This function is typically the first analysis step:
%       1. ReadDataModel() - Load plant data
%       2. ProductiveStructure() - Verify structure (this function)
%       3. ExergyAnalysis() - Calculate exergy flows
%       4. ThermoeconomicAnalysis() - Calculate costs
%       5. ThermoeconomicDiagnosis() - Compare operating conditions
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       - Input is not a valid cDataModel object
%       - ProductiveStructure component is invalid or missing
%       - Flow or process definitions contain errors
%       - Required fields are missing from the data model
%     Always check res.status or use isValid(res) before accessing results.
%
%   Performance Notes:
%     - Structure extraction is very fast (milliseconds for typical plants)
%     - No iterative calculations performed
%     - Memory usage is minimal (tables only)
%     - Suitable for large-scale systems (100+ processes)
%
%   Live Script Demo:
%     <a href="matlab:open ProductiveStructureDemo.mlx">Productive Structure Demo</a>
%
%   See also:
%     ReadDataModel, cDataModel, cProductiveStructure, cResultInfo, ShowResults,
%     SaveResults, printResults
%
    res = cTaesLab();
    % Validate required input argument
    if nargin < 1 || ~isObject(data, 'cDataModel')
        res.printError(cMessages.DataModelRequired, cMessages.ShowHelp);
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
    
    % Extract productive structure component from data model
    ps = data.ProductiveStructure;
    if ps.status
        res = buildResultInfo(ps, data.FormatData);
    else
        ps.printLogger;
        res.printError(cMessages.InvalidObject, class(ps));
    end
    
    % Validate extraction results
    if ~res.status
        res.printLogger;
        res.printError(cMessages.InvalidObject, class(res));
        return
    end
    
    % Display results in console if Show enabled
    if param.Show
        printResults(res);
    end
    
    % Export results to file if SaveAs specified
    if ~isempty(param.SaveAs)
        SaveResults(res, param.SaveAs);
    end
end