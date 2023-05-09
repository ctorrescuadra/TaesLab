classdef ThermoeconomicPanel < handle
% ThermoeconomicPanel is graphic user interface to select the thermoeconomic model parameters.
% Compatible App for Matlab/Octave
%  	Execute the basic functions of ExIoLab class cThermoeconomicModel:
%   	- productiveStructure
%   	- thermoeconomicState
%   	- thermoeconomicAnalysis
%   	- thermoeconomicDiagnosis
%  	and perform the following operations:
%   	- Save the results as excel or csv files
%   	- Show result on console
%   	- Save variables in the base workspace
%   	- View Result in tables and graphs
% See also cThermoeconomicModel
%
    properties(Access=private)
		stateNames      % State Names
        sampleNames     % Resource Sample names
		log             % Log widget
		mfile_text      % Model file widget
		open_button     % Open Data Model widget
		save_buttom     % Save Result widget
        ofile_text      % Output filename widget
        state_popup     % Select State widget
        sample_popup    % Select Resources widget
        varmode_popup   % Select VarMode widget
        tables_popup    % Select CostTables widget
		tdm_popup       % Diagnosis method widget
        vf_checkbox     % Select VarFormat widget
		sh_checkbox     % Show in console widget
		gr_checkbox     % Select file button widget
        sr_checkbox     % Summary Results widget
		mn_ps           % Table Productive Structure menu widget
		mn_ts           % Thermoeconomic State menu widget
		mn_ta           % Thermoeconomic Analysis menu widget
        mn_td           % Thermoeconomic Diagnosis menu widget
        mn_gs           % Summary Results menu widget
        mn_vr           % View Model Results menu widget
		mn_sr  			% Save Result menu widget
        mn_sd           % Save Data Model menu widget
        mn_sg           % Save General Summary menu widget
        mn_fp           % Save Diagram FP menu widget
		tb_ps			% Productive Structure tool bar widget
		tb_ts           % Thermoeconomic State tool bar widget
        tb_ta			% Thermoeconomic Analysis tool bar widget
        tb_td			% Thermoeconomic Diagnosis tool bar widgt
        tb_gs           % General Summary Results tool bar widget
    end

	properties(GetAccess=public,SetAccess=private)
        Model           	% Thermoeconomic Model
		Options         	% Global presentation options
		Results				% Results structure
    end

    methods
        function obj=ThermoeconomicPanel()
		% ThermoeconomicPanel constructor
			% Initilize non-graphics object variables
			outputFileName=strcat(cType.RESULT_FILE,'.xlsx');
			obj.Options=struct('Printer',false,...
				'VarMode',cType.VarMode.NONE, ...
				'ResultFile',[pwd,filesep,outputFileName],...
				'VarFormat',false,...
				'ShowGraph',false);
			obj.Model=cStatusLogger();
			% Create figure
            ss=get(groot,'ScreenSize');
            xsize=ss(3)/3.5;
            ysize=ss(4)/2;
            xpos=(ss(3)-xsize)/2;
            ypos=(ss(4)-ysize)/2;
            hf=figure('visible','off','menubar','none',...
			          'name','Thermoeconomic Analysis Tool',...
                      'numbertitle','off','color',[0.94 0.94 0.94],...
                      'resize','on','Position',[xpos,ypos,xsize,ysize]);
            % Tool Bar
			tb = uitoolbar(hf);
			obj.tb_ps = uipushtool (tb, 'cdata', cType.getIcon('ProductiveStructure'),...
				'tooltipstring','Show Productive Structure',...
				'clickedcallback', @(src,evt) obj.productiveStructure(src,evt));
			obj.tb_ts = uipushtool (tb, 'cdata', cType.getIcon('ThermoeconomicState'),...
			    'tooltipstring','Show Thermoeconomic State',...
			    'clickedcallback', @(src,evt) obj.thermoeconomicState(src,evt));
            obj.tb_ta = uipushtool (tb, 'cdata', cType.getIcon('ThermoeconomicAnalysis'),...
			    'tooltipstring','Thermoeconomic Analysis',...
			    'clickedcallback', @(src,evt) obj.thermoeconomicAnalysis(src,evt));
            obj.tb_td = uipushtool (tb, 'cdata', cType.getIcon('ThermoeconomicDiagnosis'),...
			    'tooltipstring','Thermoeconomic Diagnosis',...
			    'clickedcallback', @(src,evt) obj.thermoeconomicDiagnosis(src,evt));
            obj.tb_gs = uipushtool (tb, 'cdata', cType.getIcon('SummaryResults'),...
			    'tooltipstring','General Summary',...
			    'clickedcallback', @(src,evt) obj.summaryResults(src,evt));
			% Menus
            f=uimenu (hf,'label', '&File', 'accelerator', 'f');
            e=uimenu (hf,'label', '&Tools', 'accelerator', 't');
            uimenu (hf,'label', '&Help', 'accelerator', 'h');
			uimenu (f, 'label', 'Open', 'accelerator', 'o', ...
				'callback', @(src,evt) obj.getFile(src,evt));
            uimenu (f, 'label', 'Close', 'accelerator', 'q', ...
				'callback', 'close (gcf)');
            s=uimenu (f,'label','Save','accelerator','s');
			obj.mn_sr=uimenu (s, 'label', 'Model Results',...
				'callback', @(src,evt) obj.saveResult(src,evt));
            obj.mn_sd=uimenu (s, 'label', 'Data Model',...
				'callback', @(src,evt) obj.saveDataModel(src,evt));
            obj.mn_sg=uimenu (s, 'label', 'Summary',...
				'callback', @(src,evt) obj.saveSummary(src,evt));
            obj.mn_fp=uimenu (s, 'label', 'Diagram FP',...
				'callback', @(src,evt) obj.saveDiagramFP(src,evt));

			obj.mn_ps=uimenu (e, 'label', 'Productive Structure',...
				'callback', @(src,evt) obj.productiveStructure(src,evt));
			obj.mn_ts=uimenu (e, 'label', 'Thermoeconomic State',...
				'callback', @(src,evt) obj.thermoeconomicState(src,evt));
			obj.mn_ta=uimenu (e, 'label', 'Thermoeconomic Analysis',...
				'callback', @(src,evt) obj.thermoeconomicAnalysis(src,evt));
			obj.mn_td=uimenu (e, 'label', 'Thermoeconomic Diagnosis',...
				'callback', @(src,evt) obj.thermoeconomicDiagnosis(src,evt));
            obj.mn_gs=uimenu (e, 'label', 'Summary Results',...
				'callback', @(src,evt) obj.summaryResults(src,evt));
            obj.mn_vr=uimenu (e, 'label', 'View Results Model',...
				'callback', @(src,evt) obj.viewResultsModel(src,evt));
				
			% Decoration panel
            uipanel (hf,'title', 'Input Parameters', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.01, 0.47, 0.98, 0.5]);

			uipanel (hf,'title', 'Output Parameters', ...
                 'units','normalized',...
                 'fontname','Verdana','fontsize',8,...
                 'position', [0.01, 0.01, 0.98, 0.42]);

			% Labels Input Parameters
            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'fontname','Verdana','fontsize',9,...
                   'string', 'Data Model File:',...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select data model file',...
                   'position', [0.08 0.84 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Operation State:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Operation State for Analysis',...
                   'position', [0.08 0.77 0.35 0.05]);

			uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Resources Cost:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Resource Sample for Analysis',...
                   'position', [0.08 0.70 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Cost Tables:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Cost Tables',...
                   'position', [0.08 0.63 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Diagnosis Method:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Diagnosis Method',...
                   'position', [0.08 0.56 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Summary Results:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Summary Results',...
                   'position', [0.08 0.49 0.35 0.05]);


			% Labels output parameters
            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Output File:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select Result File',...
                   'position', [0.08 0.30 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Result Mode:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Select mode to show results',...
                   'position', [0.08 0.23 0.35 0.05]);

            uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Show in Console:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Show results in console',...
                   'position', [0.08 0.16 0.35 0.05]);

			uicontrol (hf,'style', 'text',...
                   'units', 'normalized',...
                   'string', 'Show Graphs:',...
                   'fontname','Verdana','fontsize',9,...
                   'horizontalalignment', 'left',...
                   'tooltipstring','Show results in console',...
                   'position', [0.08 0.09 0.35 0.05]);

			% object widget
            obj.log = uicontrol (hf,'style', 'text',...
                    'units', 'normalized',...
                    'fontname','Verdana','fontsize',9,...
                    'string', '',...
                    'backgroundcolor',[0.85 0.85 0.85],...
                    'horizontalalignment', 'left',...
                    'position', [0.012 0.014 0.975 0.05]);

			obj.mfile_text = uicontrol (hf,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string', ' Not Model Available',...
					'horizontalalignment', 'left',...
					'position', [0.35 0.84 0.35 0.05]);

			obj.open_button = uicontrol (hf,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Open',....
					'callback', @(src,evt) obj.getFile(src,evt),...
					'position', [0.75 0.84 0.1 0.05]);

			obj.state_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) obj.getState(src,evt),...
					'position', [0.35 0.77 0.35 0.05]);

 			obj.sample_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) obj.getSample(src,evt),...
					'position', [0.35 0.70 0.35 0.05]);

			 obj.tables_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'string', cType.CostTablesOptions,...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) obj.getTables(src,evt),...
					'position', [0.35 0.63 0.35 0.05]);

			obj.tdm_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) obj.getDiagnosisMethod(src,evt),...
					'position', [0.35 0.56 0.35 0.05]);

            obj.sr_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'callback', @(src,evt) obj.activateSummary(src,evt),...
					'position', [0.35 0.49 0.35 0.05]);

			obj.ofile_text = uicontrol (hf,'style', 'text',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',10,...
					'string',outputFileName,...
					'backgroundcolor',[0.95 1 0.95],...
					'horizontalalignment', 'left',...
					'position', [0.35 0.30 0.35 0.05]);

			obj.save_buttom = uicontrol (hf,'style', 'pushbutton',...
					'units', 'normalized',...
					'fontname','Verdana','fontsize',9,...
					'string','Save',...
					'callback', @(src,evt) obj.saveResult(src,evt),...
					'position', [0.75 0.30 0.1 0.05]);

			obj.varmode_popup = uicontrol (hf,'style', 'popupmenu',...
					'units', 'normalized',...
					'string', cType.VarModeOptions,...
					'fontname','Verdana','fontsize',9,...
					'value',cType.VarMode.NONE,...
					'callback', @(src,evt) obj.getVarMode(src,evt),...
					'position', [0.35 0.23 0.35 0.05]);

   			obj.vf_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'value', 0,...
					'fontname','Verdana','fontsize',9,...
					'string','Format',...
					'callback', @(src,evt) obj.getVarFormat(src,evt),...
					'position', [0.75 0.23 0.15 0.05]);

			obj.sh_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'value', 0,...
					'callback', @(src,evt) obj.getPrinter(src,evt),...
					'position', [0.35 0.165 0.05 0.05]);

			obj.gr_checkbox = uicontrol (hf,'style', 'checkbox',...
					'units', 'normalized',...
					'value', 0,...
					'callback', @(src,evt) obj.getShowGraph(src,evt),...
					'position', [0.35 0.095 0.05 0.05]);
			obj.initInputParameters;
			set(hf,'visible','on');
		end

		function res=get.Results(obj)
		% get results info
			if obj.Model.isValid
				res=obj.Model.Results;
			else
				res=cStatusLogger();
			end
        end
	end

	methods (Access=private)
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Callback Functions
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		function getFile(obj,~,~)
		% Get data model file callback
		% Select file and path
			obj.initInputParameters;
            [file,path]=uigetfile({'*.json;*.csv;*.xlsx;*.xml;*.mat','Suported Data Models'});
			if file
				cd(path);
				set(obj.log,'string','');
				set(obj.mfile_text,'string',file);
			else
				logtext=' ERROR: No file selected';
			    set(obj.log,'string',logtext);
				set(obj.mfile_text,'string','Not Model Available');
				return
			end
			% Read and Check Data Model
			data=checkModel(file);
			if isValid(data) %Assign parameters
				tm=cThermoeconomicModel(data,'Debug',false);
				set(obj.mfile_text,'backgroundcolor',[0.95 1 0.95]);
				set(obj.mn_ts,'enable','on');
				set(obj.mn_ta,'enable','on');
				set(obj.mn_ps,'enable','on');
                set(obj.mn_vr,'enable','on');
				set(obj.mn_sr,'enable','on');
                set(obj.mn_sd,'enable','on');
                set(obj.mn_fp,'enable','on');
				set(obj.tb_ts,'enable','on');
                set(obj.tb_ta,'enable','on');
                set(obj.tb_ps,'enable','on');
                set(obj.sr_checkbox,'enable','on');
				set(obj.save_buttom,'enable','on');
				obj.stateNames=tm.getStateNames;
				set(obj.state_popup,'enable','on','string',obj.stateNames);
				if tm.isResourceCost
					obj.sampleNames=tm.getResourceSamples;
					set(obj.sample_popup,'enable','on','string',obj.sampleNames);
                    set(obj.tables_popup,'enable','on');
				end
				dnames=cType.DiagnosisOptions;
				if tm.isWaste
					set(obj.tdm_popup,'string',dnames,'value',cType.Diagnosis.WASTE_OUTPUT);
				else
					set(obj.tdm_popup,'string',dnames(1:2),'value',cType.Diagnosis.WASTE_OUTPUT);
				end
				logtext=' INFO: Valid Data Model';
                obj.Model=tm;
            else
				set(obj.mfile_text,'backgroundcolor',[1 0.5 0.5]);
				logtext=' ERROR: Invalid Data Model';
			end
			set(obj.log,'string',logtext);
			data.printLogger;
        end

        function activateSummary(obj,~,~)
		% Get activate Summary callback
			val=get(obj.sr_checkbox,'value');
			if val
				obj.Model.Summary=true;
                set(obj.tb_gs,'enable','on');
                set(obj.mn_sg,'enable','on');
			else
				obj.Model.Summary=false;
                set(obj.tb_gs,'enable','off');
                set(obj.mn_sg,'enable','off');
			end
        end

        function getTables(obj,~,~)
		% Select Cost Table callback
            values=get(obj.tables_popup,'string');
            pos=get(obj.tables_popup,'value');
            obj.Model.CostTables=values{pos};
        end

		function getState(obj,~,~)
		% Get state callback
			ind=get(obj.state_popup,'value');
			obj.Model.State=obj.stateNames{ind};
			if obj.Model.isDiagnosis
				set(obj.tdm_popup,'enable','on');
                pdm=get(obj.tdm_popup,'value');
				if pdm ~= cType.Diagnosis.NONE
					set(obj.mn_td,'enable','on');
					set(obj.tb_td,'enable','on');
				end
			else
				set(obj.mn_td,'enable','off');
				set(obj.tb_td,'enable','off');
				set(obj.tdm_popup,'enable','off');
			end
		end

		function getSample(obj,~,~)
		% Get Resources Sample callback
			ind=get(obj.sample_popup,'value');
			obj.Model.ResourceSample=obj.sampleNames{ind};
        end

		function getDiagnosisMethod(obj,~,~)
		% Get WasteDiagnosis callback
            values=get(obj.tdm_popup,'string');
            pos=get(obj.tdm_popup,'value');
			obj.Model.DiagnosisMethod=values{pos};
			if pos==cType.Diagnosis.NONE
				set(obj.mn_td,'enable','off');
				set(obj.tb_td,'enable','off');
			else
				set(obj.mn_td,'enable','on');
				set(obj.tb_td,'enable','on');
			end
		end

		function getVarMode(obj,~,~)
		% Get VarMode callback
           obj.Options.VarMode=get(obj.varmode_popup,'value');
		end

		function getVarFormat(obj,~,~)
		% Get VarFormat callback
			val=get(obj.vf_checkbox,'value');
			if val
				obj.Options.VarFormat=true;
			else
				obj.Options.VarFormat=false;
			end
		end

		function getPrinter(obj,~,~)
		% Get show in console (Printer) callback
			val=get(obj.sh_checkbox,'value');
			if val
				obj.Options.Printer=true;
			else
				obj.Options.Printer=false;
			end
		end

		function getShowGraph(obj,~,~)
		% Get Save format callback
            val=get(obj.gr_checkbox,'value');
            if val
				obj.Options.ShowGraph=true;
			else
				obj.Options.ShowGraph=false;
            end
		end

		function saveResult(obj,~,~)
		% Save file callback
			default_file=obj.Options.ResultFile;
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.mat','MAT Files'},'Select File',default_file);
            cd(path);
            if ext % File has been selected
				slog=saveResultsModel(obj.Model,file);
                if isValid(slog)
				    obj.Options.ResultFile=file;
				    set(obj.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Results Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Result file %s could NOT be saved', file);
                    printLogger(slog);
                    obj.Model.addLogger(slog);
                end
            end
            set(obj.log,'string',logtext);
        end

        function saveDataModel(obj,~,~)
            default_file='DataModel.mat';
			[file,path,ext]=uiputfile({'*.mat','MAT Files';'*.xlsx','XLSX Files';'*.csv','CSV Files'; ...
                '*.xml','XML Files';'*.json','JSON Files'},'Select File',default_file);
            cd(path);
            if ext % File has been selected
				slog=saveDataModel(obj.Model,file);
                if isValid(slog)
				    set(obj.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Results Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Result file %s could NOT be saved', file);
                    printLogger(slog);
                    obj.Model.addLogger(slog);
                end
            end
            set(obj.log,'string',logtext);
        end

        function saveSummary(obj,~,~)
            default_file='SummaryResults.xlsx';
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.mat','MAT Files'},'Select File',default_file);
            cd(path);
            if ext % File has been selected
				slog=saveSummary(obj.Model,file);
                if isValid(slog)
				    set(obj.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Summary Results Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Summary Result file %s could NOT be saved', file);
                    printLogger(slog);
                    obj.Model.addLogger(slog);
                end
            end
            set(obj.log,'string',logtext);
        end

        function saveDiagramFP(obj,~,~)
            default_file='DiagramFP.xlsx';
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files';'*.csv','CSV Files';'*.mat','MAT Files'},'Select File',default_file);
            cd(path);
            if ext % File has been selected
				slog=saveDiagramFP(obj.Model,file);
                if isValid(slog)
				    set(obj.ofile_text,'string',file);
				    logtext=sprintf(' INFO: Diagram FP Available in file %s',file);			    
                else
                    logtext=sprintf(' ERROR: Diagram FP file %s could NOT be saved', file);
                    printLogger(slog);
                    obj.Model.addLogger(slog);
                end
            end
            set(obj.log,'string',logtext);
        end

		%%%%%%%%%%%%%%%%%%%%%%%
		% Methods
		%%%%%%%%%%%%%%%%%%%%%%%
		function productiveStructure(obj,~,~)
		% Show table FP callback
			set(obj.log,'string','');
			ps=obj.Model.productiveStructure;
			if ps.isValid
				if obj.Options.Printer
					printResults(ps);
				end
				res=getResultTables(ps,obj.Options.VarMode,obj.Options.VarFormat);
				logtext=sprintf(' INFO: Results Available in Variable ProductiveStructure');
				assignin('base', 'ProductiveStructure', res);
				if obj.Options.ShowGraph
					if isOctave
						viewTable(ps.Tables.flows,'SUMMARY');
					else
						ViewResults(ps);
					end
				end
			else
				logtext=' ERROR: Productive Structure Values are not available';
			end
			set(obj.log,'string',logtext);
		end

        function thermoeconomicState(obj,~,~)
        % ThermoeconomicState callback
			set(obj.log,'string','');
			ots=obj.Model.thermoeconomicState;
			if ots.isValid
				if obj.Options.Printer
					printResults(ots);
				end
				res=getResultTables(ots,obj.Options.VarMode,obj.Options.VarFormat);
				logtext=sprintf(' INFO: Results Available in Variable StateTables (%s)',ots.State);
				assignin('base', 'StateTables', res);
				if obj.Options.ShowGraph
					if isOctave
                    	viewTable(ots.Tables.eprocesses,ots.State);
					else
						ViewResults(ots);
					end
				end
			else
				logtext=' ERROR: Thermoeconomic State Values are not available';
			end
			set(obj.log,'string',logtext);
        end

		function thermoeconomicAnalysis(obj,~,~)
		% ThermoeconomicAnalisis callback
			set(obj.log,'string','');
			ota=obj.Model.thermoeconomicAnalysis;
			if ota.isValid
				if obj.Options.Printer
					printResults(ota);
				end
				res=getResultTables(ota,obj.Options.VarMode,obj.Options.VarFormat);
				logtext=sprintf(' INFO: Results Available in Variable CostTables (%s)',ota.State);
				assignin('base', 'CostTables', res);
				if obj.Options.ShowGraph
					if isOctave
						graphCost(ota)
					else
						ViewResults(ota);
					end
				end
			else
				logtext=' ERROR: Thermoeconomic Analysis Values are not available';
			end
			set(obj.log,'string',logtext);
		end

		function thermoeconomicDiagnosis(obj,~,~)
			% ThermoeconomicDiagnosis callback
			set(obj.log,'string','');
			otd=obj.Model.thermoeconomicDiagnosis;
			if otd.isValid
				if obj.Options.Printer
					printResults(otd);
				end
				res=getResultTables(otd,obj.Options.VarMode,obj.Options.VarFormat);
				logtext=sprintf(' INFO: Results Available in Variable DiagnosisTables (%s)',otd.State);
				assignin('base', 'DiagnosisTables', res);
				if obj.Options.ShowGraph
					if isOctave
						graphDiagnosis(otd);
					else
						ViewResults(otd);
					end
				end
			else
				logtext=' ERROR: Thermoeconomic Diagnosis Values are not available';
			end
			set(obj.log,'string',logtext);
        end

        function summaryResults(obj,~,~)
            set(obj.log,'string','');
            srt=obj.Model.summaryResults;
			if srt.isValid
				if obj.Options.Printer
					printResults(srt);
				end
				res=getResultTables(srt,obj.Options.VarMode,obj.Options.VarFormat);
				logtext=sprintf(' INFO: Results Available in Variable Summary Results');
				assignin('base', 'SummaryResults', res);
				if obj.Options.ShowGraph
					if isOctave
						graphSummary(srt);
					else
						ViewResults(srt);
					end
				end
			else
				logtext=' ERROR: Summary Results Values are not available';
			end
			set(obj.log,'string',logtext);
        end

        function viewResultsModel(obj,~,~)
            assignin('base', 'model', obj.Model);
            if isMatlab  
                ViewResults(obj.Model);
            end
        end

		function initInputParameters(obj)
		% Initialize widgets
			set(obj.mfile_text,'backgroundcolor',[1 0.5 0.5]);
			set(obj.mn_ts,'enable','off');
			set(obj.mn_ta,'enable','off');
			set(obj.mn_ps,'enable','off');
			set(obj.mn_td,'enable','off');
            set(obj.mn_vr,'enable','off');
			set(obj.mn_sr,'enable','off');
            set(obj.mn_sd,'enable','off');
            set(obj.mn_sg,'enable','off');
            set(obj.mn_gs,'enable','off');
            set(obj.mn_fp,'enable','off');
			set(obj.tb_ts,'enable','off');
			set(obj.tb_ta,'enable','off');
			set(obj.tb_ps,'enable','off');
			set(obj.tb_td,'enable','off');
            set(obj.tb_gs,'enable','off');
			set(obj.save_buttom,'enable','off');
            set(obj.sr_checkbox,'enable','off');
            set(obj.save_buttom,'enable','off');
			set(obj.tables_popup,'value',cType.CostTables.DIRECT,'enable','off');
			set(obj.tdm_popup,'string',{'NONE'},'value',cType.Diagnosis.NONE,'enable','off');
			set(obj.state_popup,'string',{'Reference'},'value',1,'enable','off');
			set(obj.sample_popup,'string',{'Base'},'value',1,'enable','off');
            set(obj.open_button,'enable','on');
		end
	end
end
