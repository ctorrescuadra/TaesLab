function res=buildAdjacencyTableFP(mFP,nodes)
% Get cell array with the FP Adjacency Table
% Internal use for cResultInfo and cGraphResults
%   INPUT:
%       mFP - FP matrix values
%       nodes - Name of the processes
%   OUTPUT:
%       res - Cell Array containing the adjacency matrix
%
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
    res=[source', target', num2cell(values)];
end