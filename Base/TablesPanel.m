classdef TablesPanel < cTaesLab
% cTablesPanel is a GUI class that let to show the results interactively
%   The class create a figure panel and show the Index Table of the selected cResultSet
%   From the Index Table you can select the table or graphic to show.
%   Table values could be show in the console, in a web browser or in a uitable.
%   In addition the current ResultSet could be save into a file using File->Save menu option
%
%   Methods:
%     tp=cTablePanel(option)
%     tp.setTableIndex(res)
%     tp.setTableView(option)
%       
%   See also cResultSet
%
    properties(Access=private)
        fig             % Base Figure
        tname           % Table label
        table_control   % uitable component
        tableIndex      % cTableIndex of the results
        activeTable     % Current table to show
        resultInfo      % Result Info object
        tableView       % View Table option
    end
    methods
        function app=TablesPanel(option)
        % Built an instance of the object
        %  Input:
        %   option - Table View option
        %     CONSOLE: Show table in the console
        %     GUI: Show the table in a uitable widget
        %     HTML: Show the table in a web browser as a HTML table
        %
            if nargin==0
                option=cType.DEFAULT_TABLEVIEW;
            end
            app.tableView=cType.getTableView(option);
            % Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4;
            ysize=ss(4)/1.7;
            xpos=0.55*ss(3);
            ypos=(ss(4)-ysize)/2;
            app.fig=figure('visible','off','menubar','none',...
                'name','TablesPanel',...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize]);
            f=uimenu (app.fig,'label', '&File', 'accelerator', 'f');
            uimenu (f, 'label', 'Close', 'accelerator', 'q',...
                    'callback', @(src,evt) app.closeApp);
            uimenu (f, 'label', 'Save', 'accelerator', 's',...
                    'callback', @(src,evt) app.saveResult);
            app.tname=uicontrol (app.fig,'style', 'text',...
                   'string', '',...
                   'units', 'normalized',...
                   'fontname','Verdana','fontsize',8,...
                   'FontWeight','bold',...
                   'horizontalalignment', 'left',...
                   'Position', [0.015 0.95 0.5 0.04]);
            cw=num2cell([xsize*0.21 xsize*0.64 xsize*0.12]);
            format={'char','char','char'};
            app.table_control = uitable (app.fig,...
                'ColumnName',{'Table','Description','Graph'},...
                'RowName',[],...
                'ColumnWidth',cw,'ColumnFormat',format,...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.selectTable(src,evt),...
                'units', 'normalized','position',[0.015 0.01 0.97 0.95]);
        end

        function setIndexTable(app,res)
        % get the table index of a result set and show the table panel
        %  Input:
        %   res - cResultSet 
            log=cStatusLogger();
            % Check Input parameter
            if ~isa(res,'cResultSet') && res.isValid
                log.printError('Invalid input argument');
                return
            end
            tbl=res.getTableIndex;
            data=[tbl.RowNames', tbl.Data];
            set(app.tname,'string',tbl.Description)
            set(app.table_control,'Data',data);
            app.tableIndex=tbl;
            app.resultInfo=res;
            app.showTable;
        end

        function setTableView(app,option)
        % Set the table view option
        %  Input: 
        %   option - table view options, as in the constructor
            if cType.checkTableView(option)
                app.tableView=cType.getTableView(option);
            end
        end
    end

    methods(Access=private)
        function selectTable(app,~,event)
        % Cell selection callback.
            indices=event.Indices;
            if numel(indices)<2
                return
            end
            idx=indices(1);
            app.activeTable=app.tableIndex.Content{idx};
            sg=(indices(2)==cType.GRAPH_COLUMN);
            if app.activeTable.isGraph && sg
               graph=app.tableIndex.RowNames{idx};
               showGraph(app.resultInfo,graph);
            else
                showTable(app.activeTable,app.tableView);
            end
        end

		function saveResult(app,~,~)
		% Save results callback
            log=cStatus();
			default_file=cType.RESULT_FILE;
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.html', 'HTML files'},...
                                        'Select File',default_file);
            if ext % File has been selected
                cd(path);
                res=app.resultInfo;
                descr=app.tableIndex.Description;
				slog=saveResults(res,file);
                if isValid(slog)
				    log.printInfo('%s saved in file %s',descr, file);			    
                else
                    log.printInfo('Result file %s could NOT be saved', file);
                end
            end
        end

        function showTable(app)
        % Show the table panel on top window
            set(app.fig,'Visible','on');
            figure(app.fig);
        end

        function hideTable(app)
        % Hide the table panel 
            set(app.fig,'Visible','off')
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
        end
    end
end