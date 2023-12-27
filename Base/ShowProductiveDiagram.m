function res=ShowProductiveDiagram(data,varargin)
% Shows the productive graphs (Only Matlab)
%   USAGE:
%       res=ShowProductiveDiagram(data,option)
% 	INPUT:
%		data - cReadModel object containing the data model information
%       options - an structure contains additional parameters:   
%   	    Graph - Productive graph to plot
%               cType.Tables.FLOWS_DIAGRAM (fat)
%               cType.Tables.FLOW_PROCESS_DIAGRAM (fpat)
%               cType.Tables.PRODUCTIVE_DIAGRAM (pat)
% 	OUTPUT:
%		res - digraph object
% See also cProductiveStructure
%
	res=cStatusLogger();
    if isOctave
        res.printError('Graph function not implemented in Octave');
    end
	checkModel=@(x) isa(x,'cDataModel');
	% Check input parameters
	p = inputParser;
	p.addRequired('data',checkModel);
	p.addParameter('Graph','fat',@ischar);
	try
		p.parse(data,varargin{:});
	catch err
		res.printError(err.message);
        res.printError('Usage: ThermoeconomicState(data,param)');
		return
	end
	param=p.Results;
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end
	% Build the digraph
    pd=ProductiveDiagram(data);
    tbl=pd.getTable(param.Graph);
    nodetable=pd.Info.getNodeTable(param.Graph);
    showGraph(tbl,nodetable);
end