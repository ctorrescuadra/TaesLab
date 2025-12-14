function res = WasteAnalysis(data,varargin)
%WasteAnalysis - Analyze waste cost allocation and recycling optimization strategies.
%   Performs comprehensive analysis of waste flows in thermoeconomic systems,
%   calculating optimal waste cost allocation based on defined criteria and
%   evaluating the impact of different waste recycling percentages on overall
%   plant costs. This analysis helps identify the most cost-effective waste
%   management strategy and understand how waste treatment affects production costs.
%
%   Waste in thermoeconomic systems represents exergy flows that exit the plant
%   without productive use (emissions, cooling water discharge, etc.). Their costs
%   must be allocated to productive processes to determine true production costs.
%   This function implements the waste allocation methodology to:
%     • Distribute waste costs to processes that generate them
%     • Analyze cost sensitivity to waste recycling percentages (0-100%)
%     • Compare direct (thermodynamic) vs generalized (economic) waste costs
%     • Identify optimal waste treatment levels
%     • Evaluate environmental and economic trade-offs
%
%   Two waste allocation approaches are supported:
%     Standard Allocation - Fixed allocation based on data model criteria
%       • Distributes waste costs according to predefined rules
%       • Shows how waste impacts productive process costs
%       • Provides baseline waste cost distribution
%
%     Recycling Analysis - Parametric study of recycling percentages
%       • Evaluates costs at different waste treatment levels (0-100%)
%       • Identifies optimal recycling percentage
%       • Shows cost trade-offs between waste treatment and production
%
%   Key Calculations:
%     • Waste allocation matrices (how waste costs distribute to processes)
%     • Process costs with internalized waste (true production costs)
%     • Recycling sensitivity curves (cost vs recycling percentage)
%     • Optimal recycling percentage (minimum total cost point)
%     • Marginal cost of waste treatment at different levels
%
%   Syntax:
%     res = WasteAnalysis(data)
%     res = WasteAnalysis(data, Name, Value)
%
%   Input Arguments:
%     data - cDataModel containing plant data with waste definition
%       Must include WasteData section defining waste flows and allocation
%       Requires at least one exergy state for analysis
%       May include ResourcesCost for generalized cost analysis
%
%   Name-Value Arguments:
%     State - Name of operating state to analyze
%       char array | string (default: first state in Exergy data)
%       State must exist in the Exergy data
%       Different states may have different waste characteristics
%
%     CostTables - Type of cost calculations to perform
%       'DIRECT' | 'GENERALIZED' | 'ALL' (default: 'ALL')
%       'DIRECT' - Exergy-based waste costs only (kW/kW)
%       'GENERALIZED' - Monetary waste costs (requires ResourcesCost)
%       'ALL' - Calculate both direct and generalized costs
%
%     Recycling - Enable parametric recycling analysis
%       true | false (default: true)
%       true - Analyzes costs at recycling percentages 0% to 100%
%       false - Shows only standard waste allocation at defined level
%       Recycling analysis reveals optimal waste treatment strategy
%
%     ActiveWaste - Specific waste flow to analyze
%       char array | string (default: first waste flow in model)
%       Must be a valid waste flow key from WasteData
%       Analysis focuses on this waste stream
%       Other waste flows use standard allocation
%
%     ResourceSample - Name of resource cost sample to use
%       char array | string (default: first sample in ResourcesCost)
%       Specifies which set of resource prices for generalized costs
%       Only used when CostTables includes 'GENERALIZED' or 'ALL'
%       Ignored if ResourcesCost data not available
%
%     Show - Display waste analysis results in console
%       true | false (default)
%       When true, prints waste allocation tables and recycling curves
%       Shows optimal recycling percentage if recycling analysis enabled
%
%     SaveAs - Export waste analysis results to file
%       char array | string (default: empty)
%       Saves analysis tables to file
%       Supported formats: XLSX, CSV, HTML, JSON, XML
%       Format determined by file extension
%
%   Output Arguments:
%     res - cResultInfo object containing waste analysis results
%       Contains tables for allocation, recycling analysis, and costs
%
%   ResultInfo:
%     cWasteAnalysis (cType.ResultId.WASTE_ANALYSIS)
%
%   Generated Tables:
%     wd - Waste definition table
%     wa - Waste allocation matrix
%     rad - Recycling analysis direct cost (if Recycling=true)
%     rag - Recycling analysis generalized cost (if Recycling=true)
%
%   Examples:
%
%     % Example 1: Basic waste analysis with recycling (default)
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = WasteAnalysis(data);
%     % Analyzes first waste flow with recycling 0-100%
%
%     % Example 2: Analyze specific waste flow without recycling
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = WasteAnalysis(data, ...
%                         'ActiveWaste', 'QG', ...
%                         'Recycling', false);
%     % Shows only allocation for waste gases
%
%     % Example 3: Generalized cost recycling analysis
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = WasteAnalysis(data, ...
%                         'State', 'REF', ...
%                         'CostTables', 'GENERALIZED', ...
%                         'ResourceSample', 'Base', ...
%                         'Recycling', true);
%     % Economic optimization of waste treatment
%
%     % Example 4: Display results with optimal recycling
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = WasteAnalysis(data, 'Show', true);
%     % Prints allocation tables and recycling curves
%
%     % Example 5: Export recycling analysis to Excel
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = WasteAnalysis(data, ...
%                         'CostTables', 'ALL', ...
%                         'SaveAs', 'waste_recycling.xlsx');
%     % Creates Excel with allocation and recycling tables
%
%   Live Script Demo:
%     <a href="matlab:open RecyclingAnalysisDemo.mlx">Recycling Analysis Demo</a>
%
%   Common Use Cases:
%     • Determining economically optimal waste treatment level
%     • Evaluating environmental compliance costs
%     • Allocating waste disposal costs to product costs
%     • Comparing waste management alternatives
%     • Optimizing combined heat and power waste heat recovery
%     • Assessing trade-offs between production and environmental costs
%     • Supporting environmental economic decision-making
%
%   Workflow Integration:
%     Typical waste analysis sequence:
%       1. ReadDataModel() - Load plant data with waste definitions
%       2. ProductiveStructure() - Verify topology includes waste flows
%       3. ExergyAnalysis() - Calculate thermodynamic performance
%       4. ThermoeconomicAnalysis() - Calculate baseline costs
%       5. WasteAnalysis() - Optimize waste allocation and recycling (this function)
%
%   Cost Table Selection Guidelines:
%     Use 'DIRECT' when:
%       • Pure thermodynamic waste optimization
%       • Resource costs unavailable
%       • Initial screening of waste management options
%       • Comparing exergy efficiency of alternatives
%
%     Use 'GENERALIZED' when:
%       • Economic optimization is primary goal
%       • Resource and treatment costs are available
%       • Environmental compliance costs included
%       • Business decision-making requires monetary values
%
%     Use 'ALL' when:
%       • Comprehensive analysis needed
%       • Both thermodynamic and economic perspectives required
%       • Comparing physical and economic optimums
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       • Input is not a valid cDataModel object
%       • Data model does not include WasteData section
%       • Specified state does not exist in data model
%       • Exergy data missing or invalid for the state
%       • ActiveWaste specified but not found in WasteData
%       • ResourcesCost missing when GENERALIZED costs requested
%       • Waste allocation calculation fails
%     Always check res.status or use isValid(res) before using results.
%
%   Theoretical Background:
%     Waste cost allocation follows principles from:
%       Torres, C. & Valero, A. "The Exergy Cost Theory Revisited"
%       Energies, 2021. DOI: 10.3390/en14061594
%
%   See also:
%     ReadDataModel, cDataModel, cWasteAnalysis, cWasteData, cExergyCost,
%     ThermoeconomicAnalysis, cResultInfo, ShowResults, SaveResults
%
    res=cTaesLab();
	if nargin <1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
    if ~data.isWaste
	    res.printError(cMessages.NoWasteModel)
        return
    end
    % Check and initialize parameters
    p = inputParser;
    p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('ResourceSample',cType.EMPTY_CHAR,@ischar);
	p.addParameter('CostTables',cType.DEFAULT_COST_TABLES,@cType.checkCostTables);
    p.addParameter('Recycling',true,@islogical);
    p.addParameter('ActiveWaste',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
        p.parse(varargin{:});
    catch err
        res.printError(err.message);
        return
    end
    param=p.Results;
    % Read waste info
    wd=data.WasteData;
    if ~wd.status
        wd.printLogger;
        res.printError(cMessages.InvalidObject,class(wd));
        return
    end
    % Check Waste Key
    if isempty(param.ActiveWaste)
        param.ActiveWaste=data.WasteFlows{1};
    end
    wid=wd.getWasteIndex(param.ActiveWaste);
    if ~wid
        res.printError(cMessages.InvalidWasteFlow,param.ActiveWaste);
        return
    end
    % Read exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
        ex.printLogger;
        res.printError(cMessages.InvalidExergyData,param.State);
        return
	end
	% Compute the Model FPR
    fpm=cExergyCost(ex,wd);
    if ~fpm.status
        fpm.printLogger;
        res.printError(cMessages.InvalidObject,class(fpm));
    end
    % Read external resources and get results
	pct=cType.getCostTables(param.CostTables);
	param.DirectCost=bitget(pct,cType.DIRECT);
	param.GeneralCost=bitget(pct,cType.GENERALIZED);
    if param.Recycling   
        if data.isResourceCost && param.GeneralCost
            if isempty(param.ResourceSample)
			    param.ResourceSample=data.SampleNames{1};
            end
		    rsd=data.getResourceData(param.ResourceSample);
            if ~rsd.status
			    rsd.printLogger;
			    res.printError(cMessages.InvalidResourceCost);
			    return
            end
            ra=cWasteAnalysis(fpm,true,param.ActiveWaste,rsd);
        else
            ra=cWasteAnalysis(fpm,true,param.ActiveWaste); 
        end
    else
        ra=cWasteAnalysis(fpm,false,param.ActiveWaste); 
    end
    % Execute recycling analysis
    if ra.status
        res=ra.buildResultInfo(data.FormatData,param);
    else
        ra.printLogger;
        res.printError(cMessages.InvalidWasteAnalysis);
    end
    if ~res.status
		res.printLogger;
        res.printError(cMessages.InvalidObject,class(res));
		return
    end
    % Show and Save results if required
    if param.Show
        printResults(res);
    end
    if ~isempty(param.SaveAs)
        SaveResults(res,param.SaveAs);
    end
end
