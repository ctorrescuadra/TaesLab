function ShowModelGraph(model,graph,varargin)
% Show table values as graph
%   USAGE:
%       ShowGraph(res, graph, param)
%   INPUT:
%       res - cThermoeconomicModel object
%       graph - Name of the table to plot
%       param - options depending on table
%			ShowOutput: Use for diagnosis tables
%			WasteFlow: Waste flow key for waste allocation and recycling
%			Variables: Use for summary results. 
%				Cell array with the variables to represent
% See also cThermoeconomicModel
%
    log=cStatus(cType.VALID);
	if ~isa(model,'cThermoeconomicModel') || ~isValid(model)
		log.printError('Invalid model parameter');
		return
	end
    % Check input parameters
    p = inputParser;
    p.addRequired('graph',@ischar)
	p.addParameter('ShowOutput',true,@islogical);
	p.addParameter('Variables',{},@iscell);
	p.addParameter('WasteFlow','',@ischar);
    try
		p.parse(graph,varargin{:});
    catch err
        log.printError(err.message);
        log.printError('Usage: ShowModelGraph(res,graph,options)');
        return
    end
    % Get the cResultInfo of the table
    param=p.Results;
	iTable=model.getTableInfo(param.graph);
	if isempty(iTable)
        log.printError('Graph %s does not exists',param.graph);
        return
	elseif ~iTable.graph
		log.printError('Table %s have not graph',param.graph);
		return
	else
		res=model.getResultInfo(iTable.resultId,param.WasteFlow);
	end
    % Get the table values
	tbl=getTable(res,param.graph);
	if ~isValid(tbl)
		log.printError('Invalid graph table: %s',param.graph);
		return
	end
	% Get aditional parameters
	option=[];
	switch tbl.GraphType
		case cType.GraphType.DIAGNOSIS
			if res.Info.Method==cType.DiagnosisMethod.WASTE_INTERNAL
				option=param.ShowOutput;
            else
				option=true;
			end
		case cType.GraphType.DIGRAPH
			option=res.Info.getNodeTable(graph);
		case cType.GraphType.WASTE_ALLOCATION
			if isempty(param.WasteFlow)
				param.WasteFlow=tbl.ColNames{2};
			end
			option=param.WasteFlow;
		case cType.GraphType.SUMMARY
			if isempty(param.Variables)
				if tbl.isFlowsTable
					param.Variables=obj.Info.getDefaultFlowVariables;
				else
					param.Variables=obj.Info.getDefaultProcessVariables;
				end
			end
			option=param.Variables;
	end
	% Show Graph
	showGraph(tbl,option);
end
