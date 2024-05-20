classdef TaesPanel < handle
% Graphic user interface to select the thermoeconomic model parameters.
% Compatible App for Matlab/Octave
% Execute the basic functions of class cThermoeconomicModel:
%   - productiveStructure
%   - thermoeconomicState
%   - thermoeconomicAnalysis
%   - thermoeconomicDiagnosis
%	- wasteAnalysis
% and perform the following operations:
%   - Save the results in several formats (xlsx, csc, html, txt
%   - Save variables in the base workspace
%   - View Result in tables and graphs
%
%	USAGE: app=ThermoeconomicPanel;
% See also cThermoeconomicModel
%
    properties(Access=private)
        % Widgets definition
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
		sh_checkbox     % Show in console widget
		gr_checkbox     % Select graphic widget
        sr_checkbox     % Summary Results widget
		mn_sr  			% Save Result menu widget
        mn_sd           % Save Data Model menu widget
        mn_ss           % Save General Summary menu widget
        mn_sfp          % Save Diagram FP menu widget
        mn_spd          % Save Productive Diagram menu widget
        menu            % Results Menu cell array widgets
        ptb             % Toolbar cell array widgets
    end

	properties(Access=private)
    % Appplication variables
        model           % cThermoeconomicModel object
        stateNames      % State Names
        sampleNames     % Resource Sample names
        wasteFlows      % Waste Flows
        activeWaste     % Active Waste Flow for Recycling
	    console         % Show results in console
        showGraph       % Show results in GUI
        resultFile      % Full results file name
        outputFileName  % Sort output file name
    end

    methods
        function app=TaesPanel()
		% ThermoeconomicPanel constructor
            % Initialize application variabbles
            app.console=false;
            app.showGraph=false;
            app.outputFileName=[cType.RESULT_FILE,'.xlsx'];
		    app.resultFile=[pwd,filesep,app.outputFileName];
			app.model=cStatusLogger();
            % Create GUI components
            createComponents(app);
            initInputParameters(app);
        end
	end

	methods (Access=private)
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Callback Functions
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		function getFile(app,~,~)
		% Get data model file callback
		% Select file and path
			app.initInputParameters;
            [file,path]=uigetfile({'*.json;*.csv;*.xlsx;*.xml;*.mat','Suported Data Models'});
			if file
				cd(path);
				set(app.log,'string','');
				set(app.mfile_text,'string',file);
			else
				logtext=' ERROR: No file selected';
			    set(app.log,'string',logtext);
				set(app.mfile_text,'string','Not Model Available');
				return
			end
			% Read and Check Data Model
			data=checkDataModel(file);
			if isValid(data) %Assign parameters
				tm=cThermoeconomicModel(data,'Debug',false);
				set(app.mfile_text,'backgroundcolor',[0.95 1 0.95]);
                app.enableResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
				app.enableResults(cType.ResultId.THERMOECONOMIC_STATE);
				app.enableResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
                app.enableResults(cType.ResultId.WASTE_ANALYSIS);
                app.enableResults(cType.ResultId.DIAGRAM_FP);
                app.enableResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
                app.enableResults(cType.ResultId.DATA_MODEL);
                app.enableResults(cType.ResultId.RESULT_MODEL);
				set(app.mn_sr,'enable','on');
                set(app.mn_sd,'enable','on');
                set(app.mn_sfp,'enable','on');
                set(app.mn_spd,'enable','on');
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
				if tm.isWaste
                    app.wasteFlows=tm.WasteFlows;
                    set(app.wf_popup,'enable','on','string',app.wasteFlows);
                    set(app.ra_checkbox,'enable','on');
					set(app.tdm_popup,'string',dnames,'value',cType.DiagnosisMethod.WASTE_EXTERNAL);
				else
					set(app.tdm_popup,'string',dnames(1:2),'value',cType.DiagnosisMethod.WASTE_EXTERNAL);
				end
				logtext=' INFO: Valid Data Model';
                app.model=tm;
            else
				set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
				logtext=' ERROR: Invalid Data Model';
			end
			set(app.log,'string',logtext);
			data.printLogger;
        end

        function activateSummary(app,~,~)
		% Get activate Summary callback
			val=get(app.sr_checkbox,'value');
			if val
				app.model.Summary=true;
                app.enableResults(cType.ResultId.SUMMARY_RESULTS);
				set(app.mn_ss,'enable','on');
			else
				app.model.Summary=false;
                app.disableResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
				set(app.mn_ss,'enable','off');
			end
        end

        function activateRecycling(app,~,~)
		% Get activate Summary callback
			val=get(app.ra_checkbox,'value');
            app.model.Recycling=val;
        end

        function getTables(app,~,~)
		% Select Cost Table callback
            values=get(app.tables_popup,'string');
            pos=get(app.tables_popup,'value');
            app.model.CostTables=values{pos};
        end

		function getState(app,~,~)
		% Get state callback
			ind=get(app.state_popup,'value');
			app.model.State=app.stateNames{ind};
			if app.model.isDiagnosis
				set(app.tdm_popup,'enable','on');
                pdm=get(app.tdm_popup,'value');
				if pdm ~= cType.DiagnosisMethod.NONE
                    app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
				end
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
				set(app.tdm_popup,'enable','off');
			end
        end

        function getReferenceState(app,~,~)
		% Get state callback
			ind=get(app.state_popup,'value');
			app.model.ReferenceState=app.stateNames{ind};
			if app.model.isDiagnosis
				set(app.tdm_popup,'enable','on');
                pdm=get(app.tdm_popup,'value');
				if pdm ~= cType.DiagnosisMethod.NONE
                    app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
				end
			else
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
				set(app.tdm_popup,'enable','off');
			end
		end

		function getSample(app,~,~)
		% Get Resources Sample callback
			ind=get(app.sample_popup,'value');
			app.model.ResourceSample=app.sampleNames{ind};
        end

		function getDiagnosisMethod(app,~,~)
		% Get WasteDiagnosis callback
            values=get(app.tdm_popup,'string');
            pos=get(app.tdm_popup,'value');
			app.model.DiagnosisMethod=values{pos};
			if pos==cType.DiagnosisMethod.NONE
                app.disableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
			else
                app.enableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
			end
        end

        function getActiveWaste(app,~,~)
        % Get WasteDiagnosis callback
            values=get(app.wf_popup,'string');
            pos=get(app.wf_popup,'value');
            app.model.ActiveWaste=values{pos};
        end

		function getPrinter(app,~,~)
		% Get show in console (Printer) callback
			val=get(app.sh_checkbox,'value');
			if val
				app.console=true;
			else
				app.console=false;
			end
		end

		function getShowGraph(app,~,~)
		% Get Save format callback
            val=get(app.gr_checkbox,'value');
            if val
				app.showGraph=true;
			else
				app.showGraph=false;
            end
		end

		function saveResult(app,~,~)
		% Save results callback
			default_file=app.resultFile;
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.html', 'HTML files'},...
                                        'Select File',default_file);
            cd(path);
            if ext % File has been selected
				slog=saveResults(app.model,file);
                if isValid(slog)
				    app.resultFile=file;
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Results saved in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Result file %s could NOT be saved', file);
                    printLogger(slog);
                    app.model.addLogger(slog);
                end
            end
            set(app.log,'string',logtext);
        end

        function saveDataModel(app,~,~)
        % Save Data model callback
			[file,path,ext]=uiputfile({'*.mat','MAT Files';'*.xlsx','XLSX Files';'*.csv','CSV Files'; ...
                '*.xml','XML Files';'*.json','JSON Files'},'Select File',cType.DATA_MODEL_FILE);
            cd(path);
            if ext % File has been selected
				slog=saveDataModel(app.model,file);
                if isValid(slog)
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Data Model saved in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Result file %s could NOT be saved', file);
                    printLogger(slog);
                    app.model.addLogger(slog);
                end
            end
            set(app.log,'string',logtext);
        end

        function saveSummary(app,~,~)
        % Save Summary Results
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.html', 'HTML files'},...
                'Select File',cType.SUMMARY_FILE);
            cd(path);
            if ext % File has been selected
				slog=saveSummary(app.model,file);
                if isValid(slog)
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Summary saved in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Summary file %s could NOT be saved', file);
                    printLogger(slog);
                    app.model.addLogger(slog);
                end
            end
            set(app.log,'string',logtext);
        end

        function saveDiagramFP(app,~,~)
        % Save Diagram FP tables
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.html', 'HTML files'},...
                                        'Select File',cType.DIAGRAM_FILE);
            cd(path);
            if ext % File has been selected
				slog=saveDiagramFP(app.model,file);
                if isValid(slog)
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Diagram FP Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Diagram FP file %s could NOT be saved', file);
                    printLogger(slog);
                    app.model.addLogger(slog);
                end
            end
            set(app.log,'string',logtext);
        end

		function saveProductiveDiagram(app,~,~)
        % Save Productive Diagram Tables
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.html', 'HTML files'},...
                                        'Select File',cType.DIAGRAM_FILE);
            cd(path);
            if ext % File has been selected
				slog=saveProductiveDiagram(app.model,file);
                if isValid(slog)
				    set(app.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Productive Diagram Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Productive Diagram file %s could NOT be saved', file);
                    printLogger(slog);
                    app.model.addLogger(slog);
                end
            end
            set(app.log,'string',logtext);
        end

        function getResult(app,src,~)
        % Callback for toolbar and results menu
            set(app.log,'string','');
            idx=get(src,'UserData');
            res=app.model.getResultInfo(idx);
            if ~isempty(res) && res.isValid
                varname=cType.ResultVar{idx};
                if app.console
					printResults(res);
                end
                assignin('base', varname, res);
                logtext=sprintf(' INFO: Results store in %s',varname);
				if app.showGraph
					if isOctave
						TablesPanel(res);
					else
						ViewResults(res);
					end
				end
			else
				logtext=sprintf('ERROR: Result %s is not available',res.ResultName);
            end
			set(app.log,'string',logtext);
        end

        function aboutTaes(~,~,~)
        % Show TaesLab web page
            web('https://www.exergoecology.com/TaesLab');
        end

		%%%%%%%%%%%%%%%%%%%%%%%
		% Methods
		%%%%%%%%%%%%%%%%%%%%%%%
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

        function createComponents(app)
        % Create Figure Components
			% Determine the scale depending on screen size
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/4;
            ysize=ss(4)/1.75;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;

            % Create figure
            hf=figure('visible','off','menubar','none',...
			          'name','Thermoeconomic Analysis Panel',...
                      'numbertitle','off','color',[0.94 0.94 0.94],...
                      'resize','on','Position',[xpos,ypos,xsize,ysize]);

            % Tool Bar
			tb = uitoolbar(hf);
            app.ptb=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO
                app.ptb{i}=uipushtool (tb,...
                    'CData',cType.getIcon(i),...
                    'UserData',i,'Enable','off',...
                    'Tooltipstring',cType.Results{i},...
                    'ClickedCallback', @(src,evt) app.getResult(src,evt));
            end

			% Menus
            f=uimenu (hf,'label', '&File', 'accelerator', 'f');
            e=uimenu (hf,'label', '&Results', 'accelerator', 't');
            h=uimenu (hf,'label', '&Help', 'accelerator', 'h');
            uimenu (h,'label', 'About',...
                'callback', @(src,evt) app.aboutTaes(src,evt))
			uimenu (f, 'label', 'Open', 'accelerator', 'o', ...
				'callback', @(src,evt) app.getFile(src,evt));
            uimenu (f, 'label', 'Close', 'accelerator', 'q', ...
				'callback', 'close (gcf)');
            s=uimenu (f,'label','Save','accelerator','s');
			app.mn_sr=uimenu (s, 'label', 'Model Results',...
				'callback', @(src,evt) app.saveResult(src,evt));
            app.mn_sd=uimenu (s, 'label', 'Data Model',...
				'callback', @(src,evt) app.saveDataModel(src,evt));
            app.mn_ss=uimenu (s, 'label', 'Summary',...
				'callback', @(src,evt) app.saveSummary(src,evt));
            app.mn_sfp=uimenu (s, 'label', 'Diagram FP',...
				'callback', @(src,evt) app.saveDiagramFP(src,evt));
            app.mn_spd=uimenu (s, 'label', 'Productive Diagram',...
				'callback', @(src,evt) app.saveProductiveDiagram(src,evt));
            app.menu=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO
                app.menu{i}=uimenu(e,...
                    'Label',cType.Results{i},...
                    'UserData',i,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getResult(src,evt));
            end
				
			% Decoration panel
            uipanel (hf,'title', 'Input Parameters', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.01, 0.36, 0.98, 0.61]);

			uipanel (hf,'title', 'Output Parameters', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.01, 0.01, 0.98, 0.30]);

			% Labels Input Parameters
            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'fontname','Verdana','fontsize',9,...
                   'string', 'Data Model File:',...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select data model file',...
                   'position', [0.06 0.86 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Reference State:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Reference State for Analysis',...
                   'position', [0.06 0.80 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Operation State:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Operation State for Analysis',...
                   'position', [0.06 0.74 0.36 0.04]);

			uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Resources Cost:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Resource Sample for Analysis',...
                   'position', [0.06 0.68 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Cost Tables:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Cost Tables',...
                   'position', [0.06 0.62 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Diagnosis Method:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Diagnosis Method',...
                   'position', [0.06 0.56 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Recycled Flow:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Waste for Recycling Analysis',...
                   'position', [0.06 0.50 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Recycling Analysis:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Activate Recycling',...
                   'position', [0.06 0.44 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Summary Results:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Summary Results',...
                   'position', [0.06 0.38 0.36 0.04]);


			% Labels output parameters
            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Output File:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Result File',...
                   'position', [0.06 0.20 0.36 0.04]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Show in Console:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Show results in console',...
                   'position', [0.06 0.14 0.36 0.04]);

			uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Show Graphs:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Show Results in GUI',...
                   'position', [0.06 0.08 0.36 0.04]);

			% object widget
            app.log = uicontrol (hf,'style', 'text',...
                    'units', 'normalized',...
                    'fontname','Verdana','fontsize',9,...
                    'string', '',...
                    'backgroundcolor',[0.85 0.85 0.85],...
                    'horizontalalignment', 'left',...
                    'position', [0.014 0.014 0.973 0.04]);

			app.mfile_text = uicontrol (hf,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string', ' Not Model Available',...
					'horizontalalignment', 'left',...
					'position', [0.38 0.87 0.40 0.04]);

			app.open_button = uicontrol (hf,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Open',....
					'callback', @(src,evt) app.getFile(src,evt),...
					'position', [0.80 0.867 0.15 0.045]);

           app.rstate_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'backgroundcolor',[0.9 0.9 0.94],...
					'callback', @(src,evt) app.getReferenceState(src,evt),...
					'position', [0.38 0.80 0.4 0.04]);
            
            app.state_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getState(src,evt),...
					'position', [0.38 0.74 0.4 0.04]);

 			app.sample_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getSample(src,evt),...
					'position', [0.38 0.68 0.4 0.04]);

			 app.tables_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'string', cType.CostTablesOptions,...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getTables(src,evt),...
					'position', [0.38 0.62 0.4 0.04]);

			app.tdm_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getDiagnosisMethod(src,evt),...
					'position', [0.38 0.56 0.4 0.04]);

           app.wf_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.getActiveWaste(src,evt),...
					'position', [0.38 0.50 0.4 0.04]);

            app.ra_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.activateRecycling(src,evt),...
					'position', [0.38 0.44 0.04 0.04]);

            app.sr_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) app.activateSummary(src,evt),...
					'position', [0.38 0.38 0.04 0.04]);

            % Output Control Widgets
			app.ofile_text = uicontrol (hf,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string',app.outputFileName,...
					'backgroundcolor',[0.95 1 0.95],...
					'horizontalalignment', 'left',...
					'position', [0.38 0.20 0.4 0.04]);

			app.save_buttom = uicontrol (hf,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Save',...
					'callback', @(src,evt) app.saveResult(src,evt),...
					'position', [0.80 0.197 0.15 0.045]);

			app.sh_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'value', 0,...
					'callback', @(src,evt) app.getPrinter(src,evt),...
					'position', [0.38 0.14 0.04 0.04]);

			app.gr_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'value', 0,...
					'callback', @(src,evt) app.getShowGraph(src,evt),...
					'position', [0.38 0.08 0.04 0.04]);
            % Make the figure visible
			set(hf,'visible','on');
        end

		function initInputParameters(app)
		    % Initialize widgets
			set(app.mfile_text,'backgroundcolor',[1 0.5 0.5]);
            for i=1:cType.MAX_RESULT_INFO
                app.disableResults(i);
            end
			set(app.mn_sr,'enable','off');
            set(app.mn_sd,'enable','off');
            set(app.mn_ss,'enable','off');
            set(app.mn_sfp,'enable','off');
            set(app.mn_spd,'enable','off');
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
		end
	end
end
