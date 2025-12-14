function res=ProductiveDiagram(data,varargin)
%ProductiveDiagram - Generate graph adjacency tables for productive structure visualization.
%   Creates adjacency tables that describe the plant's productive structure as
%   directed graphs, enabling visualization and network analysis. These tables
%   can be displayed graphically using ShowGraph() or exported for use with
%   external graph software (yEd, Graphviz, Gephi, etc.).
%
%   Productive diagrams represent thermoeconomic relationships as networks:
%     • Flows as nodes (energy/material streams)
%     • Processes as nodes (equipment/components)
%     • Connections showing fuel/product relationships
%     • Multiple graph types for different analysis perspectives
%
%   Five different adjacency representations are generated, each providing
%   unique insights into the productive structure:
%
%   1. Stream-Flow-Process (SFPAT) - Complete productive structure
%      Shows productive groups (streams) connected through flows and processes.
%      Reveals hierarchical production chains from resources to products.
%
%   2. Flow-Process (FPAT) - Flow-Process adjacency matrix
%      Shows direct flow/process relationships between all components.
%
%   3. Flow Graph (FAT) - Flow connections
%      Flow-to-flow connections through intermediate processes.
%      Base of the structural theory of thermoeconomicd
%
%   4. Process Graph (PAT) - Process connections
%      Fuel-Product thermoecononic representation
%      Process-to-process connections through intermediate flows.
%      Shows equipment interaction and dependency structure.
%
%   5. Kernel Graph (KPAT) - Strong component DAG
%      Directed Acyclic Graph (DAG) of strongly connected components:
%       • Nodes represent strongly connected component groups
%       • Each group contains mutually reachable processes/flows
%       • Connections show dependencies between strong components
%     Computed via strong connectivity analysis (cDigraphAnalysis)
%     Eliminates cycles by condensing strongly connected regions
%     Best for hierarchical visualization and dependency analysis
%
%   These adjacency tables support:
%     • Interactive graph visualization with ShowGraph()
%     • Network analysis (shortest paths, cycles, connectivity)
%     • Export to professional graph layout software
%     • Publication-quality diagram generation
%     • Structural analysis and optimization
%
%   Syntax:
%     res = ProductiveDiagram(data)
%     res = ProductiveDiagram(data, Name, Value)
%
%   Input Arguments:
%     data - Data model containing plant productive structure
%       cDataModel object
%       Must be a valid data model created by ReadDataModel or ThermoeconomicModel.
%       Must contain complete ProductiveStructure definition.
%
%   Name-Value Arguments:
%     Show - Display adjacency tables in console
%       true | false (default)
%       When true, prints formatted adjacency matrices showing all connections.
%       Useful for quick inspection of graph structure and connectivity.
%
%     SaveAs - Export adjacency tables to external file
%       char array | string (default: empty)
%       Saves all adjacency tables to file. Supported formats: XLSX, CSV, HTML, JSON, XML.
%       Format determined by file extension.
%       XLSX format recommended for import into graph software (yEd, Gephi).
%       Each adjacency table saved as separate sheet/file.
%
%   Output Arguments:
%     res - cResultInfo object containing all adjacency tables
%
%   ResultInfo:
%     cProductiveDiagram (cType.ResultId.PRODUCTIVE_DIAGRAM)
%
%   Generated Tables:
%     sfpat - Stream-Flow-Process Adjacency Table
%     fpat - Flow-Process Adjacency Table
%     fat - Flow Adjacency Table
%     pat - Process Adjacency Table
%     kpat - Kernel Adjacency Table
%
%   Examples:
%     % Example 1: Generate all productive diagrams
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveDiagram(data);
%     if isValid(res)
%         fprintf('Generated %d adjacency tables\n', res.NrOfTables);
%     end
%
%     % Example 2: Display adjacency tables in console
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveDiagram(data, 'Show', true);
%     % Prints all five adjacency matrices
%
%     % Example 3: Export to Excel for yEd visualization
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveDiagram(data, 'SaveAs', 'cgam_diagrams.xlsx');
%     % Creates Excel file with 5 sheets (sfpat, fpat, fat, pat, kpat)
%     % Import into yEd: File → Import Section → Excel
%
%     % Example 4: Visualize Flow-Process graph interactively
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveDiagram(data);
%     if isValid(res)
%         ShowGraph(res, 'Table', 'fpat');
%         % Opens interactive graph viewer with flow-process diagram
%     end
%
%     % Example 5: Access specific adjacency table
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     res = ProductiveDiagram(data);
%     if isValid(res)
%         processGraph = res.getTable('pat');
%         printTable(processGraph);
%         % Analyze process connectivity
%     end
%
%     % Example 7: Generate and display kernel graph using cDiagraphAnalisis/plot
%     data = ReadDataModel('./Examples/cgam/cgam_model.json');
%     dg = data.ProductiveStructure.ProcessDigraph;
%     dg.plot(cType.DigraphType.KERNEL, 'CGAM Kernel Structure');
%
%   Common Use Cases:
%     • Creating publication-quality productive structure diagrams
%     • Visualizing complex plant topology for presentations
%     • Network analysis of productive relationships
%     • Exporting structure for external graph layout tools
%     • Understanding energy flow paths and dependencies
%     • Identifying bottlenecks and critical components
%     • Documenting system architecture in reports
%
%   Workflow Integration:
%     Productive diagrams are typically generated early in analysis:
%       1. ReadDataModel() - Load plant data
%       2. ProductiveStructure() - Verify structure (optional)
%       3. ProductiveDiagram() - Generate adjacency tables (this function)
%       4. ShowGraph() - Visualize graphs interactively
%       5. ExergyAnalysis() - Calculate flows for diagram annotation
%       6. DiagramFP() - Generate annotated fuel-product diagram
%
%   Graph Type Selection Guidelines:
%     Use SFPAT when:
%       • Need complete hierarchical view
%       • Analyzing productive groups/streams
%       • Complex systems with layered structure
%
%     Use PAT when:
%       • Standard thermoeconomic analysis
%       • Showing fuel/product relationships
%       • Most common diagram format
%
%     Use FAT when:
%       • Tracking energy/material flow paths
%       • Analyzing flow dependencies
%       • Flow-centric perspective needed (structural theory)
%
%     Use FPAT when:
%       • Showing flow/processes relationships
%       • Equipment-centric perspective needed
%
%   Use KPAT when:
%     • Analyzing structural dependencies and hierarchies
%     • Identifying strongly coupled subsystems
%     • Need acyclic representation for topological sorting
%     • Understanding condensed system architecture
%     • Detecting feedback loops and circular dependencies
%
%   Graph Visualization with ShowGraph:
%     After generating adjacency tables, use ShowGraph() for interactive visualization:
%       ShowGraph(res, 'Table', 'fpat');
%       ShowGraph(res, 'Table', 'kpat');
%       ShowGraph(res, 'Table', 'pat');
%
%   External Graph Software Integration:
%     yEd (recommended):
%       1. Export: ProductiveDiagram(data, 'SaveAs', 'diagrams.xlsx');
%       2. Import in yEd: File → Import Section → Excel
%       3. Select sheet (sfpat, fpat, fat, pat, or kpat)
%       4. Apply layout: Layout → Hierarchical/Organic/Circular
%       5. Customize appearance and export as PNG/PDF/SVG
%
%     Graphviz:
%       1. Convert adjacency table to DOT format
%       2. Use dot, neato, or circo for layout
%       3. Generate publication-quality vector graphics
%
%   Error Handling:
%     Returns invalid cResultInfo object if:
%       - Input is not a valid cDataModel object
%       - ProductiveStructure component is invalid or missing
%       - Graph construction fails (disconnected components, invalid structure)
%       - Required flow or process definitions missing
%     Always check res.status or use isValid(res) before accessing results.
%
%   Live Script Demo:
%     <a href="matlab:open ProductiveStructureDemo.mlx">Productive Structure Demo</a>
%
%   See also:
%    ProductiveStructure, DiagramFP, ShowGraph, cDataModel, cProductiveDiagram,
%    cDigraphAnalysis, cResultInfo, SaveResults, ReadDataModel
%
	res=cTaesLab();
	if nargin <1 || ~isObject(data,'cDataModel')
	    res.printError(cMessages.DataModelRequired,cMessages.ShowHelp);
		return
	end
    %Check input parameters
    p = inputParser;
    p.addParameter('Show',false,@islogical);
    p.addParameter('SaveAs',cType.EMPTY_CHAR,@isFilename);
    try
		p.parse(varargin{:});
    catch err
		res.printError(err.message);
        return
    end
    param=p.Results;
	% Get Productive Diagram info
	pd=cProductiveDiagram(data.ProductiveStructure);
    if pd.status
        res=pd.buildResultInfo(data.FormatData);
    else
        pd.printLogger;
        res.printError(cMessages.InvalidObject,class(pd));
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