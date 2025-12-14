function res=ThermoeconomicDiagnosis(data,varargin)
%ThermoeconomicDiagnosis - Detect and quantify malfunctions by comparing plant operating states.
%   Performs thermoeconomic diagnosis by comparing two operating states to identify
%   equipment malfunctions, efficiency degradation, and operational changes. The
%   diagnosis quantifies how variations in irreversibility (exergy destruction)
%   impact overall plant costs.
%
%   Thermoeconomic diagnosis reveals:
%     • Which equipment has degraded performance (malfunctions)
%     • Cost impact of each malfunction on plant operation
%     • Whether changes are due to equipment issues or operational conditions
%     • Propagation of local inefficiencies through the productive structure
%     • Fuel impact and product cost variations
%
%   The analysis compares a Reference State (baseline, typically design or optimal
%   operation) against an Operational State (current operation) to detect deviations.
%   Two diagnostic methods handle waste cost variations differently:
%
%   Diagnostic Methods:
%     WASTE_EXTERNAL - Treats waste as plant outputs
%       • Computes waste cost variation between states
%       • Suitable when waste disposal/treatment costs are external
%       • Simpler approach, less detailed waste analysis
%
%     WASTE_INTERNAL - Allocates waste costs to productive processes
%       • Identifies which processes generate additional waste
%       • Computes malfunction cost including waste generation impact
%       • More detailed, shows internal cost recycling effects
%       • Recommended for comprehensive diagnosis
%
%   The data model must contain at least two exergy states (reference and
%   operational) to enable comparative diagnosis.
%
%   Syntax:
%     res = ThermoeconomicDiagnosis(data)
%     res = ThermoeconomicDiagnosis(data, Name, Value)
%
%   Input Arguments:
%     data - cDataModel containing plant data with multiple states
%       Must include at least two exergy states for comparison.
%
%   Name-Value Arguments:
%     ReferenceState - Baseline operating state for comparison
%       char array | string (default: first state in data model)
%       Typically represents design conditions or optimal operation
%       Used as reference to detect deviations
%
%     State - Operational state to diagnose
%       char array | string (default: second state in data model)
%       Current or alternative operating condition to analyze
%       Must be different from ReferenceState
%
%     DiagnosisMethod - Method for handling waste cost variations
%       'WASTE_EXTERNAL' | 'WASTE_INTERNAL' (default: 'WASTE_INTERNAL')
%       'WASTE_EXTERNAL' - Waste treated as external outputs
%       'WASTE_INTERNAL' - Waste costs allocated to generating processes
%       See Diagnostic Methods section above for detailed comparison
%
%     Show - Display diagnosis results in console
%       true | false (default)
%       When true, prints summary and detailed malfunction tables
%       Includes malfunction costs, irreversibility changes, fuel impacts
%
%     SaveAs - Export diagnosis results to file
%       char array | string (default: empty)
%       Saves analysis tables to file
%       Supported formats: XLSX, CSV, HTML, JSON, XML
%       Format determined by file extension
%
%   Output Arguments:
%     res - cResultInfo object containing diagnosis results
%       Contains multiple tables quantifying malfunctions and cost impacts
%
%   ResultInfo:
%     cDiagnosis (cType.ResultId.THERMOECONOMIC_DIAGNOSIS)
%
%   Generated Tables:
%     dgn - Diagnosis summary table
%     mf - Malfunction table
%     mfc - Malfunction cost table
%     dit - Irreversibility variation table
%     tmfc - Total malfunction cost
%     dft - Fuel impact table
%
%   Examples:
%
%     % Example 1: Basic diagnosis (compare first two states)
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicDiagnosis(data);
%     % Uses default: state 1 as reference, state 2 as operational
%
%     % Example 2: Diagnose specific states with internal waste method
%     data = ReadDataModel('./Examples/rankine/rankine_model.json');
%     res = ThermoeconomicDiagnosis(data, ...
%                                    'ReferenceState', 'REF', ...
%                                    'State', 'ETG87', ...
%                                    'DiagnosisMethod', 'WASTE_INTERNAL');
%
%     % Example 3: Display diagnosis summary in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicDiagnosis(data, 'Show', true);
%     % Prints malfunction summary and detailed tables
%
%     % Example 4: Export diagnosis to Excel for detailed analysis
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicDiagnosis(data, ...
%                                    'SaveAs', 'diagnosis_report.xlsx');
%     % Creates Excel file with all diagnosis tables
%
%   Live Script Demo:
%     <a href="matlab:open ThermoeconomicDiagnosisDemo.mlx">Thermoeconomic Diagnosis Demo</a>
%
%   Common Use Cases:
%     • Equipment degradation detection after extended operation
%     • Identifying performance changes due to fouling or wear
%     • Comparing seasonal operation differences
%     • Evaluating impact of process parameter changes
%     • Prioritizing maintenance activities based on cost impact
%     • Quantifying benefits of equipment upgrades or cleaning
%     • Monitoring plant performance over time
%
%   Workflow Integration:
%     Typical diagnosis sequence:
%       1. ReadDataModel() - Load plant data with multiple operating states
%       2. ProductiveStructure() - Verify plant topology (optional)
%       3. ExergyAnalysis() - Analyze thermodynamic performance of each state
%       4. ThermoeconomicAnalysis() - Calculate costs for each state
%       5. ThermoeconomicDiagnosis() - Compare states to identify malfunctions (this function)
%       6. Interpret results to guide maintenance and optimization decisions
%
%   Diagnostic Method Selection Guidelines:
%     Use WASTE_EXTERNAL when:
%       • Waste disposal is handled externally (purchased service)
%       • Simple diagnosis without detailed waste analysis
%       • Waste cost data is not available internally
%       • Quick screening of overall performance changes
%
%     Use WASTE_INTERNAL (recommended) when:
%       • Detailed analysis of waste generation sources needed
%       • Understanding which processes create additional waste
%       • Waste treatment/recycling is part of plant operation
%       • Comprehensive diagnosis for optimization decisions
%       • Environmental impact assessment is important
%
%   Interpretation Guidelines:
%     Malfunction (positive MF value):
%       • Process efficiency has decreased vs reference
%       • More exergy destroyed for same function
%       • Indicates degradation, fouling, or sub-optimal operation
%
%     Improvement (negative MF value):
%       • Process efficiency has increased vs reference
%       • Less exergy destroyed for same function
%       • May indicate better operation or beneficial changes
%
%     High Malfunction Cost:
%       • Significant economic impact on plant operation
%       • High priority for corrective action
%       • May justify equipment replacement or major maintenance
%
%     Fuel Impact:
%       • Shows how malfunctions increase fuel consumption
%       • Direct link between efficiency loss and resource use
%       • Helps quantify fuel savings from addressing malfunctions
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       • Input is not a valid cDataModel object
%       • Data model has fewer than two states
%       • Specified states do not exist in data model
%       • ReferenceState and State are identical
%       • Exergy data is missing or invalid for either state
%       • Diagnosis calculation fails (singular matrices, etc.)
%       • Invalid DiagnosisMethod specified
%     Always check res.status or use isValid(res) before using results.
%
%   See also:
%     ReadDataModel, cDataModel, cDiagnosis, cExergyCost, ThermoeconomicAnalysis,
%     ExergyAnalysis, cResultInfo, ShowResults, SaveResults
%

    % Initialize and validate input parameters
    res=cTaesLab();
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
    % Check optional input parameters
    p = inputParser;
    p.addParameter('ReferenceState',data.StateNames{1},@data.existState)
	p.addParameter('State',cType.EMPTY_CHAR,@ischar);
    p.addParameter('DiagnosisMethod',cType.DEFAULT_DIAGNOSIS,@cType.checkDiagnosisMethod);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    % Validate parameters
    param=p.Results;
    if ~data.isDiagnosis
        res.printError(cMessages.DiagnosisNotAvailable);
        return
    end
    if ~cType.getDiagnosisMethod(param.DiagnosisMethod)
        res.printError(cMessages.DiagnosisNotAvailable);
        return
    end
    if isempty(param.State)
        param.State=data.StateNames{2};
    elseif ~data.existState(param.State)
        res.printError(cMessages.InvalidStateName,param.State);
        return
    end
    if strcmp(param.ReferenceState,param.State)
        res.printError(cMessages.InvalidDiagnosisState)
        return
    end
    % Read reference and operation  exergy values
    rex0=data.getExergyData(param.ReferenceState);
    if ~rex0.status
        res.printError(cMessages.InvalidExergyData,param.ReferenceState);
        return
    end
    rex1=data.getExergyData(param.State);
    if ~rex1.status
        res.printError(cMessages.InvalidExergyData,param.State);
        return
    end
    % Read Waste, compute Model FP
    if  data.isWaste
		wd=data.WasteData;
        fp0=cExergyCost(rex0,wd);
        fp1=cExergyCost(rex1,wd);
    else
        fp0=cExergyCost(rex0);
        fp1=cExergyCost(rex1);
    end
    % Execute thermoeconomic diagnosis
    method=cType.getDiagnosisMethod(param.DiagnosisMethod);
    dgn=cDiagnosis(fp0,fp1,method);
    % Get diagnosis results
    if dgn.status
        res=dgn.buildResultInfo(data.FormatData);
    else
        dgn.printLogger;
        res.printError(cMessages.InvalidObject,class(dgn));
        return
    end
    if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
		return
    end
    % Show and Save results if required
    if param.Show
        summaryDiagnosis(res);
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end