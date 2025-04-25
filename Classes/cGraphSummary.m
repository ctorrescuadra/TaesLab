classdef cGraphSummary < cBuildGraph

    methods
        function obj = cGraphSummary(tbl,var)
            if nargin<2
                obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
                return
            end
            if ~iscell(var)
                obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
                return
            end
            idx=find(ismember(tbl.RowNames,var));
			if isempty(idx)
				obj.messageLog(cType.ERROR,cMessages.InvalidParameter);
				return
			end
			obj.Name='Cost Summary';
			obj.Categories=tbl.ColNames(2:end);
			obj.xValues=(1:tbl.NrOfCols-1)';
			obj.yValues=cell2mat(tbl.Data(idx,:))';
			obj.Title=tbl.Description;
			switch tbl.SummaryType
				case cType.STATES
					obj.xLabel='States';
					if tbl.Resources
						obj.Title=horzcat(obj.Title,' - [',tbl.Sample,']');
					end
				case cType.RESOURCES
					obj.xLabel='Samples';
					obj.Title=horzcat(obj.Title,' - [',tbl.State,']');
				otherwise
					obj.xLabel='';
			end
			obj.yLabel=['Unit Cost ',tbl.Unit];
			obj.Legend=tbl.RowNames(idx);
			if tbl.isGeneralCostTable || tbl.isFlowsTable
				obj.BaseLine=0.0;
			else
				obj.BaseLine=1.0;
			end
        end

        function showGraph(obj)
			f=figure('name',obj.Name, 'numbertitle','off', 'colormap',turbo,...
			'units','normalized','position',[0.1 0.1 0.45 0.6],'color',[1 1 1]);
			ax=axes(f);
			bar(obj.xValues,obj.yValues,'edgecolor','none','barwidth',0.8,'parent',ax);
			tmp=ylim;yl(1)=obj.BaseLine;yl(2)=tmp(2);ylim(yl);
			obj.setGraphParameters(ax);
        end
    end
end