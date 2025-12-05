function ShowGraph(arg,varargin)
%ShowGraph - Show the graph associated to a results table.
%	Depending on the graph, additional options could be used.
%
%   Syntax: 
%     ShowGraph(arg,Name,Value)
% 
%   Input Arguments:
%     arg - cResultSet object
%
%   Name-Value Arguments:
%     Graph: Name of the table
%       char array
%     ShowOutput: Show Output variation.Use for Diagnosis tables. 
%       false | true (default)
%     Style: Style of the graph.
%	   'BAR' | 'STACK' | 'PLOT' | 'PIE' | 'DIAGRAPH'
%     Variables: Variables used in Summary results. 
%       cell array
%
%   Example:
%     <a href="matlab:open ShowGraphDemo.mlx">Show Graph Demo</a>
%
%   See also cGraphResults, cResultSet
%
	varchk=@(x) ischar(x) || isstring(x) || iscell(x);
    log=cTaesLab();
	if nargin < 1
		log.printError(cMessages.NarginError,cMessages.ShowHelp);
        return
	end	
	if ~isObject(arg,'cResultSet')
		log.printError(cMessages.ResultSetRequired,cMessages.ShowHelp);
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Graph',arg.DefaultGraph,@ischar);
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Style',cType.DEFAULT_GRAPHSTYLE,@cType.checkGraphStyle);
	p.addParameter('Variables',cType.EMPTY_CELL,varchk);
	p.addParameter('Cases',cType.EMPTY_CELL,@iscell);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        return
    end
	param=p.Results;
    % Get the resultId and table value
    if arg.ResultId==cType.ResultId.RESULT_MODEL
		res=arg.getResultInfo(param.Graph);
	else
		res=arg;
    end
    if ~res.status
		printLogger(res)
        log.printError(cMessages.InvalidObject,class(res));
		return
    end
	tbl=getTable(res,param.Graph);
	if ~tbl.status
		printLogger(tbl);
		log.printError(cMessages.InvalidTable,param.Graph);
		return
	end
	if ~tbl.isGraph
		log.printError(cMessages.InvalidGraph,param.Graph);
		return
	end
	% Create Graph
	switch tbl.GraphType
        case cType.GraphType.COST
            gr=cGraphCost(tbl);
		case cType.GraphType.DIAGNOSIS
            gr=cGraphDiagnosis(tbl,res.Info,param.ShowOutput);
		case cType.GraphType.WASTE_ALLOCATION
            gr=cGraphWaste(tbl,res.Info,param.Style);
        case cType.GraphType.RECYCLING
            gr=cGraphRecycling(tbl);
		case cType.GraphType.DIGRAPH
			gr=cDigraph(tbl,res.Info);
		case cType.GraphType.DIAGRAM_FP	
			gr=cGraphDiagramFP(tbl);
		case cType.GraphType.SUMMARY
			gr=cGraphSummary(tbl,res.Info,param);
		case cType.GraphType.RESOURCE_COST
			gr=cGraphCostRSC(tbl,res.Info,param.Variables);
	end
	% Show Graph
	if isValid(gr)
		gr.showGraph;
	else
		printLogger(gr);
	end
end
