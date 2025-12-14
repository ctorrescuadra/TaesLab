function res = SummaryResults(data,varargin)
%SummaryResults - Generate comparative summary tables across multiple operating conditions.
%   Creates comprehensive summary tables that compare thermoeconomic performance
%   across different plant states or resource cost scenarios. This enables systematic
%   evaluation of how operating conditions, seasonal variations, or economic factors
%   affect plant efficiency, costs, and profitability.
%
%   Summary analysis consolidates key performance indicators from multiple scenarios
%   into unified comparison tables, revealing:
%     • Performance trends across operating conditions
%     • Impact of resource price variations on economics
%     • Identification of best/worst operating scenarios
%     • Sensitivity of costs to external factors
%     • Comparative efficiency metrics for decision-making
%
%   Two types of comparative analysis are supported:
%
%   STATES Summary - Compare different operating states
%     • Analyzes multiple plant operating conditions
%     • Shows how thermodynamic efficiency varies across states
%     • Compares costs with fixed external costs
%     • Example: Design vs Summer vs Winter operation
%
%   RESOURCES Summary - Compare different resource cost scenarios
%     • Analyzes single state with varying external resources costs
%     • Shows economic sensitivity to fuel/electricity price changes
%     • Compares profitability under different market conditions
%     • Example: Base case vs High fuel cost vs Low electricity price
%
%   The data model must define multiple states (for STATES summary) or multiple
%   resource cost samples (for RESOURCES summary) to enable comparison.
%
%   Key Features:
%     • Side-by-side comparison of all scenarios in single tables
%     • Automatic calculation of exergy, costs, and unit costs
%     • Both direct (thermodynamic) and generalized (economic) costs
%     • Process-level and flow-level comparisons
%     • Identifies maximum, minimum, and average values
%     • Supports export to Excel for detailed analysis
%
%   Syntax:
%     res = SummaryResults(data)
%     res = SummaryResults(data, Name, Value)
%
%   Input Arguments:
%     data - cDataModel containing plant data with multiple scenarios
%       For STATES summary: Must include multiple exergy states
%       For RESOURCES summary: Must include multiple ResourcesCost samples
%       Should have complete exergy and cost data for meaningful comparison
%
%   Name-Value Arguments:
%     Summary - Type of summary analysis to perform
%       'NONE' | 'STATES' | 'RESOURCES' | 'ALL' (default: from data model)
%       'NONE' - No summary generated (returns empty)
%       'STATES' - Compare different operating states
%       'RESOURCES' - Compare different resource cost scenarios
%       'ALL' - Generate both types of summaries
%       Default determined by data model SummaryOptions
%
%     State - Reference state for RESOURCES summary
%       char array | string (default: first state in data)
%       Used when Summary='RESOURCES' or 'ALL'
%       Fixes operating state while varying resource costs
%       Ignored for STATES summary
%
%     ResourceSample - Reference resource sample for STATES summary
%       char array | string (default: first sample in ResourcesCost)
%       Used when Summary='STATES' or 'ALL'
%       Fixes resource costs while varying operating states
%       Ignored for RESOURCES summary
%       Not used if ResourcesCost data unavailable
%
%     Show - Display summary tables in console
%       true | false (default)
%       When true, prints formatted comparison tables
%       Shows all states/samples side-by-side
%       Highlights key differences and trends
%
%     SaveAs - Export summary results to file
%       char array | string (default: empty)
%       Saves comparison tables to file
%       Supported formats: XLSX, CSV, HTML, JSON, XML
%       Format determined by file extension
%       Excel format recommended for multi-table summaries
%
%   Output Arguments:
%     res - cResultInfo object containing summary tables
%       May contain single summary type or both (STATES and RESOURCES)
%
%   ResultInfo:
%     cSummaryResults (cType.ResultId.SUMMARY_RESULTS)
%
%   Generated Tables for STATES Summary:
%     exergy - Exergy values across states
%     pku - Process unit consumption across states
%     dpc - Direct process costs across states
%     dpuc - Direct unit process costs across states
%     dfc - Direct flow costs across states
%     dfuc - Direct unit flow costs across states
%   Additional Tables (if ResourcesCost available):
%     gpc - Generalized process costs across states
%     gpuc - Generalized unit process costs across states
%     gfc - Generalized flow costs across states
%     gfuc - Generalized unit flow costs across states
%   Generated Tables for RESOURCES Summary:
%     rgpc - Generalized process costs across resource scenarios
%     rgpuc - Generalized unit process costs across scenarios
%     rgfc - Generalized flow costs across resource scenarios
%     rgfuc - Generalized unit flow costs across scenarios
%
%   Examples:
%
%     % Example 1: Compare operating states (default behavior)
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data);
%     % Compares all states with default resource costs
%
%     % Example 2: Compare resource cost scenarios
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data, ...
%                          'Summary', 'RESOURCES', ...
%                          'State', 'REF');
%     % Shows cost variations with different resource prices
%
%     % Example 3: Generate both summaries
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data, 'Summary', 'ALL');
%     % Creates both STATES and RESOURCES comparisons
%
%     % Example 4: Display results in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data, 'Show', true);
%     % Prints formatted comparison tables
%
%     % Example 5: Export to Excel for detailed analysis
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data, ...
%                          'Summary', 'ALL', ...
%                          'SaveAs', 'plant_summary.xlsx');
%     % Creates Excel file with all comparison tables
%
%     % Example 6: Access specific summary table
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = SummaryResults(data, 'Summary', 'STATES');
%     if isValid(res)
%         unitCosts = res.getTable('dpuc');
%         printTable(unitCosts);
%         % Analyze unit cost variations across states
%     end
%
%   Live Script Demo:
%     <a href="matlab:open SummaryResultsDemo.mlx">Summary Results Demo</a>
%
%   Common Use Cases:
%     • Seasonal performance comparison (winter vs summer operation)
%     • Equipment degradation tracking (design vs degraded states)
%     • Part-load performance evaluation (100%, 75%, 50% load)
%     • Fuel price sensitivity analysis for procurement decisions
%     • Economic scenario planning (optimistic, base, pessimistic)
%     • Multi-year performance trending
%     • Optimization of operating strategy across conditions
%
%   Workflow Integration:
%     Typical summary analysis sequence:
%       1. ReadDataModel() - Load plant data with multiple states/samples
%       2. ExergyAnalysis() - Calculate performance for each scenario
%       3. ThermoeconomicAnalysis() - Calculate costs for each scenario
%       4. SummaryResults() - Compare all scenarios (this function)
%       5. Analyze trends to identify optimal conditions
%       6. Make operational or investment decisions based on comparison
%
%   Summary Type Selection Guidelines:
%     Use 'STATES' when:
%       • Comparing different operating conditions
%       • Evaluating part-load performance
%       • Analyzing seasonal variations
%       • Tracking degradation over time
%       • Optimizing operating strategy
%       • Fixed economic conditions, varying operations
%
%     Use 'RESOURCES' when:
%       • Fuel/electricity price uncertainty
%       • Economic scenario planning
%       • Procurement contract evaluation
%       • Market condition sensitivity
%       • Financial risk assessment
%       • Fixed operations, varying economics
%
%     Use 'ALL' when:
%       • Comprehensive analysis needed
%       • Both operational and economic optimization
%       • Complete scenario matrix evaluation
%       • Strategic planning with multiple variables
%
%   Interpretation Guidelines:
%     STATES Summary Analysis:
%       • Compare unit costs (dpuc, gpuc) across states
%       • Lower unit costs indicate better efficiency
%       • Large variations suggest sensitivity to conditions
%       • Best state has lowest total cost for objectives
%
%     RESOURCES Summary Analysis:
%       • Compare cost changes across price scenarios
%       • Steep variations indicate high economic risk
%       • Flat profiles suggest cost stability
%       • Use for hedging and contract strategies
%
%     Trend Identification:
%       • Monotonic trends: Clear directional relationship
%       • Non-monotonic: Complex interactions, optimal interior point
%       • Outliers: Unusual conditions requiring investigation
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       • Input is not a valid cDataModel object
%       • Summary type not available (insufficient states/samples)
%       • Specified state does not exist
%       • Specified ResourceSample does not exist
%       • Summary option not enabled in data model
%       • Required exergy or cost data missing
%       • Calculation fails for any scenario
%     Always check res.status or use isValid(res) before using results.
%
%   Data Requirements:
%     For STATES Summary:
%       • Multiple exergy states defined in data model
%       • Each state must have complete exergy data
%       • Consistent productive structure across states
%       • Optional: ResourcesCost for generalized costs
%
%     For RESOURCES Summary:
%       • Multiple ResourcesCost samples defined
%       • Each sample with complete resource pricing
%       • At least one exergy state
%       • Consistent resource definition across samples
%
%   See also:
%     ReadDataModel, cDataModel, cSummaryResults, cThermoeconomicModel,
%     ExergyAnalysis, ThermoeconomicAnalysis, cResultInfo, ShowResults, SaveResults
%
    res=cTaesLab();
    % Check data model
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
    sopt=data.SummaryOptions;
    if sopt.isEnable
        doption=sopt.defaultOption;
    else
        res.printError(cMessages.SummaryNotAvailable);
        return
    end
    %Check and initialize parameters
    p = inputParser;
    p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Summary',doption,@sopt.checkName);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    % Preparing parameters
    param=p.Results;
    if ~cType.getSummaryId(param.Summary)
        res.printError(cMessages.SummaryNotAvailable);
        return
    end
    if data.isResourceCost
        if isempty(param.ResourceSample)
            param.ResourceSample=data.SampleNames{1};
        elseif ~data.existSample(param.ResourceSample)
            res.printError(cMessages.InvalidResourceName,param.ResourceSample);
        end
    end
    % Get the summary results from the thermoeconomic model
    model=cThermoeconomicModel(data,...
            'ResourceSample',param.ResourceSample,...
            'State',param.State,...
            'Summary',param.Summary);
    res=model.summaryResults;
    if isempty(res)
        model.printError(cMessages.SummaryNotAvailable);
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end