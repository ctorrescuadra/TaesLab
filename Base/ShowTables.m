classdef ShowTables < handle
% ShowTables is a GUI funtion thatshows the table index of a collection of results.
%   When select a table, it is shown in the web browser and show the graph if it exists.
%   USAGE:
%       ShowTables(res,params)
%   INPUT:
%       res - A cResultInfo or a cThermoeconomicModel object
%       param - Optional parameters
%           ViewTable - TableView option
%           ShowGraph - (true/false) indicates if the graph is shown
%   See also cResultInfo, cThermoeconomicTool
%
    properties(Access=private)
        table_control
        tableIndex
        activeTable
        fig
        ViewTable
        ShowGraph
    end
    methods
        function app=ShowTables(arg,varargin)
        % Built an instance of the object
            log=cStatusLogger();
            % Check input parameters
            checkModel=@(x) isa(x,'cResultInfo') || isa(x,'cThermoeconomicModel') && isValid(x) ;
            % Check input parameters
            p = inputParser;
            p.addRequired('arg',checkModel);
            p.addParameter('ViewTable',cType.TableView.HTML',@isnumber);
            p.addParameter('ShowGraph',false,@islogical);
            try
                p.parse(arg,varargin{:});
            catch err
                log.printError(err.message);
                log.printError('Usage: ShowTables(arg,param)');
                delete(app);
                return
            end
            param=p.Results;
            if isa(arg,'cThermoeconomicModel')
                res=arg.getModelInfo;
            else
                res=arg;
            end
            tbl=res.getTableIndex;
            % Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4;
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
            cw=num2cell([xsize*0.24 xsize*0.74]);
            app.table_control = uitable (app.fig,'Data',data,...
                'ColumnName',tbl.ColNames,'RowName',[],...
                'ColumnWidth',cw,'ColumnFormat',{'char','char'},...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.setActiveTable(src,evt),...
                'units', 'normalized','position',[0.01 0.01 0.98 0.98]);
            set(app.fig,'visible','on');
            app.tableIndex=tbl;
            app.ViewTable=param.ViewTable;
            app.ShowGraph=param.ShowGraph;
        end

        function setActiveTable(app,~,evt)
        % Cell selection callback
            idx=evt.Indices(1);
            app.activeTable=app.tableIndex.Content{idx};
            viewTable(app.activeTable,app.ViewTable);
            if app.ShowGraph && app.activeTable.isGraph
                showGraph(app)
            end
        end

        function showGraph(app)
        % Show graph from tableIndex
            log=cStatus(cType.VALID);
            option=[];
            tbl=app.activeTable;
            info=app.tableIndex.Info;
            if ~isValid(tbl) || ~isValid(info)
                log.printError('Invalid graph table: %s',tbl.Name);
                return
            end
            % Get default optional parameters
            switch tbl.GraphType
                case cType.GraphType.DIAGNOSIS
                    option=true;
                case cType.GraphType.DIGRAPH
                    option=info.getNodeTable(graph);
                case cType.GraphType.SUMMARY
                    if tbl.isFlowsTable
                        option=info.getDefaultFlowVariables;
                    else
                        option=info.getDefaultProcessVariables;
                    end
            end
            % Show Graph
            showGraph(tbl,option);
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
        end
    end
end