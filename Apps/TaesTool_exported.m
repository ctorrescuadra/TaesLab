classdef TaesTool_exported < matlab.apps.AppBase
    %TAESTOOL_EXPORTED Thermoeconomic Analysis of Energy Systems
    %   TaesApp makes thermoeconomic analysis and diagnosis of energy
    %   systems.
    %   - In the left panel, the data model and parameters could be
    %   selected
    %   - In the right panel, select the results to view in the central
    %   panel as tables or graphs
    %   - Results could be saved in different formats

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        FileMenu                      matlab.ui.container.Menu
        OpenMenu                      matlab.ui.container.Menu
        SaveMenu                      matlab.ui.container.Menu
        SaveResultsMenu               matlab.ui.container.Menu
        SaveDataModelMenu             matlab.ui.container.Menu
        SaveModelMenu                 matlab.ui.container.Menu
        CloseMenu                     matlab.ui.container.Menu
        ResultsMenu                   matlab.ui.container.Menu
        HelpMenu                      matlab.ui.container.Menu
        AboutMenu                     matlab.ui.container.Menu
        Toolbar                       matlab.ui.container.Toolbar
        GridLayout                    matlab.ui.container.GridLayout
        LogPanel                      matlab.ui.container.Panel
        LogField                      matlab.ui.control.Label
        Hyperlink                     matlab.ui.control.Hyperlink
        TableIndexPanel               matlab.ui.container.Panel
        UITable                       matlab.ui.control.Table
        InputParametersPanel          matlab.ui.container.Panel
        InputGridLayout               matlab.ui.container.GridLayout
        ViewTableDropDownLabel        matlab.ui.control.Label
        ReferenceStateDropDown        matlab.ui.control.DropDown
        ReferenceStateDropDownLabel   matlab.ui.control.Label
        DiagnosisMethodDropDown       matlab.ui.control.DropDown
        DiagnosisMethodDropDownLabel  matlab.ui.control.Label
        CostTablesDropDown            matlab.ui.control.DropDown
        CostTablesDropDownLabel       matlab.ui.control.Label
        ResourceCostDropDown          matlab.ui.control.DropDown
        ResourceCostDropDownLabel     matlab.ui.control.Label
        OperationStateDropDown        matlab.ui.control.DropDown
        OperationStateDropDownLabel   matlab.ui.control.Label
        DataModelEditField            matlab.ui.control.EditField
        DataModelEditFieldLabel       matlab.ui.control.Label
        ActiveWasteDropDownLabel      matlab.ui.control.Label
        ActiveWasteDropDown           matlab.ui.control.DropDown
        RecyclingAnalysisLabel        matlab.ui.control.Label
        RecyclingCheckBox             matlab.ui.control.CheckBox
        SummaryResultsLabel           matlab.ui.control.Label
        SummaryCheckBox               matlab.ui.control.CheckBox
        ResultsFileLabel              matlab.ui.control.Label
        OutputFileEditField           matlab.ui.control.EditField
        ViewTableDropDown             matlab.ui.control.DropDown
        LoadDataButton                matlab.ui.control.Button
        SaveButton                    matlab.ui.control.Button
    end

    
    properties (Access = public)
        Model   % Thermoeconomic Model
    end
    
    properties (Access = private)
        ResultFile  % Result file name
        CurrentNode % Selected group of tables
        TableIndex  % Current Table Index object
        ViewOption  % View Option
        menu        % Cell array containing uimenu widgets
        tb          % Cell array containing uipushtool widges
    end
    
    methods (Access = private)
        % Initialize Input parameters
        function InitInputProperties(app)
            app.DataModelEditField.BackgroundColor=[1 0.5 0.5];
            app.DataModelEditField.Value='No Model Available';
            app.SaveButton.Enable=false;
			app.CostTablesDropDown.Enable=false;
            app.CostTablesDropDown.Value=cType.DEFAULT_COST_TABLES;
            app.DiagnosisMethodDropDown.Enable=false;
            app.DiagnosisMethodDropDown.Items={cType.DEFAULT_DIAGNOSIS};
			app.DiagnosisMethodDropDown.Value=cType.DEFAULT_DIAGNOSIS;
            app.ReferenceStateDropDown.Enable=false;
            app.ReferenceStateDropDown.Items={'Reference','Operation'};
            app.ReferenceStateDropDown.Value='Reference';
            app.OperationStateDropDown.Enable=false;
            app.OperationStateDropDown.Items={'Reference','Operation'};
            app.OperationStateDropDown.Value='Reference';
            app.ResourceCostDropDown.Enable=false;
            app.ResourceCostDropDown.Items={'Base'};
            app.ResourceCostDropDown.Value='Base';
            app.SummaryCheckBox.Enable=false;
            app.SummaryCheckBox.Value=false;
            app.ViewTableDropDown.Enable=true;
            app.ViewOption=cType.TableView.CONSOLE;
            app.LogField.Text='';
            app.Model=cStatusLogger;
            app.UITable.Visible=false;
            app.CurrentNode=[];
        end

        % Show Tables Directory, when application stars
        function InitTableIndex(app)
            td=cTablesDefinition;
            tbl=td.getTablesDirectory({'DESCRIPTION','GRAPH'});
            app.UITable.ColumnWidth={'auto','6x','1x'};
            app.UITable.Data=[tbl.RowNames',tbl.Data];
            app.UITable.Visible=true;
        end

        % Show the index table in table panel
        function ViewIndexTable(app,res)
            app.TableIndexPanel.Title=res.ResultName;
            tbl=res.getTableIndex;
            app.UITable.ColumnWidth={'auto','6x','1x'};
            app.UITable.Data=[tbl.RowNames',tbl.Data];
            app.UITable.Visible=true;
            app.TableIndex=tbl;
            app.CurrentNode=res;
        end

        % Build Results Menu and Toolbar 
        function buildMenuToolbar(app)
            app.menu=cell(1,cType.MAX_RESULT_INFO);
            app.tb=cell(1,cType.MAX_RESULT_INFO);
            for i=1:cType.MAX_RESULT_INFO
                app.menu{i}=uimenu(app.ResultsMenu,...
                    'Text',cType.Results{i},...
                    'UserData',i,'Enable','off',...
                    'MenuSelectedFcn', @(src,evt) app.getResult(src,evt));
            end
            for i=1:cType.MAX_RESULT_INFO
                app.tb{i}=uipushtool (app.Toolbar,...
                    'CData',cType.getIcon(i),...,...
                    'UserData',i,'Enable','off',...
                    'Tooltip',cType.Results{i},...
                    'ClickedCallback', @(src,evt) app.getResult(src,evt));
            end
        end

        % Enable menu and toolbar buttons
        function EnableResults(app,idx)
            app.menu{idx}.Enable=true;
            app.tb{idx}.Enable=true;
        end

        % Disable menu and toolbar buttons
        function DisableResults(app,idx)
            app.menu{idx}.Enable=false;
            app.tb{idx}.Enable=false;
        end

        % View model results index table
        function ViewModelResults(app)
            res=app.Model.getResultInfo;
            app.ViewIndexTable(res);
        end

        % Generic callback for uimenu and uipushtool
        function getResult(app,src,~)
            idx=src.UserData;
            res=app.Model.getResultInfo(idx);
            if ~isempty(res)
                app.ViewIndexTable(res);
                varname=cType.ResultVar{idx};
                assignin('base', varname, res);
                logtext=sprintf(' INFO: Results store in %s',varname);
            else
                logtext='';
            end
            app.LogField.Text=logtext;
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            tables=cType.CostTablesOptions();
            app.CostTablesDropDown.Items=tables;
            outputFileName=strcat(cType.RESULT_FILE,'.xlsx');
            app.OutputFileEditField.Value=outputFileName;
			app.ResultFile=[pwd,filesep,outputFileName];
            app.buildMenuToolbar;
            app.InitInputProperties;
            InitTableIndex(app)
        end

        % Callback function: LoadDataButton, OpenMenu
        function LoadData(app, event)
            % Load datafile
            app.InitInputProperties;
            [file,path]=uigetfile({'*.json;*.xml*;.csv;*.xlsx;*.mat','Suported Data Models'});
            if file
			    cd(path);
			    app.DataModelEditField.Value=file;
            else
                logtext=' ERROR: No Model Available';
                app.LogField.Text=logtext; 
                return
            end
			% Read and Check Data Model
            data=checkDataModel(file);
            % Assing parameters and execute base analysis
            if isValid(data) %Assign parameters
                app.Model=cThermoeconomicModel(data);
                app.DataModelEditField.BackgroundColor=[0.95 1 0.95];
                app.SaveButton.Enable=true;
                app.SaveResultsMenu.Enable=true;
                app.SaveDataModelMenu.Enable=true;
                app.SaveModelMenu.Enable=true;
				stateNames=app.Model.StateNames;
                app.OperationStateDropDown.Enable=true;
                app.OperationStateDropDown.Items=stateNames;
                app.ReferenceStateDropDown.Enable=true;
                app.ReferenceStateDropDown.Items=stateNames;
                if data.NrOfStates>1
                    app.SummaryCheckBox.Enable=true;
                end
                if data.isResourceCost
					sampleNames=app.Model.SampleNames;
                    app.ResourceCostDropDown.Items=sampleNames;
                    app.ResourceCostDropDown.Enable=true;
                    app.CostTablesDropDown.Enable=true;
                    app.CostTablesDropDown.Value=cType.DEFAULT_COST_TABLES;
                end
                dnames=cType.DiagnosisOptions;
                if data.isWaste
                    wf=app.Model.WasteFlows;
					app.DiagnosisMethodDropDown.Items=dnames;
            		app.DiagnosisMethodDropDown.Value=cType.DEFAULT_DIAGNOSIS;
                    app.ActiveWasteDropDown.Items=wf;
                    app.ActiveWasteDropDown.Enable=true;
                    app.RecyclingCheckBox.Enable=true;
                else
				    app.DiagnosisMethodDropDown.Items=dnames(1:2);
            		app.DiagnosisMethodDropDown.Value=cType.DEFAULT_DIAGNOSIS;
                end
                logtext=' INFO: Valid Data Model';
                app.EnableResults(cType.ResultId.PRODUCTIVE_STRUCTURE);
                app.EnableResults(cType.ResultId.THERMOECONOMIC_STATE);
                app.EnableResults(cType.ResultId.THERMOECONOMIC_ANALYSIS);
                app.EnableResults(cType.ResultId.WASTE_ANALYSIS);
                app.EnableResults(cType.ResultId.PRODUCTIVE_DIAGRAM);
                app.EnableResults(cType.ResultId.DIAGRAM_FP);
                app.EnableResults(cType.ResultId.DATA_MODEL);           
                app.EnableResults(cType.ResultId.RESULT_MODEL);
                app.ViewModelResults
            else
                app.DataModelEditField.BackgroundColor=[1 0.5 0.5];
				logtext=' ERROR: Invalid Data Model';
                uialert(app.UIFigure,logtext,'Warning');
            end
            app.LogField.Text=logtext;

        end

        % Menu selected function: SaveModelMenu
        function SaveModel(app, event)
        % Save the model in the workspace
            if ~isdeployed
                assignin('base', 'model', app.Model);
                app.LogField.Text='INFO: Model saved on workspace';
            end
        end

        % Callback function: SaveButton, SaveResultsMenu
        function SaveResults(app, event)
            % Save the model results
            res=app.CurrentNode;
            default_file=strcat(cType.RESULT_FILE,cType.FileExt.XLSX);
			[file,path,ext]=uiputfile({'*.xlsx','XLSX Files';'*.txt','TXT Files'; ...
                '*.csv','CSV Files';'*.html','HTML Files';'*.tex','LaTeX Files'},'Select File',default_file);
            if ext % File has been selected
                cd(path)
				filename=fullfile(path,file);
                log=saveResults(res,file);
                if isvalid(log)
				    app.ResultFile=filename;
                    app.OutputFileEditField.Value=file;
                    logtext=sprintf('INFO: %s saved in file %s',res.ResultName,file);
                else
                    logtext=sprintf('WARNING: Results %s have NOT saved',res.ResultName);
                end
		    else
				logtext=sprintf('WARNING: Results %s are NOT Available',res.ResultName);
            end
            app.LogField.Text=logtext;
        end

        % Menu selected function: SaveDataModelMenu
        function SaveDataModel(app, event)
            % Save the Data Model
            default_file=strcat(app.Model.ModelName,cType.FileExt.MAT);
            [file,path,ext]=uiputfile({'*.mat','MAT Files';'*.xlsx','XLSX Files';'*.txt','TXT Files'; ...
                '*.csv','CSV Files'},'Select File',default_file);
            if ext % File has been selected
                cd(path);
                log=saveDataModel(app.Model,file);
                if isValid(log)
			        logtext=sprintf('INFO: Data Model Available in file %s',file);
                else
                    logtext=sprintf('WARNING: Data Model is NOT saved. See Log');
                end
            else
				logtext=sprintf('WARNING: Data Model is NOT Available');
            end
            app.LogField.Text=logtext;
        end

        % Callback function: CloseMenu, UIFigure
        function CloseApp(app, event)
            selection = uiconfirm(app.UIFigure,'Close the Application?',...
                'Confirmation');   
            switch selection
                case 'OK'
                    delete(app)                      
                case 'Cancel'
                    return
            end
        end

        % Value changed function: OperationStateDropDown
        function getOperationState(app, event)
            % Select Operation State
            app.Model.State = app.OperationStateDropDown.Value;
            app.DiagnosisMethodDropDown.Enable=app.Model.isDiagnosis;
            if app.Model.isDiagnosis
                app.EnableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            else
                app.DisableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            end
            app.ViewModelResults;
        end

        % Value changed function: ReferenceStateDropDown
        function getReferenceState(app, event)
            % Select Reference State
            app.Model.ReferenceState=app.ReferenceStateDropDown.Value;
            app.DiagnosisMethodDropDown.Enable=app.Model.isDiagnosis;
            if app.Model.isDiagnosis
                app.EnableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.Model.thermoeconomicDiagnosis);
            else
                app.DisableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
            end
        end

        % Value changed function: CostTablesDropDown
        function getCostTables(app, event)
            % Select CostTable property 
            app.Model.CostTables = app.CostTablesDropDown.Value;
            app.ViewIndexTable(app.Model.thermoeconomicAnalysis);
        end

        % Value changed function: ResourceCostDropDown
        function getResourcesSample(app, event)
            % Select Resource Sample
            app.Model.ResourceSample = app.ResourceCostDropDown.Value;
            app.ViewIndexTable(app.Model.thermoeconomicAnalysis);
        end

        % Value changed function: DiagnosisMethodDropDown
        function getDiagnosisMethod(app, event)
            % Select DiagnosisMethod property
            app.Model.DiagnosisMethod = app.DiagnosisMethodDropDown.Value;
            if app.Model.isDiagnosis
                app.EnableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewIndexTable(app.Model.thermoeconomicDiagnosis);
            else
                app.DisableResults(cType.ResultId.THERMOECONOMIC_DIAGNOSIS);
                app.ViewModelResults
            end
        end

        % Value changed function: ActiveWasteDropDown
        function getWasteFlow(app, event)
            app.Model.ActiveWaste = app.ActiveWasteDropDown.Value;
            app.ViewIndexTable(app.Model.wasteAnalysis);
        end

        % Value changed function: RecyclingCheckBox
        function RecyclingValueChanged(app, event)
            value = app.RecyclingCheckBox.Value;
            app.Model.Recycling=value;
            app.ViewIndexTable(app.Model.wasteAnalysis);
        end

        % Value changed function: SummaryCheckBox
        function SummaryValueChanged(app, event)
            % Activate Summary Results
            value = app.SummaryCheckBox.Value;
            app.Model.Summary=value;
            if value
                app.EnableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewIndexTable(app.Model.summaryResults);
            else
                app.DisableResults(cType.ResultId.SUMMARY_RESULTS);
                app.ViewModelResults;
            end
        end

        % Menu selected function: AboutMenu
        function AboutMenuSelected(app, event)
            web('https://www.exergoecology.com');
        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            if isempty(app.CurrentNode)
                return
            end
            selection = app.UITable.Selection;
            idx=selection(1);
            sg=(selection(2)==cType.GRAPH_COLUMN);
            tbl=app.TableIndex.Content{idx};
            showTable(tbl,app.ViewOption);
            if tbl.isGraph && sg
                graph=app.TableIndex.RowNames{idx};
                showGraph(app.CurrentNode,graph);
            end
        end

        % Value changed function: ViewTableDropDown
        function getTableViewOption(app, event)
            value = app.ViewTableDropDown.Value;
            app.ViewOption=cType.getTableView(value);
            display(app.ViewOption)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 831 623];
            app.UIFigure.Name = 'TAES App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @CloseApp, true);

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = '  File ';

            % Create OpenMenu
            app.OpenMenu = uimenu(app.FileMenu);
            app.OpenMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadData, true);
            app.OpenMenu.Text = 'Open';

            % Create SaveMenu
            app.SaveMenu = uimenu(app.FileMenu);
            app.SaveMenu.Text = 'Save';

            % Create SaveResultsMenu
            app.SaveResultsMenu = uimenu(app.SaveMenu);
            app.SaveResultsMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveResults, true);
            app.SaveResultsMenu.Tooltip = {'Save  currently state results '};
            app.SaveResultsMenu.Enable = 'off';
            app.SaveResultsMenu.Text = 'Results';

            % Create SaveDataModelMenu
            app.SaveDataModelMenu = uimenu(app.SaveMenu);
            app.SaveDataModelMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveDataModel, true);
            app.SaveDataModelMenu.Tooltip = {'Save data model, in other format.'};
            app.SaveDataModelMenu.Enable = 'off';
            app.SaveDataModelMenu.Text = 'Data Model';

            % Create SaveModelMenu
            app.SaveModelMenu = uimenu(app.SaveMenu);
            app.SaveModelMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveModel, true);
            app.SaveModelMenu.Tooltip = {'Save Model in Workspace'};
            app.SaveModelMenu.Enable = 'off';
            app.SaveModelMenu.Text = 'Model';

            % Create CloseMenu
            app.CloseMenu = uimenu(app.FileMenu);
            app.CloseMenu.MenuSelectedFcn = createCallbackFcn(app, @CloseApp, true);
            app.CloseMenu.Text = 'Close';

            % Create ResultsMenu
            app.ResultsMenu = uimenu(app.UIFigure);
            app.ResultsMenu.Text = 'Results';

            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
            app.HelpMenu.Text = ' Help';

            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.MenuSelectedFcn = createCallbackFcn(app, @AboutMenuSelected, true);
            app.AboutMenu.Text = 'About';

            % Create Toolbar
            app.Toolbar = uitoolbar(app.UIFigure);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {300, 500};
            app.GridLayout.RowHeight = {'1x', 22};
            app.GridLayout.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create InputParametersPanel
            app.InputParametersPanel = uipanel(app.GridLayout);
            app.InputParametersPanel.Title = 'Input Parameters';
            app.InputParametersPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.InputParametersPanel.Layout.Row = 1;
            app.InputParametersPanel.Layout.Column = 1;
            app.InputParametersPanel.FontAngle = 'italic';

            % Create InputGridLayout
            app.InputGridLayout = uigridlayout(app.InputParametersPanel);
            app.InputGridLayout.ColumnWidth = {105, '1x', 100};
            app.InputGridLayout.RowHeight = {22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, '1x', 22};
            app.InputGridLayout.RowSpacing = 18;
            app.InputGridLayout.Padding = [10 18 10 18];
            app.InputGridLayout.BackgroundColor = [1 1 1];

            % Create SaveButton
            app.SaveButton = uibutton(app.InputGridLayout, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveResults, true);
            app.SaveButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.SaveButton.Enable = 'off';
            app.SaveButton.Tooltip = {'Select the results file name'};
            app.SaveButton.Layout.Row = 13;
            app.SaveButton.Layout.Column = 3;
            app.SaveButton.Text = 'Save Results';

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.InputGridLayout, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadData, true);
            app.LoadDataButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.LoadDataButton.Tooltip = {'Select the data model file'};
            app.LoadDataButton.Layout.Row = 13;
            app.LoadDataButton.Layout.Column = 1;
            app.LoadDataButton.Text = 'Load Data';

            % Create ViewTableDropDown
            app.ViewTableDropDown = uidropdown(app.InputGridLayout);
            app.ViewTableDropDown.Items = {'CONSOLE', 'GUI', 'HTML'};
            app.ViewTableDropDown.ValueChangedFcn = createCallbackFcn(app, @getTableViewOption, true);
            app.ViewTableDropDown.Enable = 'off';
            app.ViewTableDropDown.Tooltip = {'Select the tables to show'};
            app.ViewTableDropDown.BackgroundColor = [1 1 1];
            app.ViewTableDropDown.Layout.Row = 11;
            app.ViewTableDropDown.Layout.Column = [2 3];
            app.ViewTableDropDown.Value = 'CONSOLE';

            % Create OutputFileEditField
            app.OutputFileEditField = uieditfield(app.InputGridLayout, 'text');
            app.OutputFileEditField.Editable = 'off';
            app.OutputFileEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.OutputFileEditField.Tooltip = {'Show the file name to save the results'};
            app.OutputFileEditField.Layout.Row = 10;
            app.OutputFileEditField.Layout.Column = [2 3];
            app.OutputFileEditField.Value = 'ModelResults.xlsx';

            % Create ResultsFileLabel
            app.ResultsFileLabel = uilabel(app.InputGridLayout);
            app.ResultsFileLabel.Layout.Row = 10;
            app.ResultsFileLabel.Layout.Column = 1;
            app.ResultsFileLabel.Text = 'Results File:';

            % Create SummaryCheckBox
            app.SummaryCheckBox = uicheckbox(app.InputGridLayout);
            app.SummaryCheckBox.ValueChangedFcn = createCallbackFcn(app, @SummaryValueChanged, true);
            app.SummaryCheckBox.Enable = 'off';
            app.SummaryCheckBox.Tooltip = {'Activate Summary Results'};
            app.SummaryCheckBox.Text = '';
            app.SummaryCheckBox.Layout.Row = 9;
            app.SummaryCheckBox.Layout.Column = 2;

            % Create SummaryResultsLabel
            app.SummaryResultsLabel = uilabel(app.InputGridLayout);
            app.SummaryResultsLabel.Layout.Row = 9;
            app.SummaryResultsLabel.Layout.Column = 1;
            app.SummaryResultsLabel.Text = 'Summary Results:';

            % Create RecyclingCheckBox
            app.RecyclingCheckBox = uicheckbox(app.InputGridLayout);
            app.RecyclingCheckBox.ValueChangedFcn = createCallbackFcn(app, @RecyclingValueChanged, true);
            app.RecyclingCheckBox.Enable = 'off';
            app.RecyclingCheckBox.Tooltip = {'Activate recycling analysis'};
            app.RecyclingCheckBox.Text = '';
            app.RecyclingCheckBox.Layout.Row = 8;
            app.RecyclingCheckBox.Layout.Column = 2;

            % Create RecyclingAnalysisLabel
            app.RecyclingAnalysisLabel = uilabel(app.InputGridLayout);
            app.RecyclingAnalysisLabel.Layout.Row = 8;
            app.RecyclingAnalysisLabel.Layout.Column = 1;
            app.RecyclingAnalysisLabel.Text = 'Recycling Analysis:';

            % Create ActiveWasteDropDown
            app.ActiveWasteDropDown = uidropdown(app.InputGridLayout);
            app.ActiveWasteDropDown.Items = {'NONE'};
            app.ActiveWasteDropDown.ValueChangedFcn = createCallbackFcn(app, @getWasteFlow, true);
            app.ActiveWasteDropDown.Enable = 'off';
            app.ActiveWasteDropDown.Tooltip = {'Select the active flow for recycling analysis'};
            app.ActiveWasteDropDown.Layout.Row = 7;
            app.ActiveWasteDropDown.Layout.Column = [2 3];
            app.ActiveWasteDropDown.Value = 'NONE';

            % Create ActiveWasteDropDownLabel
            app.ActiveWasteDropDownLabel = uilabel(app.InputGridLayout);
            app.ActiveWasteDropDownLabel.Layout.Row = 7;
            app.ActiveWasteDropDownLabel.Layout.Column = 1;
            app.ActiveWasteDropDownLabel.Text = 'Active Waste:';

            % Create DataModelEditFieldLabel
            app.DataModelEditFieldLabel = uilabel(app.InputGridLayout);
            app.DataModelEditFieldLabel.Layout.Row = 1;
            app.DataModelEditFieldLabel.Layout.Column = 1;
            app.DataModelEditFieldLabel.Text = 'Data Model:';

            % Create DataModelEditField
            app.DataModelEditField = uieditfield(app.InputGridLayout, 'text');
            app.DataModelEditField.Editable = 'off';
            app.DataModelEditField.BackgroundColor = [1 0.502 0.502];
            app.DataModelEditField.Tooltip = {'Show the data model file'};
            app.DataModelEditField.Layout.Row = 1;
            app.DataModelEditField.Layout.Column = [2 3];
            app.DataModelEditField.Value = 'No Model Available';

            % Create OperationStateDropDownLabel
            app.OperationStateDropDownLabel = uilabel(app.InputGridLayout);
            app.OperationStateDropDownLabel.Layout.Row = 3;
            app.OperationStateDropDownLabel.Layout.Column = 1;
            app.OperationStateDropDownLabel.Text = 'Operation State:';

            % Create OperationStateDropDown
            app.OperationStateDropDown = uidropdown(app.InputGridLayout);
            app.OperationStateDropDown.Items = {'Reference', 'Operation'};
            app.OperationStateDropDown.ValueChangedFcn = createCallbackFcn(app, @getOperationState, true);
            app.OperationStateDropDown.Enable = 'off';
            app.OperationStateDropDown.Tooltip = {'Select the operation state'};
            app.OperationStateDropDown.BackgroundColor = [1 1 1];
            app.OperationStateDropDown.Layout.Row = 3;
            app.OperationStateDropDown.Layout.Column = [2 3];
            app.OperationStateDropDown.Value = 'Reference';

            % Create ResourceCostDropDownLabel
            app.ResourceCostDropDownLabel = uilabel(app.InputGridLayout);
            app.ResourceCostDropDownLabel.Layout.Row = 4;
            app.ResourceCostDropDownLabel.Layout.Column = 1;
            app.ResourceCostDropDownLabel.Text = 'Resource Cost:';

            % Create ResourceCostDropDown
            app.ResourceCostDropDown = uidropdown(app.InputGridLayout);
            app.ResourceCostDropDown.Items = {'Base'};
            app.ResourceCostDropDown.ValueChangedFcn = createCallbackFcn(app, @getResourcesSample, true);
            app.ResourceCostDropDown.Enable = 'off';
            app.ResourceCostDropDown.Tooltip = {'Select the resources cost sample'};
            app.ResourceCostDropDown.BackgroundColor = [1 1 1];
            app.ResourceCostDropDown.Layout.Row = 4;
            app.ResourceCostDropDown.Layout.Column = [2 3];
            app.ResourceCostDropDown.Value = 'Base';

            % Create CostTablesDropDownLabel
            app.CostTablesDropDownLabel = uilabel(app.InputGridLayout);
            app.CostTablesDropDownLabel.Layout.Row = 5;
            app.CostTablesDropDownLabel.Layout.Column = 1;
            app.CostTablesDropDownLabel.Text = 'Cost Tables:';

            % Create CostTablesDropDown
            app.CostTablesDropDown = uidropdown(app.InputGridLayout);
            app.CostTablesDropDown.Items = {'DIRECT'};
            app.CostTablesDropDown.ValueChangedFcn = createCallbackFcn(app, @getCostTables, true);
            app.CostTablesDropDown.Enable = 'off';
            app.CostTablesDropDown.Tooltip = {'Select the tables to show'};
            app.CostTablesDropDown.BackgroundColor = [1 1 1];
            app.CostTablesDropDown.Layout.Row = 5;
            app.CostTablesDropDown.Layout.Column = [2 3];
            app.CostTablesDropDown.Value = 'DIRECT';

            % Create DiagnosisMethodDropDownLabel
            app.DiagnosisMethodDropDownLabel = uilabel(app.InputGridLayout);
            app.DiagnosisMethodDropDownLabel.Layout.Row = 6;
            app.DiagnosisMethodDropDownLabel.Layout.Column = 1;
            app.DiagnosisMethodDropDownLabel.Text = 'Diagnosis Method:';

            % Create DiagnosisMethodDropDown
            app.DiagnosisMethodDropDown = uidropdown(app.InputGridLayout);
            app.DiagnosisMethodDropDown.Items = {'NONE'};
            app.DiagnosisMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @getDiagnosisMethod, true);
            app.DiagnosisMethodDropDown.Enable = 'off';
            app.DiagnosisMethodDropDown.Tooltip = {'Select the diagnosis method to use'};
            app.DiagnosisMethodDropDown.BackgroundColor = [1 1 1];
            app.DiagnosisMethodDropDown.Layout.Row = 6;
            app.DiagnosisMethodDropDown.Layout.Column = [2 3];
            app.DiagnosisMethodDropDown.Value = 'NONE';

            % Create ReferenceStateDropDownLabel
            app.ReferenceStateDropDownLabel = uilabel(app.InputGridLayout);
            app.ReferenceStateDropDownLabel.Layout.Row = 2;
            app.ReferenceStateDropDownLabel.Layout.Column = 1;
            app.ReferenceStateDropDownLabel.Text = 'Reference State:';

            % Create ReferenceStateDropDown
            app.ReferenceStateDropDown = uidropdown(app.InputGridLayout);
            app.ReferenceStateDropDown.Items = {'Reference'};
            app.ReferenceStateDropDown.ValueChangedFcn = createCallbackFcn(app, @getReferenceState, true);
            app.ReferenceStateDropDown.Enable = 'off';
            app.ReferenceStateDropDown.Tooltip = {'Select Reference State'};
            app.ReferenceStateDropDown.Layout.Row = 2;
            app.ReferenceStateDropDown.Layout.Column = [2 3];
            app.ReferenceStateDropDown.Value = 'Reference';

            % Create ViewTableDropDownLabel
            app.ViewTableDropDownLabel = uilabel(app.InputGridLayout);
            app.ViewTableDropDownLabel.Layout.Row = 11;
            app.ViewTableDropDownLabel.Layout.Column = 1;
            app.ViewTableDropDownLabel.Text = 'View Table:';

            % Create TableIndexPanel
            app.TableIndexPanel = uipanel(app.GridLayout);
            app.TableIndexPanel.Title = 'Table Index';
            app.TableIndexPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TableIndexPanel.Layout.Row = 1;
            app.TableIndexPanel.Layout.Column = 2;
            app.TableIndexPanel.FontAngle = 'italic';

            % Create UITable
            app.UITable = uitable(app.TableIndexPanel);
            app.UITable.ColumnName = {'Table'; 'Description'; 'Graph'};
            app.UITable.RowName = {};
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Position = [0 0 500 550];

            % Create LogPanel
            app.LogPanel = uipanel(app.GridLayout);
            app.LogPanel.BackgroundColor = [0.8 0.8 0.8];
            app.LogPanel.Layout.Row = 2;
            app.LogPanel.Layout.Column = [1 2];

            % Create Hyperlink
            app.Hyperlink = uihyperlink(app.LogPanel);
            app.Hyperlink.URL = 'https://www.exergoecology.com';
            app.Hyperlink.Position = [664 1 146 22];
            app.Hyperlink.Text = 'www.exergocology.com';

            % Create LogField
            app.LogField = uilabel(app.LogPanel);
            app.LogField.Position = [5 1 650 20];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = TaesTool_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end