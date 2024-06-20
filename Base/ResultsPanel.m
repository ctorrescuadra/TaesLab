classdef ResultsPanel < cTaesLab
% cResultsPanel is a GUI class that let to show the results interactively
%   The class create a figure panel and show the Index Table of the selected cResultSet
%   From the Index Table you can select the table or graphic to show.
%   Table values could be show in the console, in a web browser or in a uitable.
%   In addition the current ResultSet could be save into a file using File->Save menu option
%
% Methods:
%   tp=ResultsPanel(option)
%   tp.setResults(res)
%   tp.setTableView(option)
%       
% See also cResultSet
%
    properties(Access=private)
        fig             % Base Figure
        tname           % Table label
        table_control   % uitable component
        tableIndex      % cTableIndex of the results
        resultInfo      % Result Info object
        tableView       % View Table option
    end
    methods
        function app=ResultsPanel(option)
        % Built an instance of the object
        %  Input:
        %   option - Table View option
        %     CONSOLE: Show table in the console
        %     GUI: Show the table in a uitable widget
        %     HTML: Show the table in a web browser as a HTML table
        %
            if nargin==0
                option=cType.TableView.CONSOLE;
            end
            app.tableView=option;
            % Create figure
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
                   'Position', [0.015 0.955 0.5 0.04]);
            cw=num2cell([xsize*0.21 xsize*0.64 xsize*0.125]);
            format={'char','char','char'};
            app.table_control = uitable (app.fig,...
                'ColumnName',{'Table','Description','Graph'},...
                'RowName',[],...
                'ColumnWidth',cw,'ColumnFormat',format,...
                'FontName','Verdana','FontSize',8,...
                'CellSelectionCallback',@(src,evt) app.selectTable(src,evt),...
                'units', 'normalized','position',[0.012 0.01 0.978 0.95]);
        end

        function setResults(app,res)
        % get the table index of a result set and show the table panel
        %  Input:
        %   res - cResultSet 
            log=cStatus();
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
            app.viewTable;
        end

        function setTableView(app,option)
        % Set the table view option
        %  Input: 
        %   option - table view options, as in the constructor
            app.tableView=option;
        end

        function closeApp(app,~,~)
        % Close callback
            delete(app.fig);
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
            tbl=app.tableIndex.Content{idx};
            sg=(indices(2)==cType.GRAPH_COLUMN);
            if tbl.isGraph && sg
               graph=app.tableIndex.RowNames{idx};
               showGraph(app.resultInfo,graph);
            else
                showTable(tbl,app.tableView);
            end
        end

		function saveResult(app,~,~)
		% Save results callback
            log=cStatus();
			default_file=cType.RESULT_FILE;
			[file,path,ext]=uiputfile(cType.SAVE_RESULTS,'Select File',default_file);
            if ext % File has been selected
                cd(path);
                res=app.resultInfo;
                descr=app.tableIndex.Description;
				slog=saveResults(res,file);
                if isValid(slog)
				    log.printInfo('%s saved in file %s',descr, file);			    
                else
                    log.printError('Result file %s could NOT be saved', file);
                end
            end
        end

        function viewTable(app)
        % Show the table panel on top window
            set(app.fig,'Visible','on');
            figure(app.fig);
        end

        function hideTable(app)
        % Hide the table panel 
            set(app.fig,'Visible','off')
        end
    end
end