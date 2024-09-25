classdef (Sealed) TaesPanel < handle
%TaesPanel - Graphic user interface to select the thermoeconomic model parameters.
%   Execute the basic functions of class cThermoeconomicModel:
%    - productiveStructure
%    - thermoeconomicState
%    - thermoeconomicAnalysis
%    - thermoeconomicDiagnosis
%    - wasteAnalysis
%   and perform the following operations:
%    - Save the results in several formats (xlsx, csv, html, txt,..)
%    - Save variables in the base workspace
%    - View Result in tables and graphs.
%
%   By clicking on a result button on the toolbar, the result is activated. 
%   The results can then be displayed in the console if the 'Console' option
%   in the View menu is activated. 
%   The results can also be saved to a file using the 'Save' option in the File menu.  
%   If 'Panel' is active in the View menu, the Results Panel is activated, 
%   and the user can then select the table or graph to be displayed.
%   If the result is selected in the Result Menu, it is saved in the workspace
%   to work with it interactively.
%
% Syntax
%   app=TaesPanel;
%
% See also cThermoeconomicModel
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
        ra_checkbox     % Recycling Analysis widget
        sr_checkbox     % Summary Results widget
        mn_save         % Save Result menu
        mn_debug        % Menu Debug
        mn_console      % Console activation menu
        mn_panel        % Panel Activation menu
        mn_sync         % Sincronize parameters menu
        menu            % Results Menu cell array widgets
        ptb             % Toolbar cell array widgets
    end

    % Application variables
    properties(GetAccess=public,SetAccess=private)
        model;
    end

	properties(Access=private)
        stateNames      % State Names
        sampleNames     % Resource Sample names
        wasteFlows      % Waste Flows
        activeWaste     % Active Waste Flow for Recycling
        resultFile      % Full results file name
        outputFileName  % Sort output file name
        tableIndex      % Current table index object
        resPanel        % ResultsPanel object
        currentNode     % Current cResultInfo
        debug           % Control debug mode
        console         % Console mode
        panel           % Panel mode
        viewOptions     % Table view options
    end

    methods
        function app=TaesPanel()
        % Create an instance of the object
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
            if data.status % Activate widgets
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
                set(app.mn_save,'enable','on');
                set(app.mn_sync,'enable','on');
                if data.NrOfStates>1
                	set(app.sr_checkbox,'enable','on');
                end
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
                set(app.tdm_popup,'enable','on');
                if tm.isWaste
                    app.wasteFlows=data.WasteFlows;
                    set(app.wf_popup,'enable','on','string',app.wasteFlows);
                    set(app.ra_checkbox,'enable','on');
					set(app.tdm_popup,'string',dnames,'value',cType.DiagnosisMethod.WASTE_EXTERNAL);
				else
					set(app.tdm_popup,'string',dnames(1:2),'value',cType.DiagnosisMethod.WASTE_EXTERNAL);
                end
                app.ViewIndexTable(tm.getResultInfo)
                app.model=tm;
            else
				set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
				logtext=' ERROR: Invalid Data Model. See Console Log';
                set(app.log,'string',logtext);
                printLogger(data);
            end	
        end

        function activateSummary(app,~,~)
		% Get activate Summary callback
			val=get(app.sr_checkbox,'value');
            setSummary(app.model,logical(val));
			if val
                app.enableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewIndexTable(app.model.summaryResults);
			else
                app.disableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewIndexTable(app.model.getResultInfo);
			end
        end

        function activateRecycling(app,~,~)
		% Get activate Summary callback
			val=get(app.ra_checkbox,'value');
            setRecycling(app.model,logical(val));
            if val
                app.ViewIndexTable(app.model.wasteAnalysis);
            else
                app.ViewIndexTable(app.model.getResultInfo);
            end
        end

        function getCostTables(app,~,~)
		% Select Cost Table callback
            values=get(app.tables_popup,'string');
            pos=get(app.tables_popup,'value');
            setCostTables(app.model,values{pos});
            app.ViewIndexTable(app.model.thermoeconomicAnalysis);
        end

		function getState(app,~,~)
		% Get state callback
			ind=get(app.state_popup,'value');
			setState(app.model,app.stateNames{ind});
            if app.model.isDiagnosis
                pdm=get(app.tdm_popup,'value');
				if pdm ~= cType.DiagnosisMethod.NONE
                    app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
				end
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            end
            app.ViewIndexTable(app.model.getResultInfo);
        end

        function getReferenceState(app,~,~)
		% Get state callback
			ind=get(app.state_popup,'value');
			setReferenceState(app.model,app.stateNames{ind});
            if app.model.isDiagnosis
                pdm=get(app.tdm_popup,'value');
				if pdm ~= cType.DiagnosisMethod.NONE
                    app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                    app.ViewIndexTable(app.model.thermoeconomicDiagnosis);
				end
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.getResultInfo);
            end
		end

		function getSample(app,~,~)
		% Get Resources Sample callback
			ind=get(app.sample_popup,'value');
			app.model.setResourceSample(app.sampleNames{ind});
            app.ViewIndexTable(app.model.thermoeconomicAnalysis);
        end

		function getDiagnosisMethod(app,~,~)
		% Get WasteDiagnosis callback
            values=get(app.tdm_popup,'string');
            pos=get(app.tdm_popup,'value');
			setDiagnosisMethod(app.model,values{pos});
			if pos==cType.DiagnosisMethod.NONE
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.getResultInfo);
            elseif app.model.isDiagnosis
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.model.thermoeconomicDiagnosis);
			end
        end

        function getActiveWaste(app,~,~)
        % Get WasteDiagnosis callback
            values=get(app.wf_popup,'string');
            pos=get(app.wf_popup,'value');
            setActiveWaste(app.model,values{pos});
            app.ViewIndexTable(app.model.wasteAnalysis);
        end

		function saveResult(app,~,~)
		% Save results callback
			default_file=app.resultFile;
			[file,path,ext]=uiputfile(cType.SAVE_RESULTS,'Select File',default_file);
            if ext % File has been selected
                cd(path);
                res=app.currentNode;
				slog=saveResults(res,file);
                printLogger(slog)
                if slog.status
				    app.resultFile=file;
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Save Results %s',res.ResultName);		    
                else
                    logtext=sprintf(' ERROR: Result file %s could NOT be saved', file);
                end
                set(app.log,'string',logtext);
            end
        end

        function showIndexTable(app,src,~)
        % Show Index Table callback
            set(app.log,'string',cType.EMPTY_CHAR);
            idx=get(src,'UserData');
            res=getResultInfo(app.model,idx);
            if res.status
                app.ViewIndexTable(res);
            else
                logtext=sprintf('ERROR: Result %s is not available',cType.ResultVar{idx});
                set(app.log,'string',logtext);
            end
        end
    
        function getResult(app,src,~)
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
        end

        function getResultModel(app,~,~)
        % Get Result model callback
        % Store model object into workspace
            assignin('base', 'model', app.model);
        end

        function setDebug(app,evt,~)
        % Menu Debug callback
            val=~app.debug;
            check=log2str(val);
            app.debug=val;
            set(evt,'checked',check);
            if isValid(app.model)
                setDebug(app.model,val);
            end
        end

        function setConsole(app,src,~)
        % Menu Console callback
            val=~app.console;
            check=log2str(val);
            app.console=val;
            set(src,'checked',check);
            if app.console
                set(app.mn_panel,'checked','off');
                app.panel=false;
                app.resPanel.hidePanel;
            end
        end

        function setPanel(app,src,~)
        % Menu Panel callback
            val=~app.panel;
            check=log2str(val);
            app.panel=val;
            set(src,'checked',check);
            if app.panel
                set(app.mn_console,'checked','off');
                app.console=false;
            else
                app.resPanel.hidePanel;
            end
        end

        function synchronizeParameters(app,~,~)
        % Menu Synchronize callback. 
        %   Synchronize the widgets with thermoeconomic model parameters 
            tm=app.model;
            set(app.sr_checkbox,'value',tm.Summary);
            set(app.ra_checkbox,'value',tm.Recycling);
            set(app.tables_popup,'value',cType.getCostTables(tm.CostTables));
            set(app.tdm_popup,'value',cType.getDiagnosisMethod(tm.DiagnosisMethod));
            set(app.state_popup,'value',app.model.getStateId(tm.State));
            set(app.rstate_popup,'value',app.model.getStateId(tm.ReferenceState));
            set(app.sample_popup,'value',app.model.getSampleId(tm.ResourceSample));
            set(app.wf_popup,'value',app.model.getWasteId(tm.ActiveWaste));
            if tm.isDiagnosis
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            end
            if tm.Summary
                app.enableResults(cType.ResultId.SUMMARY_RESULTS);
            else
                app.disableResults(cType.ResultId.SUMMARY_RESULTS);
            end
        end

        function aboutTaes(~,~,~)
        % About TaesTool callback
        % Show TaesLab web page
            web('https://www.exergoecology.com/TaesLab');
        end

        function closeApp(app,~,~)
        % Close callback
            if isValid(app.resPanel)
                app.resPanel.closeApp;
            end
            delete(app.fig);
        end

		%%%%%%%%%%%%%%%%%%%%%%%
		% Methods
		%%%%%%%%%%%%%%%%%%%%%%%
        function ViewIndexTable(app,res)
        % View the index table into the table panel
            if app.panel
                app.resPanel.showResults(res);
            elseif app.console
                showResults(res);
            end
            app.currentNode=res;
            logtext=sprintf('INFO: Current Result is %s',res.ResultName);
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
            xsize=400; ysize=480;
            xpos=ss(3)/2-xsize;
            ypos=(ss(4)-ysize)/2;
            % Create figure
            hf=figure('visible','off','menubar','none',...
			          'name','Thermoeconomic Panel',...
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
            d=uimenu (hf,'label', '&Show', 'accelerator', 'd');
            e=uimenu (hf,'label', '&Results', 'accelerator', 't');
            h=uimenu (hf,'label', '&Help', 'accelerator', 'h');
            uimenu (h,'label', 'About',...
                'callback', @(src,evt) app.aboutTaes(src,evt))
			uimenu (f, 'label', 'Open', 'accelerator', 'o', ...
				'callback', @(src,evt) app.getFile(src,evt));
            app.mn_save=uimenu (f,'label','Save','accelerator', 's',...
                'callback', @(src,evt) app.saveResult(src,evt));
            uimenu (f, 'label', 'Close', 'accelerator', 'q', ...
				'callback', @(src,evt) app.closeApp(src,evt));
            %Debug Menu
            app.debug=true;
            app.mn_debug=uimenu (d,'label','Debug','accelerator','d',...,
                'enable','on','checked','on',...
                'callback',@(src,evt) app.setDebug(src,evt));
            % Console Menu
            app.console=false;
            app.mn_console=uimenu (d,'label','Console','accelerator','c',...,
                'enable','on','checked','off',...
                'callback',@(src,evt) app.setConsole(src,evt));
            % Panel Menu
            app.panel=false;
            app.mn_panel=uimenu (d,'label','Panel','accelerator','p',...,
                'enable','on','checked','off',...
                'callback',@(src,evt) app.setPanel(src,evt));
            % Synchronize Menu
            app.mn_sync=uimenu (d,'label','Synchronize','accelerator','z',...,
            'enable','off','callback',@(src,evt) app.synchronizeParameters(src,evt));

            % Results Menu
            app.menu=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO-2
                app.menu{i}=uimenu(e,...
                    'Label',cType.Results{i},...
                    'UserData',i,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getResult(src,evt));
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
                 'position', [0.01, 0.05, 0.98, 0.94]);

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
                   'string', 'Recycling Analysis:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Activate Recycling',...
                   'position', [0.06 0.41 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Summary Results:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Summary Results',...
                   'position', [0.06 0.34 0.36 0.045]);

            uicontrol (p1,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Output File:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Result File',...
                   'position', [0.06 0.27 0.36 0.045]);

			% Object widgets
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

            app.ra_checkbox = uicontrol (p1,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.activateRecycling(src,evt),...
					'position', [0.44 0.405 0.47 0.045]);

            app.sr_checkbox = uicontrol (p1,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.activateSummary(src,evt),...
					'position', [0.44 0.335 0.47 0.045]);

            app.outputFileName=[cType.RESULT_FILE,'.xlsx'];
            app.resultFile=[pwd,filesep,app.outputFileName];
			app.ofile_text = uicontrol (p1,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string',app.outputFileName,...
					'backgroundcolor',[0.95 1 0.95],...
					'horizontalalignment', 'left',...
					'position', [0.44 0.27 0.47 0.045]);

            app.open_button = uicontrol (p1,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Load',....
					'callback', @(src,evt) app.getFile(src,evt),...
					'position', [0.06 0.04 0.25 0.06]);

			app.save_buttom = uicontrol (p1,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Save',...
					'callback', @(src,evt) app.saveResult(src,evt),...
					'position', [0.66 0.04 0.25 0.06]);
            % Make the figure visible
			set(hf,'visible','on');
            app.fig=hf;
            % Assing Table Index Panel
            app.resPanel=ResultsPanel;
        end

		function initInputParameters(app)
		    % Initialize widgets
			set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
            set(app.mn_save,'enable','off');
			set(app.save_buttom,'enable','off');
            set(app.sr_checkbox,'enable','off');
            set(app.ra_checkbox,'enable','off');
            set(app.sr_checkbox,'value',0);
            set(app.ra_checkbox,'value',0);
            set(app.save_buttom,'enable','off');
			set(app.tables_popup,'value',cType.CostTables.DIRECT,'enable','off');
			set(app.tdm_popup,'string',{'NONE'},'value',cType.DiagnosisMethod.NONE,'enable','off');
            set(app.wf_popup,'string',{'NONE'},'value',1,'enable','off');
			set(app.state_popup,'string',{'Reference'},'value',1,'enable','off');
            set(app.rstate_popup,'string',{'Reference'},'value',1,'enable','off');
			set(app.sample_popup,'string',{'Base'},'value',1,'enable','off');
            set(app.open_button,'enable','on');
            app.tableIndex=cType.EMPTY;
            app.currentNode=cType.EMPTY;
            arrayfun(@(i) app.disableResults(i), 1:cType.MAX_RESULT_INFO);
		end
	end
end

