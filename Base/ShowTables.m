classdef ShowTables < handle
% ShowTables shows the table index of a collection of results.
%   When select a table, it is shown in the web browser
%   USAGE:
%       ShowTables(res)
%   INPUT:
%       res - A cResultInfo or a cThermoeconomicModel object
%   See also cResultInfo, cThermoeconomicTool
%
    properties(Access=private)
        table_control
        tableIndex
        activeTable
        fig
    end
    methods
        function app=ShowTables(res)
        % Built an instance of the object
            log=cStatus();
            if nargin~=1
                log.printError('Values to show are required');
                log.printError('Usage: ViewModelResuls(res)');
                delete(app);
                return
            end
            if isa(res,'cResultInfo')
                val=res;
            elseif isa(res,'cThermoeconomicModel')
                val=res.getModelInfo;
            else
                log.printError('Results must be a cResultInfo object');
                delete(app);
                return
            end
            tbl=val.getTableIndex;
            % Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/5;
            ysize=ss(4)/2;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;
            app.fig=figure('visible','off','menubar','none',...
                'name',val.ResultName,...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize]);
            % File menu
            f=uimenu (app.fig,'label', '&File', 'accelerator', 'f');
            uimenu (f, 'label', 'Close', 'accelerator', 'q',...
				'callback', 'close(gcf)');
            % Show table
            data=[tbl.RowNames', tbl.Data];
            cw=num2cell([xsize*0.24 xsize*0.74]);
            app.table_control = uitable (app.fig,'Data',data,...
                'ColumnName',tbl.ColNames,'RowName',[],...
                'ColumnWidth',cw,'ColumnFormat',{'char','char'},...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.setActiveTable(src,evt),...
                'units', 'normalized','position',[0.01 0.01 0.98 0.98]);
            set(app.fig,'visible','on');
            app.tableIndex=tbl;
        end

        function setActiveTable(app,~,evt)
        % Cell selection callback
            idx=evt.Indices(1);
            app.activeTable=app.tableIndex.Content{idx};
            viewTable(app.activeTable);
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
        end
    end
end