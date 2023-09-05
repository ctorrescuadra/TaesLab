function res=ShowProductiveDiagram(data)
% Shows the productive graph (Only Matlab)
%   USAGE:
%       res=ShowProductiveDiagram(data)
% 	INPUT:
%		data - cReadModel object containing the data model information
% 	OUTPUT:
%		res - digraph object
% See also cReadModel, cProductiveStructure
%
	res=cStatusLogger();
    if isOctave
        res.printError('Function not implemented in Octave');
    end
    % Check input parameters
    if nargin~=1
        res.printError('Usage: ShowProductiveStructure(model)');
        return
    end
    if ~isa(data,'cDataModel')
        res.printError('Invalid model. It should be a cReadModel object');
        return
    end
	% Check Productive Structure
	if ~data.isValid
		data.printLogger;
		res.printError('Invalid Productive Structure. See error log');
		return
	end
	% Build the digraph
    ps=data.ProductiveStructure;
    A=ps.ProductiveMatrix;
    nodenames=[ps.StreamKeys,ps.FlowKeys,ps.ProcessKeys(1:end-1)];
    nodetypes=[repmat(cType.NodeType.STREAM,1,ps.NrOfStreams),...
               repmat(cType.NodeType.FLOW,1,ps.NrOfFlows),...
               repmat(cType.NodeType.PROCESS,1,ps.NrOfProcesses)];
    nodetable=table(nodenames',nodetypes','VariableNames',{'name','type'});
    res=digraph(A,nodetable,'omitselfloops');
    colors=eye(3);
    nodecolors=colors(nodetypes(:),:);
    figure('menubar','none','name','Productive Diagram','resize','on','numbertitle','off',...
        'units','normalized','position',[0.1 0.1 0.75 0.75],'color',[1 1 1]);
    plot(res,"Layout","auto","NodeLabel",nodenames,"NodeColor",nodecolors,"Interpreter","none");
    title('Productive Diagram','fontsize',14);
end