function res=buildDiagramFP(mFP,nodes,dgoption)
% Get cell array with the FP Adjacency Table or the digraph
% Internal use for cResultInfo and cGraphResults
%   INPUT:
%       mFP - FP matrix values
%       nodes - Cell Array with the processes node
%       dgoption - (true/false) build the digraph
%   OUTPUT:
%       res - Cell Array containing the adjacency matrix
%
    if (nargin==2) || isOctave
        dgoption=false;
    end
    % Build Internal Edges
    [idx,jdx,ival]=find(mFP(1:end-1,1:end-1));
    isource=nodes(idx);
    itarget=nodes(jdx);
    % Build Resources Edges
    [~,jdx,vval]=find(mFP(end,1:end-1));
    vsource=arrayfun(@(x) sprintf('IN%d',x),1:numel(jdx),'UniformOutput',false);
    vtarget=nodes(jdx);
    % Build Output edges
    [idx,~,wval]=find(mFP(1:end-1,end));
    wtarget=arrayfun(@(x) sprintf('OUT%d',x),1:numel(idx),'UniformOutput',false);
    wsource=nodes(idx);
    % Build the Adjacency Matrix
    source=[vsource,isource,wsource];
    target=[vtarget,itarget,wtarget];
    values=[vval';ival;wval];
    if dgoption
	    res=digraph(source,target,values,'omitselfloops');
    else
        res=[source', target', num2cell(values)];
    end
end