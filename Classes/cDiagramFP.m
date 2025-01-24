classdef (Sealed) cDiagramFP < cResultId
%cDiagramFP obtain the adjacency tables of the diagramFP
%
%   cDiagramFP constructor:
%     obj = cDiagramFP(exc)
%
%   cDiagramFP properties
%     EdgesFP  - Edges struct of the exergy adjacency table FP
%     EdgesCFP - Edges struct of the exergy cost adjacency table FP
%
%   cDiagramFP methods:
%     buildResultInfo - Build the cResultInfo object of the diagram FP
%     adjacencyTable  - get the adjacency table
%
    properties (GetAccess=public,SetAccess=private)
        EdgesFP     % Edges struct of the exergy FP adjacency table
        EdgesCFP    % Edges struct of the exergy cost FP adjacency table
    end
    methods
        function obj = cDiagramFP(exc)
        % cDiagramFP - Construct an instance of this class
        % Syntax:
        %   obj = cDiagramFP(mfp)
        % Input Argument:
        %   exc - cExergyCost object
        %
            if ~isObject(exc,'cExergyCost')
                obj.messageLog(cType.ERROR,cMessages.InvalidObject,class(exc));
                return
            end
            % Create the edges of the tables
            nodes=exc.ps.ProcessKeys;
            values=exc.TableFP;
            obj.EdgesFP=cDiagramFP.adjacencyTable(values,nodes);
            values=exc.getCostTableFP;
            obj.EdgesCFP=cDiagramFP.adjacencyTable(values,nodes);
            % cResultId properties
            obj.ResultId=cType.ResultId.DIAGRAM_FP;
            obj.DefaultGraph=cType.Tables.DIAGRAM_FP;
            obj.ModelName=exc.ModelName;
            obj.State=exc.State;
        end

        function res=buildResultInfo(obj,fmt)
        % buildResultInfo - Get cResultInfo object of the DiagramFP
        % Syntax:
        %   res = obj.buildResultInfo(fmt)
        % Input Argument:
        %   fmt - cFormatData object
        % Output Argument:
        %   res - cResultInfo object
            res=fmt.getDiagramFP(obj);
        end
    end

    methods(Static)
        function res=adjacencyTable(mFP,nodes)
        % adjacencyTable - Get a struct with the Adjacency Table FP
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