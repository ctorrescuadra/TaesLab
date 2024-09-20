classdef (Sealed) cDiagramFP < cResultId
% cDiagramFP obtain the adjacency tables of the diagramFP
% cDiagramFP Properties
%   EdgesFP  - Edges struct of the exergy adjacency table FP
%   EdgesCFP - Edges struct of the exergy cost adjacency table FP
% cDiagramFP Methods:
%   getResultInfo - Get the result info object of the diagram FP
%
    properties (GetAccess=public,SetAccess=private)
        EdgesFP     % Edges struct of the exergy FP adjacency table
        EdgesCFP    % Edges struct of the exergy cost FP adjacency table
    end
    methods
        function obj = cDiagramFP(mfp)
        % Construct an instance of this class
        % Syntax:
        %   obj = cDiagramFP(mfp)
        % Input Argument:
        %   mfp - cExergyCost object
        %
            obj=obj@cResultId(cType.ResultId.DIAGRAM_FP);
            % Create the edges of the tables 
            nodes=mfp.ps.ProcessKeys;
            values=mfp.TableFP;
            obj.EdgesFP=cDiagramFP.adjacencyTable(values,nodes);
            values=mfp.getCostTableFP;
            obj.EdgesCFP=cDiagramFP.adjacencyTable(values,nodes);
            obj.DefaultGraph=cType.Tables.DIAGRAM_FP;
            obj.ModelName=mfp.ModelName;
            obj.State=mfp.State;
        end

        function res=getResultInfo(obj,fmt)
        % Get cResultInfo object of the DiagramFP
        % Syntax:
        %   res = obj.getResultInfo(fmt)
        % Input Argument:
        %   fmt - cFormatData object
        % Output Argument:
        %   res - cResultInfo object
            res=fmt.getDiagramFP(obj);
        end
    end

    methods(Static)
        function res=adjacencyTable(mFP,nodes)
        % Get a struct with the Adjacency Table FP
        % Syntax:
        %   res=cDiagramFP.adjacencyTables(mFP,nodes);
        % Input Argument:
        %  mFP - FP matrix values
        %  nodes - Cell Array with the process node names
        % Output Argument:
        %  res - Struct Array containing the adjacency matrix
        %    The struct has the following fields
        %     source - source node of the edge
        %     target - target node of the edge
        %     value  - value of the edge
        %
            % Build Internal Edges
            fields={'source','target','value'};
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
            tmp=[source', target', num2cell(values)];
            res=cell2struct(tmp,fields,2);
        end
    end
end