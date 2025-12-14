function res = ThermoeconomicAnalysis(data, varargin)
%ThermoeconomicAnalysis - Perform thermoeconomic cost analysis of a plant operating state.
%   Calculates exergy costs for all flows and processes using cost allocation
%   theory based on the productive structure. Determines how exergy destruction
%   (irreversibilities) and resource costs propagate through the plant to establish
%   the true thermoeconomic cost of each product.
%
%   This function implements two diferent types of cost:
%     - Direct Exergy Cost - Cost based solely on exergy consumption (kW/kW)
%     - Generalized Cost - Cost including external resource cost
%
%   The analysis uses the Fuel-Product (FP) formulation to distribute costs
%   according to the productive structure, revealing which processes contribute
%   most to final product costs and where improvement efforts should focus.
%   
%   If several resources are used analyze the contribution of each individual
%   resource to the production cost (direct and geenralized)
%
%   Key Calculations:
%     - Unit exergy costs for all flows (cost per unit of exergy)
%     - Process fuel and product costs (total exergy consumed/produced)
%     - Irreversibility Costs Tables (cost impact of exergy destruction)
%     - Cost allocation matrices (how costs flow between processes)
%     - Fuel-Product-Waste cost tables
%
%   Syntax:
%     res = ThermoeconomicAnalysis(data)
%     res = ThermoeconomicAnalysis(data, Name, Value)
%
%   Input Arguments:
%     data - cDataModel containing thr data model.
%       For generalized costs, must also include ResourcesCost data.
%
%   Name-Value Arguments:
%     State - Name of the operating state to analyze
%       char array | string (default: first state in Exergy data)
%       State must exist in the Exergy data
%
%     CostTables - Type of cost calculations to perform:
%       'DIRECT' | 'GENERALIZED' | 'ALL' (default: 'ALL')
%       'DIRECT' - Calculate exergy-based costs only (kW/kW)
%       'GENERALIZED' - Calculate monetary costs (requires ResourcesCost data)
%       'ALL' - Calculate both direct and generalized costs
%
%     ResourceSample - Name of resource cost sample to use
%       char array | string (default: first sample in ResourcesCost)
%       Specifies which set of resource prices to apply for generalized costs.
%       Only used when CostTables includes 'GENERALIZED' or 'ALL'.
%       Ignored if ResourcesCost data is not available.
%
%     Show - Display thermoeconomic analysis results in console
%       true | false (default)
%       When true, prints formatted tables with costs, unit costs, and
%       cost allocation matrices for all processes and flows.
%
%     SaveAs - Export thermoeconomic analysis results to external file
%       char array | string (default: empty)
%       Saves analysis tables to file. Supported formats: XLSX, CSV, HTML, JSON, XML.
%       Format is determined by file extension.
%
%   Output Arguments:
%     res - cResultInfo object containig exergy cost analysis info.
%
%   ResultInfo:
%     cExergyCost (cType.ResultId.THERMOECONOMIC_ANALISIS)
%
%   Generated Tables (Direct Exergy Cost):
%     dfcost - Direct exergy cost of flows
%     dcost - Direct exergy cost of processes
%     udcost - Unit direct exergy cost of processeS
%     dict - Irreversibility Cost Table
%     dfict - Flows Irreversibility Cost Table
%     dcfp - Fuel-Product direct cost table
%     dcfpr - Fuel-Product direct cost table including waste
%     dfrsc  - Flows direct cost Resource Decomposition table                        
%     dprsc  - Processes direct cost Resource Decomposition table 
%
%   Generated Tables (Generalized Cost):
%     gfcost - Generalized cost of flows
%     gcost  - Generalized cost of processes
%     ugcost - Unit generalized cost of processes
%     gict   - Irreversibility generalized cost table
%     gfict  - Flows irreversibility generalized cost table
%     gcfp   - Fuel-Product generalized cost table
%     gfrsc  - Flows genralized cost Resource Decomposition table                        
%     gprsc  - Processes generalized cost Resource Decomposition table              
%
%   Examples:
%
%     % Example 1: Calculate only direct exergy costs (default)
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicAnalysis(data);
%
%     % Example 2: Calculate generalized cost for a specific state/sample
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicAnalysis(data, ...
%                                   'State', 'REF', ...
%                                   'CostTables', 'GENERALIZED', ...
%                                   'ResourceSample', 'Base');
%
%     % Example 3: Display results in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicAnalysis(data, 'Show', true);
%     % Prints all cost tables with formatted output
%
%     % Example 4: Export analysis to Excel
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicAnalysis(data, ...
%                                   'CostTables', 'ALL', ...
%                                   'SaveAs', 'cgam_costs.xlsx');
%     % Creates Excel file with sheets for each cost table
%
%     % Example 5: Access specific tables programmatically
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ThermoeconomicAnalysis(data, 'CostTables', 'DIRECT');
%     if isValid(res)
%         processCosts = res.getTable('dcost');
%         printTables(processCost);
%     end
%
%   Live Script Demo:
%     <a href="matlab:open ThermoeconomicAnalysisDemo.mlx">Thermoeconomic Analysis Demo</a>
%
%   Common Use Cases:
%     - Identifying processes with highest cost impact
%     - Determining unit production costs for plant products
%     - Evaluating cost-effectiveness of equipment improvements
%     - Allocating costs to multiple products in cogeneration plants
%     - Calculating the cost of exergy destruction
%     - Analyze the contibution of multiple resources to the production cost
%
%   Workflow Integration:
%     Typical analysis sequence:
%       1. ReadDataModel() - Load plant data with exergy and cost information
%       2. ProductiveStructure() - Verify topology (optional)
%       3. ExergyAnalysis() - Calculate thermodynamic performance
%       4. ThermoeconomicAnalysis() - Calculate costs (this function)
%       5. ThermoeconomicDiagnosis() - Identify malfunctions and cost impacts
%
%   Cost Table Selection Guidelines:
%     Use 'DIRECT' when:
%       • Resource cost data is not available
%       • Comparing purely thermodynamic efficiency
%       • Initial screening of process performance
%     
%     Use 'GENERALIZED' when:
%       • Resource cost are available
%       • Economic or environmental optimization is the goal
%       • Comparing different resource scenarios
%     
%     Use 'ALL' when:
%       • Comprehensive analysis needed
%       • Both thermodynamic and economic perspectives required
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       • Input is not a valid cDataModel object
%       • Specified state does not exist in the data model
%       • Exergy data is missing or invalid for the state
%       • ResourcesCost data missing when GENERALIZED costs requested
%       • Specified ResourceSample does not exist
%       • Cost calculation fails (singular FP matrix, etc.)
%     Always check res.status or use isValid(res) before using results.
%
%   Theoretical Background:
%     Torres, C. & Valero, A. "The Exergy Cost Theory Revisited"
%     Energies, 2021. DOI: 10.3390/en14061594.
%
%     Valero A, Torres C. Circular thermoeconomics: A waste cost accounting theory.
%     In: Feidt M, A. Valero, editors. Advances in thermodynamics and circular. London: ISTE-Wiley; 2024, p. 151–213.
%     ISBN: 978-1-78945-126-9
%
%   See also:
%     ReadDataModel, cDataModel, cExergyCost, cExergyModel,
%     cResourceData, cWasteData, cResultInfo, ShowResults, SaveResults
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
    p.addParameter('ResourceSample', cType.EMPTY_CHAR, @ischar);
    p.addParameter('CostTables', cType.DEFAULT_COST_TABLES, @cType.checkCostTables);
    p.addParameter('Show', false, @islogical);
    p.addParameter('SaveAs', cType.EMPTY_CHAR, @isfilename);
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
    
    % Create exergy cost model (include waste data if available)
    if data.NrOfWastes > 0
        fpm = cExergyCost(ex, data.WasteData); 
    else
        fpm = cExergyCost(ex);
    end
    fpm.printLogger;
    if ~fpm.status
        res.printError(cMessages.InvalidObject, class(fpm))
        return
    end
    
    % Determine which cost types to calculate and process resource costs
    pct = cType.getCostTables(param.CostTables);
    param.DirectCost = bitget(pct, cType.DIRECT);
    param.GeneralCost = bitget(pct, cType.GENERALIZED);
    
    % Load and apply resource cost data if generalized costs requested
    if data.isResourceCost && param.GeneralCost
        if isempty(param.ResourceSample)
            param.ResourceSample = data.SampleNames{1};
        end
        rd = data.getResourceData(param.ResourceSample);
        if ~rd.status
            rd.printLogger;
            rd.printError(cMessages.InvalidResourceData, param.ResourceSample);
        end
        param.ResourcesCost = rd;
        rd.setResourceCost(fpm);
    end
    
    % Build result info container with calculated cost tables
    res = fpm.buildResultInfo(data.FormatData, param);
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