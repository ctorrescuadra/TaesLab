classdef cModelTables < cStatusLogger
    % cModelTable is a class container of the cTable objects
    %   It stores the tables of the data model and application results
    %   the class provide methos to save and analize the results tables
    %   Methods:  
    %       obj.setProperties(model,state)
    %       obj.isResultTable
    %       obj.existTable(tbl)
    %       obj.getTable(tbl)
    %       obj.getTableValues(tbl)
    %       obj.getListOfTables
    %       obj.getIndexTable
    %       obj.printIndexTable
    %       obj.printResults
    %       obj.saveResults(filename)
    %       obj.getResultTables(var,fmt)
    %
    properties (GetAccess=public, SetAccess=protected)
        Id           % Id of the table container or resultId
        Name         % Name of the container
        Tables       % Struct containing the tables
        NrOfTables   % Number of tables
        ModelName    % Model Name
        State        % State Name
    end

    properties (Access=protected)
        tableIndex   % cell array of tables
    end

    methods
        function obj = cModelTables(tableId,tables)
        % Construct an instance of this class
        %  Input:
        %   tableId - Id of the table (see cType)
        %   tables - struct containig the tables
            obj.Tables=tables;
            obj.tableIndex=struct2cell(tables);
            obj.NrOfTables=numel(obj.tableIndex);
            obj.State='';
            obj.ModelName='';
            obj.setResultId(tableId);
            obj.status=cType.VALID;
        end

        function setProperties(obj,model,state)
        % set model and state values
            obj.ModelName=model;
            if nargin==3
                obj.State=state;
            end
        end

        function setResultId(obj,id)
            obj.Id=id;
            obj.Name=cType.Results{id};
        end

        function status=isResultTable(obj)
        % Determine if the tables are results
            status=(obj.Id~=cType.ResultId.DATA_MODEL);
        end
        
        function status=existTable(obj,name)
        % Check if there is a table called name
            status=isfield(obj.Tables,name);
        end

        function res = getTable(obj,name)
        % Get the table called name
            res = cStatusLogger;
            if obj.existTable(name)
                res=obj.Tables.(name);
            end
        end

        function printTable(obj,name)
        % Print an individual table
        %   Input:
        %       name - Name of the table
            res=obj.getTable(name);
            if isValid(res)
                res.printFormatted;
            else
                obj.printError('Table %s do NOT exists',name);
            end
        end

        function viewTable(obj,name)
        % view an individual table as a GUI Table
        %   Input:
        %       name - Name of the table
            res=obj.getTable(name);
            if isValid(res)
                res.viewTable(obj.State);
            else
                obj.printError('Table %s do NOT exists',name);
            end
        end

        function res=getListOfTables(obj)
        % Get the list of tables as cell array
            res=fieldnames(obj.Tables);
        end

        function res=getTableValues(obj,name)
        % Get the values of the table called name as cell array
            res={};
            tbl=getTable(obj,name);
            if tbl.isValid
                res=tbl.Values;
            end
        end

        function res=getIndexTable(obj)
            % Get a cTableData object with the tables and descripcion
                N=obj.NrOfTables+1;
                data=cell(obj.NrOfTables+1,2);
                data(1,:)={'Key','Description'};
                tnames=fieldnames(obj.Tables);
                data(2:end,1)=tnames;
                for i=2:N
                    data{i,2}=obj.Tables.(data{i,1}).Description;
                end
                res=cTableData(data);
            end
    
            function printIndexTable(obj)
            % Print the index table in console
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
            if ~obj.isResultTable
                return
            end
            cellfun(@(x) printFormatted(x),obj.tableIndex);
        end

        function log=saveResults(obj,filename)
        % Save result tables in different file formats depending on file extension
        % Input:
        %   filename - File name. Extensión is used to determine the save mode.
        % Output:
        %   log - cStatusLog object with save status and error messages
            log=cStatusLogger(cType.VALID);
            if ~cType.checkFileWrite(filename)
                message=sprintf('Invalid file name: %s',filename);
                log.messageLog(cType.ERROR,message);
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
                message=sprintf('File extension %s is not supported',filename);
                log.messageLog(cType.ERROR,message);
                return
            end
            log.addLogger(slog);
            if log.isValid
                message=sprintf('%s available in file %s',obj.Name,filename);
                log.messageLog(cType.INFO,message);
            end
        end
        
        function res=getResultTables(obj,mode,fmt)
        % Get the result tables in different format mode
        %  Input:
        %   mode - Select the output object: CELL, STRUCT or TABLE.
        %   fmt  - (true/false) Applied defined format
        %  Output
        %   res - Result tables in the selected format
        %
            narginchk(2,3);
            if (nargin==2) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            switch mode
            case cType.VarMode.CELL
                res=obj.getResultAsCell(fmt);
            case cType.VarMode.STRUCT
                res=obj.getResultAsStruct(fmt);
            case cType.VarMode.TABLE
                res=obj.getResultAsTable;
            otherwise
                obj.printWarning('VarMode undefined');
            end
        end
        
        function log=saveAsCSV(obj,filename)
        % Save result tables as CSV files, each table in a file
        %  Input:
        %   filename - Name of the file where the csv file information is stored
        %  Output:
        %   log - cStatusLog object with save status and error messages
            log=cStatusLogger(cType.VALID);
            % Check Input
            list=fieldnames(obj.Tables);
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
                message=sprintf('Writting file info %s',filename);
                log.messageLog(cType.ERROR,message);
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
                fname=strcat(folder,filesep,list{i},ext);
                slog=tbl.exportCSV(fname);
                if ~slog.isValid
                    log.addLogger(slog);
                    message=sprintf('file %s is NOT saved',fname);
                    log.messageLog(cType.ERROR,message);
                end
            end
        end
            
        function log=saveAsXLS(obj,filename)
        % Save the result tables in a Excel file, each table in a worksheet.
        %  Input:
        %   filename - name of the worksheet file
        %  Output:
        %   log - cStatusLog object with save status and error messages
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
                [fId,status]=oct2xls(tidx.Data,fId,'Index');
                if ~status || isempty(fId)
                    log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
                end
            else
                try
                    writecell(tidx.Values,fId,'Sheet','Index');
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,'Index Sheet is NOT saved');
                end
            end

            for i=1:obj.NrOfTables
                data=obj.tableIndex{i}.Values;
                sheet=list{i};
                if isOctave
                    [fId,status]=oct2xls(data,fId,sheet);
                    if ~status || isempty(fId)
                        log.messageLog(cType.ERROR,'Sheet %s is NOT saved',sheet);
                    end
                else
                    try
                        writecell(data,fId,'Sheet',sheet);
                    catch err
                        log.messageLog(cType.ERROR,err.message);
                        log.messageLog(cType.ERROR,'Sheet %s is NOT saved',sheet);
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
        %  Input:
        %   filename - name of the worksheet file
        %  Output:
        %   log - cStatusLog object with save status and error messages
            log=cStatusLogger(cType.VALID);
            % Open text file
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message)
                message=sprintf('Open file %s',filename);
                log.messageLog(cType.ERROR,message);
                return
            end
            % Print tables into file
            cellfun(@(x) printFormatted(x,fId),obj.tableIndex);
            fclose(fId);
        end
    end
    methods(Access=protected)
        function res=getResultAsCell(obj,fmt)
        % Converts Result Tables into cell arrays to display on the variable editor
        % Input:
        %   fmt - (true/false) indicate is the values are formated or not
        % Output:
        %   res - Struct of cell arrays with the result tables values
            res=struct();
            if (nargin==1) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            list=fieldnames(obj.Tables);
            for i=1:length(list)
                res.(list{i})=getFormattedCell(obj.tableIndex{i},fmt);
            end
        end

        function res=getResultAsStruct(obj,fmt)
        % Converts tables result values into arrays of structs, to display on the variable editor
        % Input:
        %   fmt - (true/false) indicate is the values are formated or not
        % Output:
        %   res - Struct of struct arrays with the result tables values
            res=struct();
            if (nargin==1) || ~isa(fmt,'logical') || ~obj.isResultTable
                fmt=false;
            end
            list=fieldnames(obj.Tables);
            for i=1:length(list)
                res.(list{i})=getFormattedStruct(obj.tableIndex{i},fmt);
            end
        end

        function res=getResultAsTable(obj)
        % Get the tables. In case of matlab it is converted to Matlab tables.
        % Output:
        %   res - Struct of tables/matlab tables with the result tables values
        %
            if isMatlab
                res=struct();
                list=fieldnames(obj.Tables);
                for i=1:length(list)
                    res.(list{i})=getMatlabTable(obj.tableIndex{i});
                end
            else
                res=obj;
            end
        end
    end
end