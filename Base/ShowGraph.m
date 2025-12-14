function ShowGraph(arg,varargin)
%ShowGraph - Display graphical visualizations of thermoeconomic analysis results.
%   ShowGraph creates and displays specialized graphs for different types of
%   thermoeconomic analysis results. The function automatically selects the
%   appropriate graph type based on the table's characteristics and supports
%   various customization options for styling, variables, and display modes.
%
%   Each result table type has an associated graph renderer:
%   - Cost analysis: Bar/stack charts of exergy costs
%   - Diagnosis: Malfunction visualization with optional output variation
%   - Waste allocation: Distribution of waste costs across processes
%   - Recycling: Cost recycling optimization results
%   - Productive structure: Digraph visualization of flow-process relationships
%   - FP diagram: Fuel-Product structure representation
%   - Summary: Multi-state or multi-sample comparison charts
%   - Resource costs: Cost variation across different scenarios
%
%   Syntax: 
%     ShowGraph(resultSet)
%     ShowGraph(resultSet, 'Graph', graphName)
%     ShowGraph(resultSet, 'Graph', graphName, 'Style', styleType)
%     ShowGraph(resultSet, 'Graph', graphName, 'Variables', varList, 'Cases', caseList)
% 
%   Input Arguments:
%     resultSet - Result container from analysis functions (cResultSet)
%                 Objects typically returned by ExergyAnalysis, ThermoeconomicAnalysis,
%                 ThermoeconomicDiagnosis, WasteAnalysis, or cThermoeconomicModel methods
%
%   Name-Value Arguments:
%     'Graph' - Name of the table/graph to display (char array, default: DefaultGraph property)
%               If not specified, uses the default graph defined in the result set
%               Graph names correspond to table names defined in printformat.json
%               Must be a table that has graphing capabilities (isGraph property = true)
%
%     'ShowOutput' - Display output variation for diagnosis graphs (logical, default: true)
%                    When true, shows both fuel and product variations in diagnosis results
%                    When false, shows only fuel variation
%                    Only applicable to diagnosis graph types (DIAGNOSIS)
%
%     'Style' - Graph style/type for visualization (char array, default: 'BAR')
%               Available styles:
%               'BAR'      - Vertical bar chart (default for most graph types)
%               'STACK'    - Stacked bar chart showing composition
%               'PLOT'     - Line plot for trend visualization
%               'PIE'      - Pie chart for proportional distribution
%               'DIAGRAPH' - Directed graph for flow relationships
%               Style availability depends on the specific graph type being displayed
%
%     'Variables' - Variables to display in summary graphs (char/string/cell array, default: empty)
%                   Specifies which result variables to include in the visualization
%                   Used primarily for Summary and Resource Cost graph types
%                   Examples: 'efficiency', {'cost', 'irreversibility'}
%
%     'Cases' - Specific cases to display from multi-case results (cell array, default: empty)
%               Filters the visualization to show only selected cases/scenarios
%               Used for Summary graphs with multiple states or samples
%
%   Examples:
%     % Display default graph from exergy analysis
%     model = ThermoeconomicModel('cgam_model.json');
%     results = model.exergyAnalysis();
%     ShowGraph(results);
%
%     % Show specific cost graph with stacked style
%     ShowGraph(results, 'Graph', 'dcost', 'Style', 'STACK');
%
%     % Display diagnosis results without output variation
%     diagnosis = model.thermoeconomicDiagnosis();
%     ShowGraph(diagnosis, 'Graph', 'mfc', 'ShowOutput', false);
%
%     % Show summary graph with specific variables
%     summary = SummaryResults(model, 'Group', 'STATES');
%     ShowGraph(summary, 'Graph', 'dfuc', 'Variables', {'WN', 'QV'});
%
%   Live Script Demo:
%     <a href="matlab:open ShowGraphDemo.mlx">Show Graph Demo</a>
%
%   See also ShowResults, ViewResults, cGraphResults, cResultSet, cDigraph,
%   cGraphCost, cGraphDiagnosis, cGraphSummary, ExergyAnalysis
%
	log = cTaesLab();
	% Define custom validator for Variables parameter (accepts char, string, or cell array)
	varchk = @(x) ischar(x) || isstring(x) || iscell(x);
    % Validate required input argument
	if nargin < 1
		log.printError(cMessages.NarginError, cMessages.ShowHelp);
        return
	end	   
    % Ensure input is a valid cResultSet object
	if ~isObject(arg, 'cResultSet')
		log.printError(cMessages.ResultSetRequired, cMessages.ShowHelp);
		return
	end
    % Configure input parser with graph-specific parameters and validation functions
    p = inputParser;
    p.addParameter('Graph', arg.DefaultGraph, @ischar);                % Graph/table name
	p.addParameter('ShowOutput', true, @islogical);                     % Diagnosis output flag
	p.addParameter('Style', cType.DEFAULT_GRAPHSTYLE, @cType.checkGraphStyle);  % Graph style
	p.addParameter('Variables', cType.EMPTY_CELL, varchk);             % Variable selection
	p.addParameter('Cases', cType.EMPTY_CELL, @iscell);                % Case filtering  
    % Parse name-value pairs and handle validation errors
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        return
    end   
	% Extract parsed parameters
	param = p.Results;
    % Navigate to appropriate result set level based on ResultId type
    % RESULT_MODEL contains multiple result sets.
    if arg.ResultId == cType.ResultId.RESULT_MODEL
		% Extract specific result info for the requested graph from model results
		res = arg.getResultInfo(param.Graph);
	else % Already at result info level, use directly
		res = arg;
    end   
    % Verify result info object is valid
    if ~res.status
		printLogger(res)
        log.printError(cMessages.InvalidObject, class(res));
		return
    end   
	% Retrieve the specific table from the result set
	tbl = getTable(res, param.Graph);	
	% Validate table exists and is accessible
	if ~tbl.status
		printLogger(tbl);
		log.printError(cMessages.InvalidTable, param.Graph);
		return
	end	
	% Verify table has graphing capabilities (isGraph property must be true)
	if ~tbl.isGraph
		log.printError(cMessages.InvalidGraph, param.Graph);
		return
	end
	% Instantiate appropriate graph renderer based on table's GraphType property
	% Each graph type has specialized visualization class with specific parameters
	switch tbl.GraphType
        case cType.GraphType.COST
            % Cost distribution graphs (bar/stack charts of exergy costs)
            gr = cGraphCost(tbl);          
		case cType.GraphType.DIAGNOSIS
            % Diagnosis malfunction detection graphs with optional output display
            gr = cGraphDiagnosis(tbl, res.Info, param.ShowOutput);            
		case cType.GraphType.WASTE_ALLOCATION
            % Waste cost allocation and distribution visualization (pie/bar charts)
            gr = cGraphWaste(tbl, res.Info, param.Style);        
        case cType.GraphType.RECYCLING
            % Cost recycling optimization results (plot of recycled costs)
            gr = cGraphRecycling(tbl);           
		case cType.GraphType.DIGRAPH
			% Directed graph of productive structure (flow-process relationships)
			gr = cDigraph(tbl, res.Info);		
		case cType.GraphType.DIAGRAM_FP	
			% Fuel-Product diagram visualization
			gr = cGraphDiagramFP(tbl);			
		case cType.GraphType.SUMMARY
			% Multi-state or multi-sample comparison summary graphs
			gr = cGraphSummary(tbl, res.Info, param);		
		case cType.GraphType.RESOURCE_COST
			% Resource cost variation across different scenarios
			gr = cGraphCostRSC(tbl, res.Info, param.Variables);
	end	
	% Render the graph if successfully created and valid
	if isValid(gr) % Display the graph using the renderer's showGraph method
		gr.showGraph;
	else % Print any error messages from graph creation
		printLogger(gr);
	end
end
