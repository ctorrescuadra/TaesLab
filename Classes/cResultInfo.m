classdef cResultInfo < cStatusLogger
% cResultInfo is a class container of the application results
% It stores the tables and the application class info.
% It provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV, TXT and HTML
%   The diferent types (ResultId) of cResultInfo object are defined in cType.ResultId 
%   Methods:
%       obj.getTable(table)
%       obj.printTable(table)
%       obj.viewTable(table);
%       obj.printResults;
%       res=getTableIndex
%       obj.printTableIndex;
%       log=obj.saveResults(filename)
%       res=obj.getResultTables(varmode,fmt)
%       obj.summaryDiagnosis
%       obj.graphCost(table)
%       obj.graphDiagnosis(table, option)
%       obj.graphSummary(table, option)
%       obj.graphRecycling(table)
%       obj.graphWasteAllocation(waste);
%       obj.showDiagramFP;
%       obj.showFlowsDiagram;
%       obj.showGraph(table,options) 
% See: cResultTableBuilder, cTableResult
%
    properties (GetAccess=public, SetAccess=private)
        ResultId     % Result Id 
        ResultName   % Result name
        Tables       % Struct containing the tables
        NrOfTables   % Number of tables
        Info         % cResultId object containing the results
        ModelName    % Model Name
        State        % State Name
    end

    properties (Access=private)
        tableIndex   % cell array of tables
    end

    methods
        function obj=cResultInfo(info,tables)
        % Construct an instance of this class
        %  Usage: 
        %   cResultInfo(info,tables)
        %  Input:
        %   info - cResultId containing the results
        %   tables - struct containig the result tables
        %
            % Check parameters
            if ~isa(info,'cResultId')
                obj.messageLog(cType.ERROR,'Invalid ResultId object');
                return
            end
            if ~isstruct(tables)
                obj.messageLog(cType.ERROR,'Invalid tables parameter');
                return
            end
            % Fill the class values
            obj.Info=info;
            obj.setResultId(info.ResultId)
            obj.Tables=tables;
            obj.tableIndex=cTableIndex(obj);
            obj.NrOfTables=obj.tableIndex.NrOfRows;
            obj.ModelName='';
            obj.State='';
            obj.status=info.status;
        end

        function setResultId(obj,id)
        % Set ResultId
            obj.ResultId=id;
            obj.ResultName=cType.Results{id};
        end
        
        function setProperties(obj,model,state)
        % Set model and state properties
            obj.ModelName=model;
            cellfun(@(x) setState(x,state),obj.tableIndex.Content);
            obj.State=state;
        end

        function status=isResultTable(obj)
        % Determine if the tables are results
            status=(obj.ResultId~=cType.ResultId.DATA_MODEL);
        end
            
        function status=existTable(obj,name)
        % Check if there is a table called name
            status=isfield(obj.Tables,name);
        end
    
        function res=getListOfTables(obj)
        % Get the list of tables as cell array
            res=fieldnames(obj.Tables);
        end
    
        function res = getTable(obj,name)
        % Get the table called name
        %   Usage: 
        %       res=obj.getTable(name)
        %   Input:
        %       name - Name of the table
        %   Output:
        %       res - cTable object 
            res = cStatusLogger;
            if obj.existTable(name)
                res=obj.Tables.(name);
            else
                res.printError('Table name %s does NOT exists',name);
            end
        end

        function printTable(obj,name)
        % Print an individual table
        %   Usage:
        %       obj.printTable(table)
        %   Input:
        %       name - Name of the table
            log=cStatus(cType.VALID);
            tbl=obj.getTable(name);
            if isValid(tbl) && isResultTable(obj)
                tbl.printTable;
            else
                log.printError('Table name %s does NOT exists',name);
            end
        end
    
        function viewTable(obj,name,varargin)
        % View an individual table as a GUI Table
        %   Usage:
        %       obj.viewTable(table,option)
        %   Input:
        %       name - Name of the table
        %       option - Way to display the table
        %           cType.TableView.GUI (default)
        %           cType.TableView.HTML
        %
            log=cStatus(cType.VALID);
            tbl=obj.getTable(name);
            if isValid(tbl)
                viewTable(tbl,varargin{:});
            else
                log.printError('Table name %s does NOT exists',name);
            end
        end

        function res=getTableIndex(obj)
            res=obj.tableIndex;
        end
        
        function printTableIndex(obj)
        % Print the index table in console
            tbl=obj.tableIndex;
            tbl.printTable;
        end
    
        function printResults(obj)
        % Print the formated tables on console
            log=cStatus();
            if ~isValid(obj)
                log.printError('Invalid object to print')
                return
            end
            cellfun(@(x) printTable(x),obj.tableIndex.Content);
        end

        function log=saveResults(obj,filename)
        % Save result tables in different file formats depending on file extension
        %   Usage:
        %       log=obj.saveResults(filename)
        %   Input:
        %       filename - File name. Extensión is used to determine the save mode.
        %   Output:
        %       log - cStatusLogger object with error messages
            log=cStatusLogger(cType.VALID);
            if ~isValid(obj) 
                log.messageLog(cType.ERROR,'Invalid cResultInfo object')
                return
            end
            if ~cType.checkFileWrite(filename)
                log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
                return
            end
            [fileType,ext]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    slog=obj.saveAsCSV(filename);
                case cType.FileType.XLSX
                    slog=obj.saveAsXLS(filename);
                case cType.FileType.HTML
                    slog=obj.saveAsHTML(filename);
                case cType.FileType.TXT
                    slog=obj.saveAsTXT(filename);
            otherwise
                log.messageLog(cType.ERROR,'File extension %s is not supported',ext);
                return
            end
            log.addLogger(slog);
			if isValid(log)
				log.messageLog(cType.INFO,'File %s has been saved',filename);
			end
        end

        function log=saveAsCSV(obj,filename)
        % Save result tables as CSV files, each table in a file
        %   Usage:
        %       log=obj.saveAsCSV(filename)
        %   Input:
        %       filename - Name of the file where the csv file information is stored
        %   Output:
        %       log - cStatusLog object with error messages
            log=cStatusLogger(cType.VALID);
            % Check Input
            if obj.tableIndex.NrOfRows<1
                log.messageLog(cType.ERROR,'No tables to save');
                return
            end
            % Check Folder and print info file
            [~,name,ext]=fileparts(filename);
            folder=strcat('.',filesep,name,'_csv');
            % Write the info directory
            try
                fid = fopen(filename, 'wt');
                fprintf (fid, '%s', folder);
                fclose (fid);
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog('Writting file info %s',filename);
                return
            end
            if ~exist(folder,'dir')
                mkdir(folder);
            end
            % Save Index file
            tidx=obj.tableIndex;
            fname=strcat(folder,filesep,'index',ext);
            slog=tidx.exportCSV(fname);
            if ~slog.isValid
                log.addLogger(slog);
                log.messageLog(cType.ERROR,'Index file is NOT saved');
            end
            % Save each table in a file
            for i=1:obj.NrOfTables
                tbl=obj.tableIndex.Content{i};
                fname=strcat(folder,filesep,tbl.Name,ext);
                slog=tbl.exportCSV(fname);
                if ~slog.isValid
                    log.addLogger(slog);
                    log.messageLog(cType.ERROR,'file %s is NOT saved',fname);
                end
            end
        end
            
        function log=saveAsXLS(obj,filename)
        % Save the result tables in a Excel file, each table in a worksheet.
        %   Usage:
        %       log=obj.saveASXLS(filename)
        %  Input:
        %       filename - name of the worksheet file
        %  Output:
        %       log - cStatusLog object with error messages
            log=cStatusLogger(cType.VALID);
            % Check Input     
            if obj.tableIndex.NrOfRows<1
                log.messageLog(cType.ERROR,'No tables to save');
                return
            end
            if isOctave
                try
                    fId=xlsopen(filename,1);
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,'Error open file %s',filename);
                    return
                end
            else
                fId=filename;
            end
            tidx=obj.tableIndex;
            if isOctave
                [fId,status]=oct2xls(tidx.Values,fId,'Index');
                if ~status || isempty(fId)
                    log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
                    return
                end
            else
                try
                    writecell(tidx.Values,fId,'Sheet','Index');
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
                    return
                end
            end
            for i=1:obj.NrOfTables
                tbl=obj.tableIndex.Content{i};              
                if isOctave
                    [fId,status]=oct2xls(tbl.Values,fId,tbl.Name);
                    if ~status || isempty(fId)
                        log.messageLog(cType.ERROR,'Sheet %s is NOT saved',tbl.Name);
                    end
                else
                    try
                        writecell(tbl.Values,fId,'Sheet',tbl.Name);
                    catch err
                        log.messageLog(cType.ERROR,err.message);
                        log.messageLog(cType.ERROR,'Sheet %s is NOT saved',tbl.Name);
                    end
                end
            end
            if isOctave
                fId=xlsclose(fId);
                if ~isempty(fId)
                    log.messageLog(cType.ERROR,'Result file %s is NOT saved',filename);
                end
            end
        end

        function log=saveAsHTML(obj,filename)
        % Save result tables as CSV files, each table in a file
        %   Usage:
        %       log=obj.saveAsCSV(filename)
        %   Input:
        %       filename - Name of the file where the csv file information is stored
        %   Output:
        %       log - cStatusLog object with error messages
            log=cStatusLogger(cType.VALID);
            % Check Input
            if obj.tableIndex.NrOfRows<1
                log.messageLog(cType.ERROR,'No tables to save');
                return
            end
            % Get folder name and create it.
            [~,name,ext]=fileparts(filename);
            folder=strcat('.',filesep,name,'_html');
            if ~exist(folder,'dir')
                mkdir(folder);
            end
            % Create html index page
            html=cBuildHTML(obj.tableIndex,folder);
            log=html.saveTable(filename);
            % Save each table in a file
            for i=1:obj.NrOfTables
                tbl=obj.tableIndex.Content{i};
                fname=strcat(folder,filesep,tbl.Name,ext);
                html=cBuildHTML(tbl);
                slog=html.saveTable(fname);
                if ~slog.isValid
                    log.addLogger(slog);
                    log.messageLog(cType.ERROR,'file %s is NOT saved',fname);
                end
            end
        end

        function log=saveAsTXT(obj,filename)
        % Save the result tables if a formatted text file
        %   Usage:
        %       log=saveAsTXT(filename)
        %   Input:
        %       filename - name of the worksheet file
        %   Output:
        %       log - cStatusLog object with save status and error messages
            log=cStatusLogger(cType.VALID);
            % Open text file
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,'Open file %s',filename);
                return
            end
            % Print tables into file
            cellfun(@(x) printTable(x,fId),obj.tableIndex.Content);
            fclose(fId);
        end

        function res=getResultTables(obj,varmode,fmt)
        % Get the result tables in different format mode
        %   Usage: 
        %       res = obj.getResultTables(mode, fmt)
        %   Input:
        %       mode - Select the output object. The valid values are:
        %           cType.VarMode.NONE: Return a struct with the cTable objects
	    %           cType.VarMode.CELL: Return a struct with cell values
	    %           cType.VarMode.STRUCT: Return a struct with structured array values
	    %           cType.VarModel.TABLE: Return a struct of Matlab tables
        %       fmt  - true/false value, indicating if the table format is applied to the output. By default the value is false.
        %   Output
        %       res - Result tables in the selected format
            narginchk(2,3);
            if (nargin==2) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            names=obj.getListOfTables;
            tables=cellfun(@(x) exportTable(obj,x,varmode,fmt),names,'UniformOutput',false);
            res=cell2struct(tables,names,1);            
        end

        function res=getFuelImpact(obj)
        % get the Fuel Impact as a string including format and unit
            res='WARNING: Fuel Impact NOT Available';
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.dit.Format;
                unit=obj.Tables.dit.Unit;
                tfmt=['Fuel Impact:',format,' ',unit];
                res=sprintf(tfmt,obj.Info.FuelImpact);
            end
        end

        function summaryDiagnosis(obj)
        % Show diagnosis summary results
            if isValid(obj) && obj.ResultId==cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                format=obj.Tables.mfc.Format;
                unit=obj.Tables.mfc.Unit;
                tfmt=['Fuel Impact:',format,' ',unit,'\n'];
                fprintf(tfmt,obj.Info.FuelImpact);
                tfmt=['Malfunction Cost:',format,' ',unit,'\n'];
                fprintf(tfmt,obj.Info.TotalMalfunctionCost);
            end
        end

        function fuelImpact(obj)
        % Print the fuel impact of the actual diagnosis state
            fprintf('%s\n',obj.getFuelImpact);
        end

        function graphCost(obj,graph)
        % Shows a barplot with the irreversibilty cost table values for a given state 
        %   Usage:
        %       obj.graphCost(graph)
        %   Input:   
        %       graph - (optional) table name to plot
        %           cType.Tables.PROCESS_COST (dict)
        %           cType.Tables.PROCESS_GENERALIZED_COST (gict)
        %           cType.Tables.FLOW_COST (dfict)
        %           cType.Tables.FLOW_GENERALIZED_COST (gfict)
        %       If graph is not selected first option is taken
        % See also cGraphResults
            % Check input
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return                
            end
            if (obj.ResultId~=cType.ResultId.THERMOECONOMIC_ANALYSIS) && ...
                (obj.ResultId~=cType.ResultId.EXERGY_COST_CALCULATOR)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end  
            if nargin==1
                graph=cType.Tables.PROCESS_ICT;
            end
            % Get Result Table info and build graph
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                showGraph(tbl);
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end
        
        function graphDiagnosis(obj,graph,shout)
        % Shows a barplot of diagnosis table values for a given state 
        %   Usage:
        %       obj.graphDiagnosis(graph)
        %   Input:
        %       graph - table name to plot
        %           cType.Graph.MALFUNCTION (mf)
        %           cType.Graph.MALFUNCTION_COST (mfc)
        %           cType.Graph.IRREVERSIBILITY (dit)
        %       If graph is not selected first option is taken
        %       shout - Show output info bar.
        % See also cGraphResults
        %
            % Check input arguments
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return                
            end
            if obj.ResultId~=cType.ResultId.THERMOECONOMIC_DIAGNOSIS
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end  
            if nargin==1
                graph=cType.Tables.MALFUNCTION_COST;
                shout=true;
            end
            if nargin==2
                shout=true;
            end
            if obj.Info.Method==cType.DiagnosisMethod.WASTE_EXTERNAL
                shout=true;
            end
            % Get Result Table info and build graph
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                showGraph(tbl,shout);
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end

        function graphSummary(obj,graph,var)
        % Plot summary tables.
        %   Input:
        %       graph - (optional) type of graph to plot
        %           cType.SummaryTables.UNIT_CONSUMPTION (pku)
        %           cType.SummaryTables.PROCESS_DIRECT_UNIT_COST (dpuc)
        %           cType.SummaryTables.FLOW_UNIT_COST (dfuc)
        %           cType.SummaryTables.PROCESS_GENERALIZED_UNIT_COST (gpuc)
        %           cType.SummaryTables.FLOW_GENERALIZED_UNIT_COST (gfuc)
        %       var - (optional) Cell Array indicating the keys of the variables to plot
        %       If var is not selected only the output flows are show if apply.
        % See also cGraphResults
        %
            % Check input arguments
            log=cStatus(cType.VALID);
            if ~isValid(obj)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return                
            end
            if obj.ResultId ~= cType.ResultId.SUMMARY_RESULTS
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end
            if nargin==1
                graph=cType.SummaryTables.FLOW_UNIT_COST;
                var=obj.Info.getDefaultFlowVariables;
            end
            tbl=obj.getTable(graph);
            if ~isValid(tbl) || ~isGraph(tbl)
                log.printError('Invalid graph type: %s',graph);
                return
            end
            if (nargin==2) || isempty(var)            
                if tbl.isFlowsTable
                    var=obj.Info.getDefaultFlowVariables;
                else
                    var=obj.Info.getDefaultProcessVariables;
                end
            end
            % Plot the table
            showGraph(tbl,var);
        end

        function graphRecycling(obj,graph)
        % Shows the recycling graph
        %   Usage:
        %       obj.graphRecycling(obj)
        %   Input:
        %       graph - (optional) name of the table to plot
        %           cType.Graph.WASTE_RECYCLING_DIRECT (rag)
        %           cType.Graph.WASTE_RECYCLING_GENERALIZED (rag)
        % See also cGraphResults
        %
            % Check Input
            log=cStatus(cType.VALID);
            if obj.ResultId~=cType.ResultId.WASTE_ANALYSIS
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end
            if ~isValid(obj)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return                
            end
            if nargin==1 || isempty(graph)
                graph=cType.Tables.WASTE_RECYCLING_DIRECT;
            end
            % get result table and plot the graph
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                showGraph(tbl);
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end

        function graphWasteAllocation(obj,varargin)
        % Shows a pie chart of the waste allocation table
        %   Usage:
        %       obj.graphWasteAllocation(wkey)
        %   Input:
        %       wkey - (optional) waste key key.
        %       If not selected first waste is taken.
        % See also cGraphResults
        %
            log=cStatus(cType.VALID);
  
            if obj.ResultId==cType.ResultId.WASTE_ANALYSIS || ...
                obj.ResultId==cType.ResultId.EXERGY_COST_CALCULATOR
                tbl=obj.Tables.wa;
            else
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end
            if ~isValid(obj)
                log.printError('Invalid cResultInfo object %s',obj.ResultName);
                return
            end   
            showGraph(tbl,varargin{:});
        end

        function showDiagramFP(obj,graph)
        % Show the FP table digraph [only Matlab]
        %   Usage:
        %       obj.showDiagramFP;
        % See also cGraphResults
        %
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented in Octave');
                return
            end
            if nargin==1
                switch obj.ResultId
                case cType.ResultId.DIAGRAM_FP
                    graph=cType.Tables.DIAGRAM_FP;
                case cType.ResultId.THERMOECONOMIC_STATE
                    graph=cType.Tables.TABLE_FP;
                case cType.ResultId.THERMOECONOMIC_ANALYSIS
                    graph=cType.Tables.COST_TABLE_FP;
                otherwise
                    log.printError('Invalid cResultInfo object %s',obj.ResultName);
                    return
                end
            end
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                showGraph(tbl);
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end

        function showProductiveDiagram(obj,graph)
        % Show the flows diagram of the productive structure [Only Matlab]
        %   Usage:
        %       obj.showFlowsDiagram;
        % See also cGraphResults, cTableResults
        %
            log=cStatus(cType.VALID);
            if isOctave
                log.printError('Function not implemented in Octave');
                return
            end
            if nargin==1
                graph=cType.Tables.FLOWS_DIAGRAM;
            end
            tbl=obj.getTable(graph);
            if isValid(tbl) && isGraph(tbl)
                option=obj.Info.getNodeTable(graph);
                showGraph(tbl,option);
            else
                log.printError('Invalid graph type: %s',graph);
                return
            end
        end

        function showGraph(obj,graph,varargin)
        % Show graph with options
        %   Usage:
        %       obj.showGraph(graph, options)
        %   Input:
        %       graph - graph table name
        %       varagin - graph options
        % See also cGraphResults, cTableResults
            log=cStatus(cType.VALID);
            option=[];
            if nargin==1
                graph=obj.Info.DefaultGraph;
            end
	        tbl=getTable(obj,graph);
	        if ~isValid(tbl)
		        log.printError('Invalid graph table: %s',graph);
		        return
	        end
	        % Get default optional parameters
            if isempty(varargin)
                switch tbl.GraphType
		            case cType.GraphType.DIAGNOSIS
			            option=true;
		            case cType.GraphType.WASTE_ALLOCATION
				        option=obj.Info.wasteFlow;
                    case cType.GraphType.DIGRAPH
                        option=obj.Info.getNodeTable(graph);
		            case cType.GraphType.SUMMARY
                        if tbl.isFlowsTable
					        option=obj.Info.getDefaultFlowVariables;
				        else
					        option=obj.Info.getDefaultProcessVariables;
                        end
                end
            else
                option=varargin{:};
            end
	        % Show Graph
	        showGraph(tbl,option);
        end
    end

    methods(Access=private)
        function res=exportTable(obj,name,varmode,fmt)
        % Export a table using diferent formats. Internal use.
            res=[];
            if nargin==3
                fmt=false;
            end
            tbl=obj.getTable(name);
            if isValid(tbl)
                res=tbl.exportTable(varmode,fmt);
            end
        end
    end
end