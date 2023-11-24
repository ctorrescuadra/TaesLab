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
    ps=data.ProductiveStructure;
    switch param.Graph
    case cType.Tables.FLOWS_DIAGRAM
        A=ps.StructuralMatrix;
        nodenames=[ps.FlowKeys];
        nodetypes=repmat(cType.NodeType.FLOW,1,ps.NrOfFlows);
        name=['Flows Diagram / ',data.ModelName];
    case cType.Tables.FLOW_PROCESS_DIAGRAM
        A=ps.FlowProcessMatrix;
        nodenames=[ps.FlowKeys,ps.ProcessKeys(1:end-1)];
        nodetypes=[repmat(cType.NodeType.FLOW,1,ps.NrOfFlows),...
               repmat(cType.NodeType.PROCESS,1,ps.NrOfProcesses)];
        name=['Flow-Process Diagram / ',data.ModelName];
    case cType.Tables.PRODUCTIVE_DIAGRAM
        A=ps.ProductiveMatrix;
        nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
        nodetypes=[repmat(cType.NodeType.STREAM,1,ps.NrOfStreams),...
               repmat(cType.NodeType.FLOW,1,ps.NrOfFlows),...
               repmat(cType.NodeType.PROCESS,1,ps.NrOfProcesses)];
        name=['Productive Diagram / ',data.ModelName];
    otherwise
        res.printError('Invalid graph name %s',param.Graph);
        return
    end
    nodetable=table(nodenames',nodetypes','VariableNames',{'name','type'});
    res=digraph(A,nodetable,'omitselfloops');
    colors=eye(3);
    nodecolors=colors(nodetypes(:),:);
    figure('menubar','none','name','Productive Diagram','resize','on','numbertitle','off',...
        'units','normalized','position',[0.1 0.1 0.75 0.75],'color',[1 1 1]);
    plot(res,"Layout","auto","NodeLabel",nodenames,"NodeColor",nodecolors,"Interpreter","none");
    title(name,'fontsize',14,"Interpreter","none");
end