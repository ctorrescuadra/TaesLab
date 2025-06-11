classdef (Sealed) TaesTool < handle
%TaesTool - Compatible user interface for Matlab/Octave
%   Execute the basic functions of class cThermoeconomicModel:
%    - productiveStructure
%    - thermoeconomicState
%    - thermoeconomicAnalysis
%    - thermoeconomicDiagnosis
%	 - wasteAnalysis
%   and perform the following operations:
%    - Saves the results in several formats (xlsx, csv, html, txt,..)
%    - Saves variables in the base workspace
%    - Shows the result as tables or graphs
%   The application has two panels: the Taess panel, where the parameters
%   of the Thermoeconomic Model are selected, and the results panel, 
%   where the user selects the tables and graphs to show.
% 
%   Syntax
%     app=TaesTool;
%
%   See also cThermoeconomicModel
%
    properties(Access=private)
        % Widgets definition
        fig             % Main fig
        log             % Log widget
		mfile_text      % Model file widget
		open_button     % Open Data Model widget
		save_buttom     % Save Result widget
        ofile_text      % Output filename widget
        state_popup     % Select State widget
        rstate_popup    % Select Reference State widget
        sample_popup    % Select Resources widget
        wf_popup        % Select Waste Flows widget
        tables_popup    % Select CostTables widget
		tdm_popup       % Diagnosis method widget
        sr_popup       % Summary Results widget
        tv_popup        % Table View widget
        ra_checkbox     % Recycling Analysis widget
		sh_checkbox     % Show in console widget
		gr_checkbox     % Select graphic widget
        mn_rsave        % Save Result menu
        mn_tsave        % Save Table menu
        mn_debug        % Debug menu
        ptindex         % Table Index panel
        menu            % Results Menu cell array widgets
        ptb             % Toolbar cell array widgets
        table_control   % Table Index figure
    end

    % Application variables
    properties(GetAccess=public,SetAccess=private)
        model   
    end        % cThermoeconomicModel object
	properties(Access=private)
        stateNames      % State Names
        sampleNames     % Resource Sample names
        wasteFlows      % Waste Flows
        activeWaste     % Active Waste Flow for Recycling
        resultFile      % Full results file name
        outputFileName  % Sort output file name
        tableView       % table view option
        tableIndex      % Current table index object
        currentNode     % Current cResultInfo
        currentTable    % Current Table
        debug           % Debug control
    end

    methods
        % TaesTool constructor
        function app=TaesTool()
            % Initialize application variables
			app.model=cMessageLogger(cType.INVALID);
            % Create GUI components
            createComponents(app);
            initInputParameters(app);
        end
	end

	methods (Access=private)
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Callback Functions
		%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Get data model file callback
		function getFile(app,~,~)
            % Select file and path
			app.initInputParameters;
            [file,path]=uigetfile({'*.json;*.csv;*.xlsx;*.xml;*.mat','Suported Data Models'});
			if file
				cd(path);
				set(app.log,'string',cType.EMPTY_CHAR);
				set(app.mfile_text,'string',file);
			else
				logtext=' ERROR: No file selected';
			    set(app.log,'string',logtext);
				set(app.mfile_text,'string','Not Model Available');
				return
			end
			% Read and Check Data Model
			data=readModel(file);
            % Activate widgets
			if data.status 
                if app.debug
                    printLogger(data);
                end
				tm=cThermoeconomicModel(data,'Debug',app.debug);
				set(app.mfile_text,'backgroundcolor',[0.95 1 0.95]);
                app.enableResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
				app.enableResults(cType.ResultId.THERMOECONOMIC_STATE);
				app.enableResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
                app.enableResults(cType.ResultId.WASTE_ANALYSIS);
                app.enableResults(cType.ResultId.DIAGRAM_FP);
                app.enableResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
                app.enableResults(cType.ResultId.DATA_MODEL);
                app.enableResults(cType.ResultId.RESULT_MODEL);
                set(app.mn_rsave,'enable','on');
				set(app.save_buttom,'enable','on');
				app.stateNames=tm.StateNames;
				set(app.state_popup,'enable','on','string',app.stateNames);
                set(app.rstate_popup,'enable','on','string',app.stateNames);
				if tm.isResourceCost
					app.sampleNames=tm.SampleNames;
					set(app.sample_popup,'enable','on','string',app.sampleNames);
                    set(app.tables_popup,'enable','on');
				end
				dnames=cType.DiagnosisOptions;
                tdm_pos=cType.DiagnosisMethod.WASTE_EXTERNAL+1;
                set(app.tdm_popup,'enable','on');
				if tm.isWaste
                    app.wasteFlows=data.WasteFlows;
                    set(app.wf_popup,'enable','on','string',app.wasteFlows);
                    set(app.ra_checkbox,'enable','on');
                    set(app.tdm_popup,'string',dnames,'value',tdm_pos);
				else
                    set(app.tdm_popup,'string',dnames(1:2),'value',tdm_pos);
				end
                sopt=data.SummaryOptions;
                set(app.sr_popup,'string',sopt.Names,'enable','on');
                app.ViewIndexTable(tm.getResultInfo)
                app.model=tm;
            else
				set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
				logtext=' ERROR: Invalid Data Model. See Console Log';
                printLogger(data);
                set(app.log,'string',logtext);
			end
        end

        function activateRecycling(app,~,~)
		% Activate Recycling callback
			val=get(app.ra_checkbox,'value');
            setRecycling(app.model,logical(val));
            if val
                app.ViewIndexTable(app.model.wasteAnalysis);
            else
                app.ViewIndexTable(app.model.getResultInfo);
            end
        end

        function getSummary(app,~,~)
		% Get activate Summary callback
            value=TaesTool.getPopupValue(app.sr_popup);
            setSummary(app.model,value);
			if isSummaryActive(app.model)
                app.enableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewIndexTable(app.model.summaryResults);
			else
                app.disableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewIndexTable(app.model.getResultInfo);
			end
        end

        function getCostTables(app,~,~)
		% Select Cost Table callback
            value=TaesTool.getPopupValue(app.tables_popup);
            setCostTables(app.model,value);
            app.ViewIndexTable(app.model.thermoeconomicAnalysis);
        end

		function getState(app,~,~)
		% Get state callback
            value=TaesTool.getPopupValue(app.state_popup);
			setState(app.model,value);
            if app.model.isDiagnosis
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            end
            app.ViewIndexTable(app.model.getResultInfo);
        end

        function getReferenceState(app,~,~)
		% Get state callback
            value=TaesTool.getPopupValue(app.state_popup);
			setReferenceState(app.model,value);
            if app.model.isDiagnosis
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.thermoeconomicDiagnosis);
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.getResultInfo);
            end
		end

		function getSample(app,~,~)
		% Get Resources Sample callback
            value=TaesTool.getPopupValue(app.sample_popup);
			app.model.setResourceSample(value);
            app.ViewIndexTable(app.model.thermoeconomicAnalysis);
        end

		function getDiagnosisMethod(app,~,~)
		% Get WasteDiagnosis callback
            value=TaesTool.getPopupValue(app.tdm_popup);
			setDiagnosisMethod(app.model,value);
			if isDiagnosis(app.model)
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.thermoeconomicDiagnosis);
            else 
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.getResultInfo);
			end
        end

        function getActiveWaste(app,~,~)
        % Get WasteDiagnosis callback
            value=TaesTool.getPopupValue(app.wf_popup);
            setActiveWaste(app.model,value);
            app.ViewIndexTable(app.model.wasteAnalysis);
        end

        function getTableView(app,~,~)
        % Select Table View callback
            pos=get(app.tv_popup,'value');
            app.tableView=pos;
        end

		function saveResult(app,~,~)
		% Save results callback
			default_file=cType.RESULT_FILE;
            [file,path,ext]=uiputfile(cType.SAVE_RESULTS,'Select File',default_file);
            if ext % File has been selected
                cd(path);
                res=app.currentNode;
				slog=saveResults(res,file);
                printLogger(slog);
                if slog.status
				    app.resultFile=file;
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: %s saved in file %s',res.ResultName, file); 
                else
                    logtext=sprintf(' ERROR: Result file has NOT been saved');
                end
            else
                logtext=sprintf(' ERROR: Result file is NOT available');
            end
            set(app.log,'string',logtext);
        end

        function saveTable(app,~,~)
        % Save Table callback
            if ~isempty(app.currentTable)
                tbl=app.currentTable;
                default_file=tbl.Name;
                [file,path,ext]=uiputfile(cType.SAVE_TABLES,'Select File',default_file);
                if ext % File has been selected
                    cd(path);
                    slog=saveTable(tbl,file);
                    printLogger(slog);
                    if slog.status
                        logtext=sprintf(' INFO: Table %s saved in file %s',tbl.Name, file); 
                    else
                        logtext=sprintf(' ERROR: File %s could NOT be saved', file);     
                    end
                else
                    logtext=sprintf(' ERROR: Table is NOT available');
                end
            else
                set(app.mn_tsave,'enable','off');
                logtext=sprintf(' ERROR: Table is NOT available');
            end 
            set(app.log,'string',logtext);
        end

        function showIndexTable(app,src,~)
        % Show Index Table callback
            set(app.log,'string',cType.EMPTY_CHAR);
            idx=get(src,'UserData');
            res=getResultInfo(app.model,idx);
            app.currentTable=cType.EMPTY;
            set(app.mn_tsave,'enable','off')
            if res.status
                app.ViewIndexTable(res);
			else
				logtext=sprintf('ERROR: Result %s is not available',cType.ResultVar{idx});
                set(app.log,'string',logtext);
            end
        end

        function getResults(app,src,~)
        % Get Results callback
        % Store the selected result into workspace
            set(app.log,'string',cType.EMPTY_CHAR);
            idx=get(src,'UserData');
            res=getResultInfo(app.model,idx);
            if res.status
                varname=cType.ResultVar{idx};
                assignin('base', varname, res);
                logtext=sprintf(' INFO: Results store in %s',varname);
			else
				logtext=sprintf('ERROR: Result %s is not available',cType.ResultVar{idx});
            end
			set(app.log,'string',logtext);
        end

        function getDataModel(app,~,~)
        % Get Data model callback
        % Store the cDataModel object into workspace
            assignin('base', 'data', app.model.DataModel);
            logtext=sprintf(' INFO: Results store in variable data');
            set(app.log,'string',logtext);
        end

        function getResultModel(app,~,~)
        % Get Result model callback
        % Store model object into workspace
            assignin('base', 'model', app.model);
            logtext=sprintf(' INFO: Results store in variable model');
            set(app.log,'string',logtext);
        end

        function selectTable(app,~,event)
        % Cell selection callback.
            indices=event.Indices;
            if numel(indices)<2
                return
            end
            if isempty(app.tableIndex)
                return
            end
            idx=indices(1);
            tbl=app.tableIndex.Content{idx};
            sg=(indices(2)==cType.GRAPH_COLUMN);
            if tbl.isGraph && sg
                graph=app.tableIndex.RowNames{idx};
                res=app.currentNode;
                if res.Info.ResultId==cType.ResultId.RESULT_MODEL
                    res=getResultInfo(res.Info,graph);
                end
                showGraph(res,graph);
            else
                app.currentTable=tbl;
                set(app.mn_tsave,'enable','on')
                showTable(tbl,app.tableView);
            end
        end

        function setDebug(app,evt,~)
        % Menu Debug callback
            val=~app.debug;
            check=cType.log2text(val);
            app.debug=val;
            set(evt,'checked',check);
            if isValid(app.model)
                setDebug(app.model,val);
            end
        end

        function aboutTaes(~,~,~)
        % About TaesTool callback
        % Show TaesLab web page
            web('https://www.exergoecology.com/TaesLab');
        end

        function closeApp(app,~,~)
        % Close callback
            selection = questdlg({'Close the Application?'},'Confirmation','OK','Cancel','OK');   
            switch selection
                case 'OK'
                    delete(app.fig)                      
                case 'Cancel'
                    return     
            end
        end

		%%%%%%%%%%%%%%%%%%%%%%%
		% Methods
		%%%%%%%%%%%%%%%%%%%%%%%
        function ViewIndexTable(app,res)
        % View the index table into the table panel
            if isempty(res)
                return
            end
            set(app.ptindex,'Title',res.ResultName);
            tbl=res.getTableIndex;
            data=[tbl.RowNames',tbl.Data];
            set(app.table_control,'Data',data);
            app.tableIndex=tbl;
            app.currentNode=res;
            logtext=sprintf(' INFO: Show %s tables',res.ResultName);
            set(app.log,'string',logtext);
        end

        function disableResults(app,id)
        % Disable menus and toolbar results
            set(app.menu{id},'Enable','off');
            set(app.ptb{id},'Enable','off');
        end

        function enableResults(app,id)
        % Enable menu and toolbar results
            set(app.menu{id},'Enable','on');
            set(app.ptb{id},'Enable','on');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%
        % Create User Interface
        %%%%%%%%%%%%%%%%%%%%%%%%%
        function createComponents(app)
        % Create Figure Components
			% Determine the scale depending on screen size
            ss=get(groot,'ScreenSize');
            xsize=900; ysize=500;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;
            % Create figure
            hf=figure('visible','off','menubar','none',...
			          'name','Thermoeconomic Analysis Tool',...
                      'numbertitle','off','color',[0.94 0.94 0.94],...
                      'resize','off','Position',[xpos,ypos,xsize,ysize],...
                      'CloseRequestFcn',@app.closeApp);

            % Tool Bar
			tb = uitoolbar(hf);
            app.ptb=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO
                app.ptb{i}=uipushtool (tb,...
                    'CData',cType.getIcon(i),...
                    'UserData',i,'Enable','off',...
                    'Tooltipstring',cType.Results{i},...
                    'ClickedCallback', @(src,evt) app.showIndexTable(src,evt));
            end

			% Menus
            f=uimenu (hf,'label', '&File', 'accelerator', 'f');
            e=uimenu (hf,'label', '&Results', 'accelerator', 't');
            h=uimenu (hf,'label', '&Help', 'accelerator', 'h');
            uimenu (h,'label', 'About',...
                'callback', @(src,evt) app.aboutTaes(src,evt))
			uimenu (f, 'label', 'Open', 'accelerator', 'o', ...
				'callback', @(src,evt) app.getFile(src,evt));
            app.mn_rsave=uimenu (f,'label','Save Result','accelerator', 'r',...
                'callback', @(src,evt) app.saveResult(src,evt));
            app.mn_tsave=uimenu (f,'label','Save Table','accelerator', 't',...
                'callback', @(src,evt) app.saveTable(src,evt));
            app.debug=true;
            app.mn_debug=uimenu (f,'label','Debug','accelerator','d',...,
                'enable','on','checked','on',...
                'callback',@(src,evt) app.setDebug(src,evt));
            uimenu (f, 'label', 'Close', 'accelerator', 'q', ...
				'callback', @(src,evt) app.closeApp(src,evt));
            app.menu=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO-2
                app.menu{i}=uimenu(e,...
                    'Label',cType.Results{i},...
                    'UserData',i,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getResults(src,evt));
            end
            idm=cType.ResultId.DATA_MODEL;
            app.menu{idm}=uimenu(e,...
                    'Label',cType.Results{idm},...
                    'UserData',idm,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getDataModel(src,evt));
            irm=cType.ResultId.RESULT_MODEL;
            app.menu{irm}=uimenu(e,...
                    'Label',cType.Results{irm},...
                    'UserData',irm,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getResultModel(src,evt));
				
			% Decoration panel
            p1=uipanel (hf,'title', 'Input Parameters', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.01, 0.05, 0.385, 0.94]);

			app.ptindex=uipanel (hf,'title', 'Index Table', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.405, 0.05, 0.585, 0.94]);

            app.log = uicontrol (hf,'style', 'text',...
                 'units', 'normalized',...
                 'fontname','Verdana','fontsize',9,...
                 'string', cType.EMPTY_CHAR,...
                 'backgroundcolor',[0.75 0.75 0.75],...
                 'horizontalalignment', 'left',...
                 'position', [0.01 0.01 0.98 0.045]);

			% Labels Input Parameters
            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'fontname','Verdana','fontsize',9,...
                   'string', 'Data Model File:',...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select data model file',...
                   'position', [0.06 0.90 0.4 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Reference State:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Reference State for Analysis',...
                   'position', [0.06 0.83 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Operation State:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Operation State for Analysis',...
                   'position', [0.06 0.76 0.36 0.045]);

			uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Resources Cost:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Resource Sample for Analysis',...
                   'position', [0.06 0.69 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Cost Tables:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Cost Tables',...
                   'position', [0.06 0.62 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Diagnosis Method:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Diagnosis Method',...
                   'position', [0.06 0.55 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Recycled Flow:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Waste for Recycling Analysis',...
                   'position', [0.06 0.48 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Summary Results:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Summary Results',...
                   'position', [0.06 0.41 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Table View:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Table View',...
                   'position', [0.06 0.34 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Recycling Analysis:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Activate Recycling Analysis',...
                   'position', [0.06 0.27 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Output File:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Result File',...
                   'position', [0.06 0.20 0.36 0.045]);

			% object widget
			app.mfile_text = uicontrol (p1,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string', ' Not Model Available',...
					'horizontalalignment', 'left',...
					'position', [0.44 0.9 0.47 0.045]);

           app.rstate_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'backgroundcolor',[0.9 0.9 0.94],...
					'callback', @(src,evt) app.getReferenceState(src,evt),...
					'position', [0.44 0.83 0.47 0.045]);
            
            app.state_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getState(src,evt),...
					'position', [0.44 0.76 0.47 0.045]);

 			app.sample_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getSample(src,evt),...
					'position', [0.44 0.69 0.47 0.045]);

			 app.tables_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'string', cType.CostTablesOptions,...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getCostTables(src,evt),...
					'position', [0.44 0.62 0.47 0.045]);

			app.tdm_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getDiagnosisMethod(src,evt),...
					'position', [0.44 0.55 0.47 0.045]);

           app.wf_popup = uicontrol (p1,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getActiveWaste(src,evt),...
					'position', [0.44 0.48 0.47 0.045]);

            app.sr_popup = uicontrol (p1,'style', 'popupmenu',...
                    'units', 'normalized',...
                    'fontname','Verdana','fontsize',9,...
                    'callback', @(src,evt) app.getSummary(src,evt),...
                    'position', [0.44 0.41 0.47 0.045]);

            tvopc=cType.TableViewOptions;
            app.tv_popup = uicontrol (p1,'style', 'popupmenu',...
                    'units', 'normalized',...
                    'string', tvopc(2:end),...
                    'fontname','Verdana','fontsize',9,...
                    'callback', @(src,evt) app.getTableView(src,evt),...
                    'position', [0.44 0.34 0.47 0.045]);
                    
            app.ra_checkbox = uicontrol (p1,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.activateRecycling(src,evt),...
                    'position', [0.44 0.275 0.47 0.045]);
	
            app.outputFileName=[cType.RESULT_FILE,'.xlsx'];
            app.resultFile=[pwd,filesep,app.outputFileName];
			app.ofile_text = uicontrol (p1,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string',app.outputFileName,...
					'backgroundcolor',[0.95 1 0.95],...
					'horizontalalignment', 'left',...
					'position', [0.44 0.20 0.47 0.045]);

            app.open_button = uicontrol (p1,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Load',....
					'callback', @(src,evt) app.getFile(src,evt),...
					'position', [0.06 0.05 0.25 0.06]);

			app.save_buttom = uicontrol (p1,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Save',...
					'callback', @(src,evt) app.saveResult(src,evt),...
					'position', [0.66 0.05 0.25 0.06]);

            % Load Index Table
            psize=0.585*xsize;
            cw=num2cell([0.21*psize 0.62*psize 0.145*psize]);
            format={'char','char','char'};
            td=cTablesDefinition;
            tbl=td.getTablesDirectory({'DESCRIPTION','GRAPH'});
            data=[tbl.RowNames',tbl.Data];
            app.table_control = uitable (app.ptindex,'Data',data,...
                'ColumnName',{'Table','Description','Graph'},...
                'units','normalized',...
                'RowName',cType.EMPTY,...
                'ColumnWidth',cw,'ColumnFormat',format,...
                'FontName','Verdana','FontSize',9,...
                'CellSelectionCallback',@(src,evt) app.selectTable(src,evt),...
                'units', 'normalized','position',[0.01 0.01 0.98 0.96]);

            % Make the figure visible
			set(hf,'visible','on');
            % Assing Table Index Panel
            app.fig=hf;
        end

		function initInputParameters(app)
		    % Initialize widgets
			set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
            set(app.mn_rsave,'enable','off');
            set(app.mn_tsave,'enable','off');
			set(app.save_buttom,'enable','off');
            set(app.ra_checkbox,'value',0,'enable','off');
			set(app.tables_popup,'value',cType.CostTables.DIRECT,'enable','off');
            set(app.sr_popup,'string',{'NONE'},'value',1,'enable','off');
			set(app.tdm_popup,'string',{'NONE'},'value',1,'enable','off');
            set(app.wf_popup,'string',{'NONE'},'value',1,'enable','off');
			set(app.state_popup,'string',{'Reference'},'value',1,'enable','off');
            set(app.rstate_popup,'string',{'Reference'},'value',1,'enable','off');
			set(app.sample_popup,'string',{'Base'},'value',1,'enable','off');
            set(app.tv_popup,'value',cType.TableView.CONSOLE,'enable','on');
            set(app.open_button,'enable','on');
            app.tableView=cType.TableView.CONSOLE;
            app.tableIndex=cType.EMPTY;
            app.currentNode=cType.EMPTY;
            app.currentTable=cType.EMPTY;
            app.model=cMessageLogger(false);
            arrayfun(@(i) app.disableResults(i), 1:cType.MAX_RESULT_INFO);
        end
    end
    methods(Static,Access=private)
        function res=getPopupValue(popup)
        % Get the selected value in the popup downdrop widget
            list=get(popup,'string');
			idx=get(popup,'value');
            res=list{idx};
        end
	end
end
