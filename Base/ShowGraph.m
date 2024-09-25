function ShowGraph(arg,varargin)
%ShowGraph - Shows a result table as a graph.
%	Depending on the graph, additional options could be used.
%
% Syntax 
%  	ShowGraph(arg,Name,Value)
% 
% Input Argument
% 	arg - cResultSet object
%
% Name-Value Arguments
%   Graph: Name of the table
%     char array
%   ShowOutput: Use for diagnosis tables
%     false | true (default)
%   WasteFlow: Waste flow key for waste allocation and recycling
%     char array 
%	Variables: Use for summary results. 
%	  cell array
%   Colorbar: Use Colorbar in Diagram FP
%     false | true (default)
%
% Example
%   <a href="matlab:open ThermoeconomicModelDemo.mlx">Thermoeconomic Model Demo</a>
%
% See also cGraphResults, cResultSet
%
    log=cMessageLogger();
	if nargin < 1 || ~isObject(arg,'cResultSet')
		log.printError('First Argument must be a Result Set');
		log.printError('Usage: ShowGraph(res,options)');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addParameter('Graph',cType.EMPTY_CHAR,@ischar);
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Variables',cType.EMPTY_CELL,@iscell);
	p.addParameter('WasteFlow',cType.EMPTY_CHAR,@ischar);
	p.addParameter('Colorbar',true,@islogical);
    try
		p.parse(varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowGraph(res,options)');
        return
    end
	param=p.Results;
    switch arg.classId
        case cType.ClassId.RESULT_INFO
            if isempty(param.Graph)
			    param.Graph=arg.Info.DefaultGraph;
            end
            res=arg;
        case cType.ClassId.RESULT_MODEL
            if isempty(param.Graph)
			   log.printError('Not enough input arguments');
               return
            end
            res=arg.getResultInfo(param.Graph);
            if ~res.status
                res.printLogger;
                return
            end
        otherwise
            log.printError('Invalid result parameter');
            return
    end
    % Get the table values
	tbl=getTable(res,param.Graph);
	if ~tbl.status || ~tbl.isGraph
		log.printError('Table %s is NOT valid',param.Graph);
		return
	end
	% Get aditional parameters
	option=cType.EMPTY;
	switch tbl.GraphType
		case cType.GraphType.DIAGNOSIS
			if res.Info.Method==cType.DiagnosisMethod.WASTE_INTERNAL
				option=param.ShowOutput;
            else
				option=true;
			end
		case cType.GraphType.DIGRAPH
			option=res.Info.getNodeTable(param.Graph);
		case cType.GraphType.WASTE_ALLOCATION
            option=res.Info.wasteFlow;
		case cType.GraphType.SUMMARY
			if isempty(param.Variables)
				if tbl.isFlowsTable
					param.Variables=res.Info.getDefaultFlowVariables;
				else
					param.Variables=res.Info.getDefaultProcessVariables;
				end
			end
			option=param.Variables;
        case cType.GraphType.DIAGRAM_FP
            option=param.Colorbar;
        case cType.GraphType.DIGRAPH_FP
            option=param.Colorbar;
	end
	% Show Graph
	gr=cGraphResults(tbl,option);
	gr.showGraph;
end
