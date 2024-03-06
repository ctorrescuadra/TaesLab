classdef (Sealed) cDiagramFP < cResultId
% cDiagramFP obtain the adjacency tables of the diagramFP
    properties (GetAccess=public,SetAccess=private)
        EdgesFP     % Edges of the exergy FP adjacency table
        EdgesCFP    % Edges of the exergy cost FP adjacency table
    end
    methods
        function obj = cDiagramFP(mfp)
        % Construct an instance of this class
        %  Input:
        %   mfp - cModelFPR
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
            obj.status=cType.VALID;
        end

        function res=getResultInfo(obj,fmt)
        % Get cResultInfo object
            res=fmt.getDiagramFP(obj);
        end
    end
    methods (Static)
        function res=adjacencyTable(mFP,nodes)
        % Get cell array with the FP Adjacency Table
        %	Usage:
        %		res=cDiagramFP.adjacencyTables(mFP,nodes);
        %   Input:
        %       mFP - FP matrix values
        %       nodes - Cell Array with the processes node
        %   Output:
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
    end
end