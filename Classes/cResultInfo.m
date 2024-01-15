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
%       res=obj.getListOfTables;
%       res=obj.getTable(name)
%       obj.printTable(name)
%       obj.viewTable(name);
%       res=getTableIndex
%       obj.viewTableIndex;
%       obj.printResults;
%       log=obj.saveResults(filename)
%       res=obj.getResultTables(varmode,fmt)
%       obj.summaryDiagnosis
%       obj.showGraph(name,options) 
% See: cResultTableBuilder, cTable
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
        tableIndex   % cTableIndex object with tables information
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
            if isValid(tbl)
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
        % Get the Table Index
            res=obj.tableIndex;
        end
        
        function viewTableIndex(obj,varargin)
        % Print the index table in console
            tbl=obj.tableIndex;
            tbl.viewTable(varargin{:});
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
        %       res - Struct with the result tables in the selected format
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