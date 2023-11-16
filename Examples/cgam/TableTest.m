classdef TableTest < handle
    properties(Access=private)
        td
        model
        uit
    end
    properties(GetAccess=public,SetAccess=private)
    end
    methods
        function obj=TableTest(model)
            def=cTablesDefinition;
            tbl=def.getTablesDirectory;
            wcols=8*[35,26,9,7];
            ColumnWidth=num2cell(wcols);
            ss=get(groot,'ScreenSize');
            xsize=sum(wcols)+120;
			ysize=min(0.8*ss(4),(tbl.NrOfRows+1)*23);	
			xpos=(ss(3)-xsize)/2;
			ypos=(ss(4)-ysize)/2;
            h=figure('menubar','none','toolbar','none','name',tbl.Description,...
				'numbertitle','off',...
				'position',[xpos,ypos,xsize,ysize]);
   			obj.uit=uitable(h, 'Data', tbl.Data,...
				'RowName', tbl.RowNames, 'ColumnName', tbl.ColNames,...
				'ColumnWidth',ColumnWidth,...
				'ColumnFormat',{'char','char','char','char','char'},...
				'FontName','Consola','FontSize',10,...
                'CellSelectionCallback', @(src,event) obj.showTable(src,event),... 
				'Units', 'normalized','Position',[0,0,1,1]);
            obj.td=tbl;
            obj.model=model;
        end
        function showTable(obj,~,evnt)
            idx=evnt.Indices;
            name=obj.td.RowNames{idx};
            display(name);
            viewTable(obj.model,name);
            showGraph(obj.model,name);
        end
        function setData(obj,values)
            tmp=get(obj.uit,'Data');
            tmp(:,4)=values;
            set(obj.uit,'Data',tmp);
        end
    end
end
