function res = ExergyAnalysis(data, varargin)
%ExergyAnalysis - Perform exergy analysis of a system for a specific plant operating state.
%   Analyzes a thermoeconomic data model using the Second Law of Thermodynamics, 
%   to calculate the irreversibilities and efficiencies for all processes of the model. 
%   This analysis step quantifies the energy quality degradation and process performance.
%
%   This function required a data model, including the exergy values for all system flows to calculate:
%     - The exergy of fuel and products of each process.
%     - The irreversibilities (exergy destruction)
%     - The unit consumption and exergetic efficiency
%     - The Fuel-Product tables showing the processes relationships
%
%   Syntax:
%     res = ExergyAnalysis(data)
%     res = ExergyAnalysis(data, Name, Value)
%
%   Input Arguments:
%     data - Data model containing plant structure and thermodynamic states
%       cDataModel object
%
%   Name-Value Arguments:
%     State - Name of the operating state to analyze
%       char array (default value: first state in data model)
%
%     Show - Display exergy analysis results in console
%       boolean (default value: false)
%
%     SaveAs - Export exergy analysis results to external file
%       char array | string (default value: empty)
%       It saves the result tables to a file, Format is determined by file extension.
%       Supported formats are : XLSX, CSV, HTML, LaTex, Markdown, MAT.
%
%   Output Arguments:
%     res - cResultInfo object containig exergy analysis info
%
%     ResultInfo:
%       cExergyModel (cType.ResultId.THERMOECONOMIC_STATE)
%
%     Generated Tables:
%       eflows - Exergy values for all flows     
%       estreams - Exergy values for productive groups (streams)
%       eprocesses - Exergy balance for each process      
%       tfp - Fuel-Product table (process interaction matrix)
%
%   Workflow Integration:
%       1. ReadDataModel() - Load plant data with thermodynamic states
%       2. ProductiveStructure() - Verify topology (optional)
%       3. ExergyAnalysis() - Calculate exergy (this function)
%       4. ThermoeconomicAnalysis() - Calculate costs based on exergy
%       5. ThermoeconomicDiagnosis() - Compare states and detect malfunctions
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       - Input is not a valid cDataModel object
%       - Specified state does not exist in the data model
%       - Exergy data is missing or invalid for the state
%       - Exergy balance calculations fail
%
%   Examples:
%     % Example 1: Basic exergy analysis of CGAM model (default state)
%     data = ReadDataModel(cgam_model.json');
%     res = ExergyAnalysis(data);
%     if isValid(res)
%         fprintf('Exergy analysis completed for state: %s\n', res.State);
%     end
%
%     % Example 2: Analyze specific operating state
%     data = ReadDataModel('cgam_model.json');
%     res = ExergyAnalysis(data, 'State', 'ETG87');
%     % Calculates exergy for the 'design' operating condition
%
%     % Example 3: Display exergy results in console
%     res = ExergyAnalysis(data, 'Show', true);
%     % Prints all exergy tables: flows, processes, efficiencies, FP table
%
%     % Example 4: Export exergy analysis to Excel
%     data = ReadDataModel('cgam_model.json');
%     res = ExergyAnalysis(data, ...
%                          'State', 'ETG87', ...
%                          'SaveAs', 'cgam_exergy.xlsx');
%     % Creates Excel file with separate sheets for each table
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