classdef cGraphCost < cBuildGraph

    methods
        function obj=cGraphCost(tbl)
            obj.Name=tbl.Description;
            obj.Title=[tbl.Description,' [',tbl.State,']'];
            obj.Categories=tbl.ColNames(2:end);
            obj.xValues=(1:tbl.NrOfCols-1)';
            obj.yValues=circshift(cell2mat(tbl.Data(1:end-1,1:end)),1)';
            if tbl.isFlowsTable
                obj.xLabel='Flows';
            else
                obj.xLabel='Processes';
            end
            obj.yLabel=['Unit Cost ',tbl.Unit];
            obj.Legend={'ENV',tbl.RowNames{1:end-2}};
            if tbl.isGeneralCostTable || tbl.isFlowsTable
                obj.BaseLine=0.0;
            else
                obj.BaseLine=1.0;
            end
        end
        
        function showGraph(obj)
		% Plot the ICT bar graph.
            M=numel(obj.Legend);
            cm=turbo(M);
            f=figure('name',obj.Name, 'numbertitle','off','colormap',turbo,...
            'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
            ax=axes(f);
            b=bar(obj.yValues,'stacked','edgecolor','none','barwidth',0.5,'parent',ax);

            for i=1:M, set(b(i),'facecolor',cm(i,:)); end
            tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
            obj.setGraphParameters(ax);
        end
    end

end