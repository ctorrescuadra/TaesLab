classdef cModelTables < cResultId
    % cModelTable is a class container of the cTable objects
    %   It stores the tables of the data model and application results
    %   Methods:  
    %       tbj=obj.getTable(tbl)
    %       obj.printTable(tbl)
    %       obj.viewTable(tbl)
    %       obj.printIndexTable
    %       obj.printResults
    %       obj.saveResults(filename)
    %       obj.getResultTables(var,fmt)
    %
    properties (GetAccess=public, SetAccess=protected)
        Tables       % Struct containing the tables
        NrOfTables   % Number of tables
        ModelName    % Model Name
        State        % State Name
    end

    properties (Access=protected)
        tableIndex   % cell array of tables
    end

    methods
        function obj = cModelTables(Id,tables)
        % Construct an instance of this class
        %   Usage: cModelTables(tableId, tables)
        %  Input:
        %   Id - ResultId of the table group (see cType)
        %   tables - struct containig the tables
            obj=obj@cResultId(Id);
            obj.Tables=tables;
            obj.tableIndex=struct2cell(tables);
            obj.NrOfTables=numel(obj.tableIndex);
            obj.State='';
            obj.ModelName='';
            obj.status=cType.VALID;
        end

        function setProperties(obj,model,state)
        % Set model and state values
            obj.ModelName=model;
            if nargin==3
                obj.State=state;
            end
        end

        function setResultId(obj,id)
        % Set ResultId
            obj.ResultId=id;
            obj.ResultName=cType.Results{id};
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
        %       res - cTableResult object 
            res = cStatusLogger;
            if obj.existTable(name)
                res=obj.Tables.(name);
            end
        end

        function printTable(obj,name)
        % Print an individual table
        %   Usage:
        %       obj.printTable(table)
        %   Input:
        %       name - Name of the table
            log=cStatus(cType.VALID);
            res=obj.getTable(name);
            if isValid(res)
                res.printTable;
            else
                log.printError('Table %s do NOT exists',name);
            end
        end

        function viewTable(obj,name)
        % View an individual table as a GUI Table
        %   Usage:
        %       obj.viewTable(table)
        %   Input:
        %       name - Name of the table
            log=cStatus(cType.VALID);
            res=obj.getTable(name);
            if isValid(res)
                res.viewTable;
            else
                log.printError('Table %s do NOT exists',name);
            end
        end

        function res=getIndexTable(obj)
        % Get a cTableData object with the table names and descripcion
            colNames={'Key','Description'};
            tnames=obj.getListOfTables;
            data=cellfun(@(x) obj.Tables.(x).Description,tnames,'UniformOutput',false);
            %for i=1:N
            %    data{i}=obj.Tables.(tnames{i}).Description;
            %end
            res=cTableData(data,tnames',colNames);
        end
    
        function printIndexTable(obj)
        % Print the index table in console
        %   Usage:
        %       obj.printIndexTable
            tbl=obj.getIndexTable;
            len1=max(cellfun(@length,tbl.RowNames))+1;
            len2=max(cellfun(@length,tbl.Data(:,1)))+1;
            hfmt=['%-',num2str(len1),'s %-',num2str(len2),'s\n'];
            lines=repmat('-',1,len1+len2+2);
            fprintf('\n')
            fprintf(hfmt,tbl.ColNames{:});
            fprintf('%s\n',lines);
            for i=1:tbl.NrOfRows
                fprintf(hfmt,tbl.RowNames{i},tbl.Data{i,1});
            end
            fprintf('\n');
        end

        function printResults(obj)
        % Print the formated tables on console
        %   Usage:
        %       obj.printResults
            log=cStatus();
            if ~isValid(obj) || ~obj.isResultTable
                log.printError('Invalid object to print')
                return
            end
            cellfun(@(x) printTable(x),obj.tableIndex);
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
                log.messageLog(cType.ERROR,'Invalid object to save')
                return
            end
            if ~cType.checkFileWrite(filename)
                log.messageLog(cType.ERROR,'Invalid file name: %s',filename);
                return
            end
            fileType=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    slog=obj.saveAsCSV(filename);
                case cType.FileType.XLSX
                    slog=obj.saveAsXLS(filename);
                case cType.FileType.TXT
                    slog=obj.saveAsTXT(filename);
            otherwise
                log.messageLog(cType.ERROR,'File extension %s is not supported',filename);
                return
            end
            log.addLogger(slog);
			if isValid(log)
				log.messageLog(cType.INFO,'File %s has been saved',filename);
			end
        end
        
        function res=getResultTables(obj,mode,fmt)
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
            res=cStatusLogger;
            if (nargin==2) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            switch mode
            case cType.VarMode.NONE
                res=obj;
            case cType.VarMode.CELL
                res=obj.getResultAsCell(fmt);
            case cType.VarMode.STRUCT
                res=obj.getResultAsStruct(fmt);
            case cType.VarMode.TABLE
                res=obj.getResultAsTable;
            otherwise
                res.printWarning('VarMode undefined');
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
            list=obj.getListOfTables;
            if numel(list)<1
                log.messageLog(cType.ERROR,'No tables to save');
                return
            end
            % Check Folder and print info file
            [~,name,ext]=fileparts(filename);
            folder=strcat('.',filesep,name,'_csv');
            % Write the info directory
            try
                fid = fopen (filename, 'wt');
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
            tidx=obj.getIndexTable;
            fname=strcat(folder,filesep,'index',ext);
            slog=tidx.exportCSV(fname);
            if ~slog.isValid
                log.addLogger(slog);
                log.messageLog(cType.ERROR,'Index file is NOT saved');
            end
            % Save each table in a file
            for i=1:obj.NrOfTables
                tbl=obj.tableIndex{i};
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
            list=obj.getListOfTables;
            if numel(list)<1
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
            tidx=obj.getIndexTable;
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
                tbl=obj.tableIndex{i};              
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
            cellfun(@(x) printTable(x,fId),obj.tableIndex);
            fclose(fId);
        end
    end

    methods(Access=protected)
        function res=getResultAsCell(obj,fmt)
        % Converts Result Tables into cell arrays to display on the variable editor
            res=struct();
            if (nargin==1) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            list=obj.getListOfTables;
            for i=1:length(list)
                res.(list{i})=getFormattedCell(obj.tableIndex{i},fmt);
            end
        end

        function res=getResultAsStruct(obj,fmt)
        % Converts tables result values into arrays of structs, to display on the variable editor
            res=struct();
            if (nargin==1) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            list=obj.getListOfTables;
            for i=1:length(list)
                res.(list{i})=getFormattedStruct(obj.tableIndex{i},fmt);
            end
        end

        function res=getResultAsTable(obj)
        % Get the tables. In case of matlab it is converted to Matlab tables.
            if isMatlab
                res=struct();
                list=obj.getListOfTables;
                for i=1:length(list)
                    res.(list{i})=getMatlabTable(obj.tableIndex{i});
                end
            else
                res=obj.Tables;
            end
        end
    end
end