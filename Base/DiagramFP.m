function res=DiagramFP(data,varargin)
%DiagramFP - Generate annotated fuel-product diagrams with exergy flows and costs.
%   Creates comprehensive fuel-product (FP) diagrams that combine productive
%   structure with calculated exergy flows and direct costs for a specific
%   operating state. These diagrams can be visualized interactively using
%   ShowGraph() or exported for professional graph layout software (yEd, Graphviz).
%
%   FP diagrams extend productive structure by adding quantitative information:
%     • Exergy flow magnitudes (kW, MW, etc.)
%     • Direct exergy costs (kW/kW, dimensionless)
%     • Process fuel and product values
%     • Component-based grouping for complex systems
%     • Both detailed and simplified kernel representations
%   These tables support:
%     • State-specific performance visualization
%     • Exergy flow tracking through system
%     • Direct cost formation analysis
%     • Interactive diagram exploration with ShowGraph()
%     • Export to professional layout software
%     • Publication-quality annotated diagrams
%
%   Syntax:
%     res = DiagramFP(data)
%     res = DiagramFP(data, Name, Value)
%
%   Input Arguments:
%     data - Data model containing plant structure and exergy data
%       cDataModel object
%       Must be a valid data model created by ReadDataModel or ThermoeconomicModel
%       Must contain exergy data for at least one operating state
%
%   Name-Value Arguments:
%     State - Operating state for diagram generation
%       char array | string (default: first state in data)
%       Must match a state name defined in ExergyStates
%       Determines which exergy values are used for diagram annotation
%       Different states show different operating conditions
%
%     Show - Display diagram tables in console
%       true | false (default)
%       When true, prints formatted tables with exergy and cost values
%       Useful for quick inspection of flow magnitudes and costs
%
%     SaveAs - Export diagram tables to external file
%       char array | string (default: empty)
%       Saves all FP diagram tables to file
%       Supported formats: XLSX, CSV, HTML, JSON, XML
%       Format determined by file extension
%       XLSX format recommended for graph software import
%       Each table saved as separate sheet/file
%
%   Output Arguments:
%     res - cResultInfo object containing all FP diagram tables
%
%   ResultInfo:
%     cDiagramFP (cType.ResultId.DIAGRAM_FP)
%
%   Generated Tables:
%     atfp - Diagram FP adjacency table (exergy-weighted graph)
%     atcfp - Cost Diagram FP adjacency table (cost-weighted graph)
%     katfp - Kernel Diagram FP adjacency table (simplified exergy graph)
%     katcfp - Kernel Cost Diagram FP adjacency table (simplified cost graph)
%     tfp - Table FP (exergy fuel-product table)
%     ktfp - Kernel Table FP (simplified exergy table)
%     dcfp - Direct Cost Table FP (cost fuel-product table)
%     kdcfp - Kernel Direct Cost Table FP (simplified cost table)
%     grps - Process Groups table (component mapping)
%
%   Examples:
%     % Example 1: Generate FP diagrams for default state
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data);
%     if isValid(res)
%         fprintf('Generated %d FP diagram tables\n', res.NrOfTables);
%     end
%
%     % Example 2: Generate diagrams for specific operating state
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data, 'State', 'design');
%     % Uses exergy values from 'design' state
%
%     % Example 3: Display FP tables in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data, 'State', 'design', 'Show', true);
%     % Prints all tables with exergy flows and costs
%
%     % Example 4: Export to Excel for yEd visualization
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data, 'SaveAs', 'cgam_fp_diagrams.xlsx');
%     % Creates Excel file with 9 sheets
%     % Import adjacency tables (atfp, atcfp, katfp, katcfp) into yEd
%
%     % Example 5: Visualize exergy flow diagram interactively
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data, 'State', 'design');
%     if isValid(res)
%         ShowGraph(res, 'Table', 'atfp');
%     end
%
%     % Example 6: Visualize cost formation diagram
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data);
%     if isValid(res)
%         ShowGraph(res, 'Table', 'atcfp');
%     end
%
%     % Example 7: Access and analyze fuel-product table
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data, 'State', 'REF');
%     if isValid(res)
%         ShowResults(res,'Table','tfp')
%
%     % Example 8: Generate simplified kernel diagram for complex system
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = DiagramFP(data);
%     if isValid(res)
%         ShowGraph(res, 'Table', 'katfp');
%     end
%
%   Common Use Cases:
%     • State-specific performance visualization
%     • Exergy flow tracking and Sankey diagrams
%     • Direct cost formation analysis
%     • Publication-quality annotated FP diagrams
%     • Comparing different operating conditions
%     • Identifying exergy destruction locations
%     • Cost propagation visualization
%     • Educational presentations of thermoeconomic theory
%
%   Workflow Integration:
%     FP diagrams are generated after exergy analysis:
%       1. ReadDataModel() - Load plant data
%       2. ExergyAnalysis() - Calculate exergy flows
%       3. DiagramFP() - Generate annotated diagrams (this function)
%       4. ShowGraph() - Visualize with interactive layouts
%       5. ThermoeconomicAnalysis() - Calculate generalized costs
%       6. Compare diagrams across different states
%
%   Diagram Types:
%
%	1. Adjacency Matrix	
%      atfp - Diagram FP adjacency table with exergy flows
%        Process-to-process connections weighted by exergy
%        Standard fuel-product graph representation
%        Used for interactive visualization
%
%      atcfp - Cost Diagram FP adjacency table with direct costs
%        Process-to-process connections weighted by exergy costs
%        Shows cost formation through productive structure
%        Reveals cost accumulation paths
%
%      katfp - Kernel Diagram FP adjacency table (simplified)
%        Condensed DAG with strongly connected components grouped
%        Exergy-weighted connections between components
%        Clearer visualization for complex systems
%
%      katcfp - Kernel Cost Diagram FP adjacency table (simplified)
%        Condensed DAG with cost-weighted connections
%        Component-level cost relationships
%        Hierarchical cost structure
%
%   2. Fuel-Product Tables (Matrix Representations):
%      tfp - Table FP with exergy flows
%		 Fuel-product table format
%        exergy flows values in system units
%
%      ktfp - Kernel Table FP (simplified)
%        Component-aggregated fuel-product table
%        Reduced complexity for large systems
%        Preserves essential productive relationships
%
%      dcfp - Direct Cost Table FP
%        Process-flow costs in exergy terms
%        Shows exergy cost formation
%
%      kdcfp - Kernel Direct Cost Table FP (simplified)
%        Component-level cost table
%        Aggregated cost relationships
%        Simplified cost structure
%
%   3. Component Grouping:
%      grps - Process Groups table
%        Maps processes to strongly connected components
%        Identifies circular dependencies
%        Used for component-based analysis
%
%   Diagram Type Selection Guidelines:
%     Use atfp (exergy adjacency) when:
%       • Visualizing energy flow magnitudes
%       • Creating Sankey-style flow diagrams
%       • Identifying major energy paths
%       • Analyzing flow distribution
%
%     Use atcfp (cost adjacency) when:
%       • Analyzing exergy cost formation
%       • Tracking cost propagation
%       • Identifying high-cost processes
%       • Understanding cost structure
%
%     Use katfp/katcfp (kernel) when:
%       • System has many processes (20+)
%       • Need simplified overview
%       • Circular dependencies present
%       • Publication clarity priority
%
%     Use tfp/dcfp (tables) when:
%       • Need numerical values for calculations
%       • Exporting to other analysis tools
%       • Detailed quantitative analysis
%       • Validation and verification
%
%   Visualization with ShowGraph:
%     After generating FP diagrams, use ShowGraph() for interactive visualization:
%       ShowGraph(res, 'Table', 'atfp');
%       ShowGraph(res, 'Table', 'atcfp');
%       ShowGraph(res, 'Table', 'katfp');
%
%   External Graph Software Integration:
%     yEd (recommended for FP diagrams):
%       1. Export: DiagramFP(data, 'SaveAs', 'fp_diagrams.xlsx');
%       2. Import in yEd: File → Import Section → Excel
%       3. Select adjacency sheet (atfp, atcfp, katfp, or katcfp)
%       4. Apply hierarchical layout: Layout → Hierarchical
%       5. Edge thickness by weight for flow visualization
%       6. Color edges by weight for cost visualization
%       7. Export as SVG/PDF for publications
%
%     Graphviz (for automated layouts):
%       1. Export adjacency table to DOT format
%       2. Use 'dot' algorithm for hierarchical layout
%       3. Edge labels show exergy/cost values
%       4. Generate high-resolution graphics
%
%     Sankey diagram tools:
%       1. Use tfp table data for flow values
%       2. Import into Sankey generators (D3.js, Plotly, etc.)
%       3. Visualize exergy flows as proportional bands
%       4. Interactive web-based presentations
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       - Input is not a valid cDataModel object
%       - Specified state does not exist
%       - Exergy data invalid or missing for state
%       - Productive structure incomplete
%       - Exergy cost calculation fails
%     Always check res.status or use isValid(res) before accessing results.
%
%   Live Script Demo:
%     <a href="matlab:open DiagramFpDemo.mlx">Diagram FP Demo</a>
%
%   See also:
%     ProductiveDiagram, ExergyAnalysis, ThermoeconomicAnalysis, ShowGraph,
%     cDiagramFP, cExergyCost, cDataModel, cResultInfo, SaveResults
%
	res=cTaesLab();
	if nargin<1 || ~isObject(data,'cDataModel')
		res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
	% Check input parameters
	p = inputParser;
	p.addParameter('State',data.StateNames{1},@data.existState);
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
	try
		p.parse(varargin{:});
	catch err
		res.printError(err.message);
		return
	end
	param=p.Results;
	% Read and check exergy values
	ex=data.getExergyData(param.State);
	if ~ex.status
        ex.printLogger;
		res.printError(cMessages.InvalidExergyData,param.State);
        return
	end	
	% Get FP Diagram model and set results
	pm=cExergyCost(ex);
    dfp=cDiagramFP(pm);
    if ~dfp.status
        dfp.printLogger;
        res.printError(cMessages.InvalidObject,class(dfp));
		return
    end
	res=dfp.buildResultInfo(data.FormatData);
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