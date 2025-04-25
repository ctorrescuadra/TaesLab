classdef cGraphDiagramFP < cBuildGraph
    methods
        function obj=cGraphDiagramFP(tbl)
            if isOctave
				obj.messageLog(cType.ERROR,cMessages.GraphNotImplemented);
				return
            end
            if isObject(tbl,'cTableMatrix')
                mFP=cell2mat(tbl.Data(1:end-1,1:end-1));
                val=cDiagramFP.adjacencyTable(mFP,tbl.RowNames);
                data=struct2cell(val)';
                source=data(:,1); target=data(:,2);
                values=cell2mat(data(:,3));
            else
                source=tbl.Data(:,1); target=tbl.Data(:,2);
                values=cell2mat(tbl.Data(:,3));
            end
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description ' [',tbl.State,']'];
            obj.xValues=digraph(source,target,values,'omitselfloops');
			obj.isColorbar=true;
			obj.Legend=cType.EMPTY_CELL;
			obj.yValues=cType.EMPTY;
			obj.xLabel=['Exergy ' tbl.Unit];
			obj.yLabel=cType.EMPTY_CHAR;
			obj.BaseLine=0.0;
			obj.Categories=cType.EMPTY_CELL;
        end
        
        function showGraph(obj)
            f=figure('name',obj.Name, 'numbertitle','off', ...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]); 
			ax=axes(f);
			r=(0:0.1:1); red2blue=[r.^0.4;0.2*(1-r);0.8*(1-r)]';
			colormap(red2blue);
			plot(ax,obj.xValues,"Layout","auto","EdgeCData",obj.xValues.Edges.Weight,"EdgeColor","flat","LineWidth",1.5);
			c=colorbar(ax);
			c.Label.String=obj.xLabel;
			c.Label.FontSize=12;
			title(ax,obj.Title,'fontsize',14);
        end
    end
end