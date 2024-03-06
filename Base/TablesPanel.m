classdef TablesPanel < handle
% TablesPanel is a GUI funtion that shows the table index of a collection of results.
%   When select a table, it is shown in the web browser and show the graph if it exists.
%   USAGE:
%       TablesPanel(res,params)
%   INPUT:
%       res - cResultInfo containig the tables to show 
%   See also cResultInfo, cThermoeconomicModel, cDataModel
%
    properties(Access=private)
        fig             % Base Figure
        table_control   % uitable component
        tableIndex      % cTableIndex of the results
        activeTable     % Current table to show
        resultInfo      % Result Info object
        tableView       % View Table option
    end
    methods
        function app=TablesPanel(arg)
        % Built an instance of the object
            log=cStatusLogger();
            if nargin<1
                log.printError('Usage: TableViewer(res)');
                return
            end
            % Check Input parameter
            switch getClassId(arg)
                case cType.ClassId.RESULT_INFO
                    res=arg;
                case cType.ClassId.DATA_MODEL
                    res=arg.getResultInfo;
                case cType.ClassId.RESULT_MODEL
                    res=arg.resultModelInfo;
                otherwise
                    log.printError('Invalid result parameter');
                    return
            end
            % Check input parameters
            if isOctave
                app.tableView=cType.TableView.GUI;
            else
                app.tableView=cType.TableView.HTML;
            end
            tbl=res.getTableIndex;
            % Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4.2;
            ysize=ss(4)/2;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;
            app.fig=figure('visible','off','menubar','none',...
                'name',res.ResultName,...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize]);
            % File menu
            f=uimenu (app.fig,'label', '&File', 'accelerator', 'f');
            uimenu (f, 'label', 'Close', 'accelerator', 'q',...
				'callback', 'close(gcf)');
            % Show table
            data=[tbl.RowNames', tbl.Data];
            cw=num2cell([xsize*0.18 xsize*0.68 xsize*0.12]);
            format=[cType.colType(tbl.getColumnFormat)];
            app.table_control = uitable (app.fig,'Data',data,...
                'ColumnName',tbl.ColNames,'RowName',[],...
                'ColumnWidth',cw,'ColumnFormat',format,...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.setActiveTable(src,evt),...
                'units', 'normalized','position',[0.01 0.01 0.98 0.98]);
            set(app.fig,'visible','on');
            app.tableIndex=tbl;
            app.resultInfo=arg;
        end

        function setActiveTable(app,~,event)
        % Cell selection callback.
        % Select the table to show
            indices=event.Indices;
            idx=indices(1);
            app.activeTable=app.tableIndex.Content{idx};
            sg=(indices(2)==cType.GRAPH_COLUMN);
            if app.activeTable.isGraph && sg
               graph=app.tableIndex.RowNames{idx};
               showGraph(app.resultInfo,graph);
            else
                viewTable(app.activeTable,app.tableView);
            end
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
        end
    end
end