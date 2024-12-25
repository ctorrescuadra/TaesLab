classdef (Sealed) ResultsPanel < cTaesLab
%ResultsPanel - Graphical user interface to display the results interactively.
%   The class creates a panel and displays the table index of the chosen cResultSet.
%   A table or graph can be selected by clicking on the corresponding table.
%   In the View menu, you can choose where the tables are shown:  the console, a web browser or a GUI table.
%   In addition, the current ResultSet can be saved to a file using the menu option File->Save.
%
%   ResultPanel constructor:
%     obj = ResultPanel(res)
%   
%   ResultPanel properties:
%     resultInfo - Result set info object
%     tableView  - Table view option
%
%   ResultPanel methods:
%     ResultsPanel - Creates the panel and shows the result
%     showResults  - Shows  another results table index
%     viewPanel    - Show the panel on the top
%     hidePanel    - Side the panel
%       
%   See also cResultSet
%
    properties(GetAccess=public,SetAccess=private)
        resultInfo      % Result Info object
        tableView       % Table View option
    end

    properties(Access=private)
        fig             % Base Figure
        tname           % Table label
        table_control   % uitable component
        tableIndex      % cTableIndex of the results
        currentTable    % Sslected table
        mn_view         % Table View menu
        mn_rsave        % Save Results menu
        mn_tsave        % Save Table menu
    end

    methods
        function app=ResultsPanel(res)
        % Create a class object
        %   Input:
        %     res - cResultSet object
        %     option - Table View option
        %       CONSOLE: Show table in the console
        %       GUI: Show the table in a uitable widget
        %       HTML: Show the table in a web browser as a HTML table
        %
            log=cMessageLogger();
            app.createPanel;
            if nargin > 0
                if isObject(res,'cResultSet')
                    app.showResults(res)
                else
                    log.printError(cMessages.ResultSetRequired);
                end
            end
        end

        function showResults(app,res)
        % Get the table index of the result set and show it in the table panel
        %  Input:
        %   res - cResultSet 
        %
            % Check Input parameter
            log=cMessageLogger();
            if ~isObject(res,'cResultSet')
                log.printError(cMessages.InvalidObject,class(res));
                return
            end
            % Set table parameters
            tbl=res.getTableIndex;
            data=[tbl.RowNames', tbl.Data];
            set(app.tname,'string',tbl.Description)
            set(app.table_control,'Data',data);
            set(app.mn_tsave,'enable','off');
            app.tableIndex=tbl;
            app.resultInfo=res;
            app.currentTable=cType.EMPTY;
            % show panel
            app.viewPanel;
        end

        function viewPanel(app)
        % Show the table panel on top window
            set(app.fig,'Visible','on');
            figure(app.fig);
        end

        function hidePanel(app)
        % Hide the table panel 
            set(app.fig,'Visible','off')
        end

        function setViewOption(app,idx)
        % Set the actual view option and update menu
            pos=idx+1;
            if pos>0
                app.tableView=idx;
                cellfun(@(x) set(x,'Checked','off'),app.mn_view) 
                set(app.mn_view{pos},'Checked','on');
            end
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
            app.status=false;
        end
    end

    methods(Access=private)
        function createPanel(app)
        % Create Panel
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4;
            ysize=ss(4)/1.8;
            xpos=0.55*ss(3);
            ypos=(ss(4)-ysize)/2;
            app.fig=figure('visible','off','menubar','none',...
                'name','Results Panel',...
                'numbertitle','off','color',[0.94 0.94 0.94],...
                'resize','on','Position',[xpos,ypos,xsize,ysize],...
                'CloseRequestFcn',@app.closeApp);
            f=uimenu(app.fig,'label', '&File', 'accelerator', 'f');
            v=uimenu(app.fig,'label', '&View', 'accelerator', 'v');
            app.mn_rsave=uimenu (f, 'label', 'Save Results', 'accelerator', 's',...
                    'callback', @(src,evt) app.saveResults);
            app.mn_tsave=uimenu (f, 'label', 'Save Table', 'accelerator', 't',...
                    'enable','off','callback', @(src,evt) app.saveTable);
            uimenu (f, 'label', 'Close', 'accelerator', 'q',...
                    'callback', @(src,evt) app.closeApp);
            items=cType.TableViewOptions;

            text=cellfun(@(x) [x(1),lower(x(2:end))],items,'UniformOutput',false);
            for i=1:numel(text)
                app.mn_view{i} = uimenu(v, 'Text', text{i}, ...,
                'MenuSelectedFcn', @(src, event) app.selectViewOption(src, event));
            end
            app.tableView=cType.TableView.CONSOLE;
            set(app.mn_view{2},'Checked','on');

            app.tname=uicontrol (app.fig,'style', 'text',...
                   'string', cType.EMPTY_CHAR,...
                   'units', 'normalized',...
                   'fontname','Verdana','fontsize',8,...
                   'FontWeight','bold',...
                   'horizontalalignment', 'left',...
                   'Position', [0.015 0.955 0.5 0.04]);
            cw=num2cell([xsize*0.21 xsize*0.64 xsize*0.125]);
            format={'char','char','char'};
            app.table_control = uitable (app.fig,...
                'ColumnName',{'Table','Description','Graph'},...
                'RowName',cType.EMPTY,...
                'ColumnWidth',cw,'ColumnFormat',format,...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.selectTable(src,evt),...
                'units', 'normalized','position',[0.012 0.01 0.978 0.95]);
        end

        function selectViewOption(app,src,~)
        % Set the table view as internal
            text=get(src,'Text');
            idx=cType.getTableView(text);
            app.setViewOption(idx)
        end

        function selectTable(app,~,event)
        % Cell selection callback.
            indices=event.Indices;
            if numel(indices)<2
                return
            end
            idx=indices(1);
            tbl=app.tableIndex.Content{idx};
            set(app.mn_tsave,'enable','on');
            sg=(indices(2)==cType.GRAPH_COLUMN);
            if tbl.isGraph && sg
               graph=app.tableIndex.RowNames{idx};
               showGraph(app.resultInfo,graph);
            else
               showTable(tbl,app.tableView);
            end
            app.currentTable=tbl;
        end

		function saveResults(app,~,~)
		% Save results callback
			default_file=cType.RESULT_FILE;
			[file,path,ext]=uiputfile(cType.SAVE_RESULTS,'Select File',default_file);
            if ext % File has been selected
                cd(path);
                res=app.resultInfo;
                descr=app.tableIndex.Description;
				slog=saveResults(res,file);
                if log.status
				    slog.printInfo(cMessages.InfoFileSave,descr, file);			    
                else
                    slog.printError(cMessages.FileNotSaved, file);
                end
            end
        end

        function saveTable(app,~,~)
        % SaveTable callback
            if ~isempty(app.currentTable)
                tbl=app.currentTable;
                default_file=tbl.Name;
                [file,path,ext]=uiputfile(cType.SAVE_TABLES,'Select File',default_file);
                if ext % File has been selected
                    cd(path);
                    slog=saveTable(tbl,file);
                    if log.status
                        slog.printInfo(cMessages.InfoFileSaved, tbl.Name,file);			    
                    else
                        slog.printError(cMessages.FileNotSaved, tbl.Name);
                    end
                end
            else
                log.printError(cMessages.NoTableToSave);
            end
        end
    end
end