classdef (Sealed) cDiagramFP < cResultId
% cDiagramFP build the FP digraph of the thermoeconomic state of the plant
%   Methods:
%       obj=cDiagramFP(tbl)
%       res=obj.getDigraph [Only Matlab]
%       obj.plotDiagram [Only Matlab]
%
	properties (GetAccess=public, SetAccess=private)
		NrOfEdges   % Number of Edges
		NrOfNodes   % Number of Nodes
		Nodes       % Nodes of the Digraph
		Edges       % Edges of the Digraph
        AdjacencyTable % Cell Array with adjacency table
	end
	properties (Access=private)
		source  % source nodes array 
		target  % target nodes array
		values  % value nodes array
        unit    % value unit
        descr   % digraph description
	end

	methods
		function obj = cDiagramFP(tbl)
        % Create an instance of cDiagramFP from a digraph table or a cResultInfo object
        %   Input:
        %     arg - cTableMatrix or cResultInfo objects
			% Check Input
            obj=obj@cResultId(cType.ResultId.DIAGRAM_FP);
            if ~isValid(tbl) || ~isDigraph(tbl)
                obj.messageLog(cType.ERROR,'Table %s is not valid',tbl.Key);
                return
            end
    		% Get matrix and nodes
            mFP=cell2mat(tbl.Data(1:end-1,1:end-1));
            nodes=tbl.RowNames(1:end-2);
			[N,M]=size(mFP);
			if N~=M
				obj.messageLog(cType.ERROR,'Invalid FP table size');
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
            % Build object
            obj.source=[vsource,isource,wsource];
            obj.target=[vtarget,itarget,wtarget];
            obj.values=[vval';ival;wval];
            obj.unit=tbl.Unit;
            obj.descr=[tbl.Description,' [',tbl.State,']'];
            obj.Nodes=[vsource,nodes,wtarget];
			obj.NrOfEdges=numel(obj.values);
			obj.NrOfNodes=numel(obj.Nodes);
            obj.status=true;
		end

		function res=get.Edges(obj)
        % get the Edges property as a struct (source,target,value)
			res(obj.NrOfEdges)=struct('source','','target','','value',0.0);
			for i=1:obj.NrOfEdges
				res(i).source=obj.source{i};
				res(i).target=obj.target{i};
				res(i).value=obj.values(i);
			end
        end

        function res=get.AdjacencyTable(obj)
        % get the adjacency Table as cell array
            res=[obj.source',obj.target',num2cell(obj.values)];
        end

        function res=getDigraph(obj)
        % get the digraph object [Matlab] of the Table FP
            res=[];
            if isMatlab
                res=digraph(obj.source,obj.target,obj.values,"omitselfloops");
            end
        end

        function plotDiagram(obj)
        % Plot the diagram FP [Only Matlab]
            if isOctave
                return
            end      
            dg=obj.getDigraph;
            % Create figure and colormap
            figure('menubar','none',...
			        'name','Diagram FP', ...
                    'resize','on','numbertitle','off');
            r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
            colormap(red2blue);
            % Plot the digraph with colobar     
            plot(dg,"Layout","auto","EdgeCData",dg.Edges.Weight,"EdgeColor","flat");
            title(obj.descr);
            c=colorbar;
            c.Label.String=['Exergy',obj.unit];
        end
    end
end