function res = ExergyAnalysis(data, varargin)
%ExergyAnalysis - Perform exergy analysis for a specific plant operating state.
%   Analyzes a thermoeconomic data model using the Second Law of Thermodynamics
%   to calculate exergy flows, irreversibilities, and efficiencies for all
%   processes and flows in the plant. This is the fundamental analysis step that
%   quantifies energy quality degradation and process performance.
%
%   The exergy analysis evaluates thermodynamic performance by calculating:
%     - Exergy values for all flows (based on temperature, pressure, composition)
%     - Exergy balances for each process (fuel input vs. product output)
%     - Irreversibilities (exergy destruction in each process)
%     - Exergetic efficiencies (ratio of product to fuel exergy)
%     - Fuel-Product (FP) table showing energy transformations
%
%   This function requires thermodynamic state data (exergy values)
%   for a specific operating condition. Multi-state analysis is available through
%   SummaryResults or ThermoeconomicDiagnosis functions.
%
%   Syntax:
%     res = ExergyAnalysis(data)
%     res = ExergyAnalysis(data, Name, Value)
%
%   Input Arguments:
%     data - Data model containing plant structure and thermodynamic states
%       cDataModel object
%       Must be a valid data model created by ReadDataModel or ThermoeconomicModel.
%       Must include at least one exergy state with thermodynamic properties.
%
%   Name-Value Arguments:
%     State - Name of the operating state to analyze
%       char array (default: first state in data model)
%       Identifies which thermodynamic condition to use for calculations.
%       State must exist in the ExergyStates section of the data model.
%
%     Show - Display exergy analysis results in console
%       true | false (default)
%       When true, prints formatted tables showing flows, processes, balances,
%       irreversibilities, efficiencies, and the Fuel-Product table.
%
%     SaveAs - Export exergy analysis results to external file
%       char array | string (default: empty)
%       Saves analysis tables to file. Supported formats: XLSX, CSV, HTML, JSON, XML.
%       Format is determined by file extension.
%
%   Output Arguments:
%     res - cResultInfo object containig exergy analysis info
%
%   ResultInfo:
%     cExergyModel (cType.ResultId.THERMOECONOMIC_STATE)
%
%   Generated Tables:
%     eflows - Exergy values for all flows     
%     estreams - Exergy values for productive groups (streams)
%     eprocesses - Exergy balance for each process      
%     tfp - Fuel-Product table (process interaction matrix)
%
%   Examples:
%     % Example 1: Basic exergy analysis of CGAM model (default state)
%     data = ReadDataModel('Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data);
%     if isValid(res)
%         fprintf('Exergy analysis completed for state: %s\n', res.StateName);
%     end
%
%     % Example 2: Analyze specific operating state
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data, 'State', 'design');
%     % Calculates exergy for the 'design' operating condition
%
%     % Example 3: Display exergy results in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data, 'Show', true);
%     % Prints all exergy tables: flows, processes, efficiencies, FP table
%
%     % Example 4: Export exergy analysis to Excel
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data, ...
%                          'State', 'design', ...
%                          'SaveAs', 'cgam_exergy.xlsx');
%     % Creates Excel file with separate sheets for each table
%
%     % Example 5: Access specific exergy values programmatically
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data);
%     if isValid(res)
%         processTable = res.getTable('eprocesses');
%         fprintf('Process efficiencies:\n');
%         disp(processTable.Data);
%     end
%
%     % Example 6: Generate HTML report with analysis
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ExergyAnalysis(data, ...
%                          'Show', true, ...
%                          'SaveAs', 'exergy_report.html');
%     % Creates formatted HTML report with all tables
%
%   Common Use Cases:
%     - Identifying processes with highest exergy destruction
%     - Calculating thermodynamic efficiency of equipment
%     - Benchmarking plant performance against theoretical limits
%     - Evaluating impact of operating conditions on efficiency
%     - Generating Fuel-Product tables for thermoeconomic analysis
%     - Preparing data for cost allocation calculations
%
%   Workflow Integration:
%     Typical analysis sequence:
%       1. ReadDataModel() - Load plant data with thermodynamic states
%       2. ProductiveStructure() - Verify topology (optional)
%       3. ExergyAnalysis() - Calculate exergy (this function)
%       4. ThermoeconomicAnalysis() - Calculate costs based on exergy
%       5. ThermoeconomicDiagnosis() - Compare states and detect malfunctions
%
%   Physical Interpretation:
%     - Exergy: Maximum useful work obtainable from an energy stream
%     - Irreversibility: Lost work potential due to process inefficiencies
%     - Exergetic efficiency: Measure of how well a process uses energy quality
%     - FP table: Shows energy quality transfer between processes
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       - Input is not a valid cDataModel object
%       - Specified state does not exist in the data model
%       - Exergy data is missing or invalid for the state
%       - Exergy balance calculations fail
%     Always check res.status or use isValid(res) before using results.
%
%   Performance Notes:
%     - Analysis is fast
%     - Computation time scales linearly with number of processes
%     - Memory usage depends on FP table size (processes²)
%     - Suitable for real-time monitoring applications
%
%   Live Script Demo:
%     <a href="matlab:open ExergyAnalysisDemo.mlx">Exergy Analysis Demo</a>
%
%   See also:
%     ReadDataModel, cDataModel, cExergyModel, cExergyData,
%     cResultInfo, ShowResults, SaveResults, printResults
%
    res = cTaesLab();
    
    % Validate required input argument
    if nargin < 1 || ~isObject(data, 'cDataModel')
        res.printError(cMessages.DataModelRequired, cMessages.ShowHelp);
        return
    end
    
    % Parse optional name-value arguments
    p = inputParser;
    p.addParameter('State', data.StateNames{1}, @data.existState);
    p.addParameter('Show', false, @islogical);
    p.addParameter('SaveAs', cType.EMPTY_CHAR, @isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    param = p.Results;
    
    % Extract and validate exergy data for the specified state
    ex = data.getExergyData(param.State);
    if ~ex.status
        ex.printLogger;
        res.printError(cMessages.InvalidExergyData, param.State);
        return
    end
    
    % Create exergy model and perform calculations
    pm = cExergyModel(ex);
    
    % Build result info container with calculated tables
    if pm.status
        res = pm.buildResultInfo(data.FormatData);
    else
        pm.printLogger;
        res.printError(cMessages.InvalidObject, class(pm));
        return
    end
    
    % Validate calculation results
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