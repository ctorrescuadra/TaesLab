classdef cGraphRecycling < cBuildGraph

    methods
        function obj = cGraphRecycling(tbl)
			obj.Name='Recycling Cost Analysis';
			obj.Title=[tbl.Description ' [',tbl.State,'/',tbl.ColNames{end},']'];
			obj.xValues=(0:10:100);
			obj.yValues=cell2mat(tbl.Data);
			obj.xLabel='Recycling (%)';
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Categories=tbl.RowNames;
			obj.Legend=tbl.ColNames(2:end);
			if tbl.isGeneralCostTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
        end

        function showGraph(obj)
 		% Plot the graph recycling
			f=figure('name',obj.Name,'numbertitle','off','colormap',turbo,...
				'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			plot(obj.xValues,obj.yValues,'Marker','diamond','LineWidth',1);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
        end
    end
end