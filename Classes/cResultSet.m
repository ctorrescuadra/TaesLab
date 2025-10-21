classdef(Abstract) cResultSet < cResultId
%cResultSet - Abstract class to manage the result sets.
%   The results classes are cResultInfo, cDataModel and cThermoeconomicModel
%   It provide methods to:
%   - Show the results in console
%   - Show the results in workspace
%   - Show the results in graphic user interfaces
%   - Save the results in files: XLSX, CSV, TXT LaTeX and HTML
%
%   cResultSet properties:
%     ClassId - Result Set Id
%       cType.ClassId.RESULT_INFO
%       cType.ClassId.DATA_MODEL
%       cTtpe.ClassId.RESULT_MODEL
% 
%   cResultSet methods:
%     StudyCase        - Get the study case value names
%     ListOfTables     - Get the table names from a result set
%     LIstOfGraphs     - Get the graphic table names from a result set
%     getTableIndex    - Get the table index from a result set
%     printResults     - Print results on console
%     showResults      - Show results in different interfaces
%     showGraph        - Show the graph associated to a table
%     showTableIndex   - Show the table index in different interfaces
%     exportResults    - Export all the result Tables to another format
%     saveResults      - Save all the result tables in an external file
%     getTable         - Get a table of the result set by name
%     saveTable        - Save the results in an external file 
%     exportTable      - Export a table to another format
%
%   See also cResultId, cResultInfo, cThermoeconomicModel, cDataModel
%
    properties(GetAccess=public,SetAccess=protected)
        ClassId  % Class Id (see cType.ClassId)
    end

    methods
        function res=StudyCase(obj)
        %StudyCase - Get/display the study case names
        %   If output argument is not provided names are shown on console
        %
        %   Syntax:
        %     obj.StudyCase;
        %     res=obj.StudyCase
        %   Output Arguments:
        %     res - struct with the current state and sample names
        %
                res=struct('State',obj.State,'Sample',obj.Sample);
                if nargout==0
                    disp(res);
                end
        end

        function res=ListOfTables(obj)
        %ListOfTables - Get the list of tables as cell array
        %   Syntax:
        %     obj.ListOfTables
        %   Output Arguments:
        %     res - cell array with the table names
        %
            res=cType.EMPTY_CELL;
            tmp=getResultInfo(obj);
            if tmp.status
                res=fieldnames(tmp.Tables);
            end
        end

        function res=ListOfGraphs(obj)
        %ListOfGraphs - Get the list of graph tables as cell array
        %   Syntax:
        %     obj.ListOfTables
        %   Output Arguments:
        %     res - cell array with the graph table names
        %
            res=cType.EMPTY_CELL;
            tmp=getResultInfo(obj);
            if ~tmp.status
                return
            end
            tbls=struct2cell(tmp.Tables);
            idx=cellfun(@(x) isGraph(x),tbls);
            if any(idx)
                res=cellfun(@(x) x.Name,tbls(idx),'UniformOutput',false);
            end
        end

        function res=getTableIndex(obj,varargin)
        %getTableIndex - Get the table index of the results set
        %   Syntax:
        %     res=getTableIndex(obj,options)
        %   Input Arguments:
        %     options - VarMode options
        %       cType.VarMode.NONE: cTable object
        %       cType.VarMode.CELL: cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarModel.TABLE: Matlab table
        %   Output Arguments:
        %     res - Table Index info in the format selected
        %
            tmp=getResultInfo(obj);
            res=getTableIndex(tmp,varargin{:});
        end

        function printResults(obj)
        %printResults - print the result tables on console
        %   Syntax:
        %     obj.printResults
        %
            tidx=getTableIndex(obj);
            cellfun(@(x) printTable(x),tidx.Content);
        end

        function showResults(obj,name,varargin)
        %showResults - View an individual table
        %   If no parameters are provided print the result tables on console.
        %
        %   Syntax:
        %     obj.showResults(table,option)
        %   Input Arguments:
        %     name - Name of the table
        %     option - Table view option
        %       cType.TableView.CONSOLE 
        %       cType.TableView.GUI
        %       cType.TableView.HTML (default)
        %
            if nargin==1
                printResults(obj);
                return
            end
            tbl=obj.getTable(name);
            if tbl.status
                showTable(tbl,varargin{:});
            else
                tbl.printLogger;
            end
        end

        function showTableIndex(obj,varargin)
        %showTableIndex - View the index table of the results set
        %   Syntax:
        %     obj.showTableIndex(option)
        %   Input Arguments:
        %     option - Table view option
        %      cType.TableView.CONSOLE (default)
        %      cType.TableView.GUI
        %      cType.TableView.HTML
        %   
            tbl=getTableIndex(obj);
            if tbl.status
                tbl.showTable(varargin{:});
            else
                obj.printWarning(cMessages.InvalidTableIndex);
            end
        end

        function res=exportResults(obj,varmode,fmt)
        %exportResults - Export result tables into a structure using diferent formats.
        %   Syntax:
        %     res=obj.exportResults(varmode,fmt)
        %   Input Arguments:
        %     varmode - result type (optional)
        %      cType.VarMode.NONE: cTable object
        %      cType.VarMode.CELL: cell array
        %      cType.VarMode.STRUCT: structured array
        %      cType.VarModel.TABLE: Matlab table
        %     fmt - Format values (false/true)
        % Output Arguments:
        %   res - structure with the tables in the required format
        %
            tmp=getResultInfo(obj);
            switch nargin
            case 1
                res=tmp.Tables;
                return
            case 2
                fmt=false;
            end
            names=obj.ListOfTables;
            tables=cellfun(@(x) exportTable(tmp.Tables.(x),varmode,fmt),names,'UniformOutput',false);
            res=cell2struct(tables,names,1);
        end

        function log=saveResults(obj,filename)
        %saveResults - Save result tables in different file formats depending on file extension
        %   Accepted extensions: xlsx, csv, html, txt, tex
        %
        %   Syntax:
        %     log=obj.saveResults(filename)
        %   Input Arguments:
        %     filename - File name. Extensión is used to determine the save mode.
        %   Output Arguments:
        %     log - cMessageLogger object with error messages
        %
            log=cMessageLogger();
            if (nargin < 2) || ~isFilename(filename)
                log.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            if ~obj.status
                log.messageLog(cType.ERROR,cMessages.InvalidResultInfo)
                return
            end
            [fileType,ext]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    log=obj.saveAsCSV(filename);
                case cType.FileType.XLSX
                    log=obj.saveAsXLS(filename);
                case cType.FileType.HTML
                    log=obj.saveAsHTML(filename);
                case cType.FileType.TXT
                    log=obj.saveAsTXT(filename);
                case cType.FileType.LaTeX
                    log=obj.saveAsLaTeX(filename);
                case cType.FileType.MD
                    log=exportMarkdown(obj,filename);
                case cType.FileType.MAT
                    log=exportMAT(obj,filename);
                otherwise
                    log.messageLog(cType.ERROR,cMessages.InvalidFileExt,ext);
                    return
            end
            if log.status
                log.messageLog(cType.INFO,cMessages.InfoFileSaved,obj.ResultName,filename);
            end
        end

        function res=getTable(obj,name)
        %getTable - Get the table called name
        %   Syntax:
        %     res=obj.getTable(name)
        %   Input Arguments:
        %     name - Name of the table
        %   Output Arguments:
        %     res - cTable object
        %
            res=cMessageLogger();
            if (nargin < 2) || ~ischar(name) || isempty(name)
                res.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            tmp=getResultInfo(obj);
            res=getTable(tmp,name);
        end
    
        function log=saveTable(obj,tname,filename)
        %saveTable - Save a result table into a file depending on extension
        %   Valid extension depends of the result set
        %
        %   Syntax:
        %     obj.saveTable(tname, filename)
        %   Input Arguments:
        %     tname - name of the table
        %     filename - name of the file with extension
        %   Output Arguments:
        %     log - cMessageLogger, with the status of the action and error messages
        %
            log=cMessageLogger();
            if nargin < 3
                log.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            tbl=obj.getTable(tname);
            if tbl.status
                log=saveTable(tbl,filename);
            else
                log.messageLog(cType.ERROR,cMessages.TableNotFound,tname);
            end
        end
    
        function res=exportTable(obj,tname,varargin)
        %exportTable - Export tname into the selected varmode/format
        %   Syntax:
        %     obj.exportTable(tname,options)
        %   Input Arguments:
        %     tname - name of the table
        %     options - optional parameters
        %       varmode - result type
        %        cType.VarMode.NONE: cTable object (default)
        %        cType.VarMode.CELL: cell array
        %        cType.VarMode.STRUCT: structured array
        %        cType.VarModel.TABLE: Matlab table
        %       fmt - Format values (false/true)
        %   Output Arguments:
        %     res - the result table in the selected format
        %
            res=cMessageLogger();
            if nargin < 2
                res.messageLog(cType.ERROR,cMessages.InvalidArgument)
                return
            end
            tbl=obj.getTable(tname);
            if tbl.status
                res=exportTable(tbl,varargin{:});
            else
                res.messageLog(cType.ERROR,cMessages.TableNotFound,tname);
            end
        end
    end

    methods(Access=protected)
        function log=saveAsCSV(obj,filename)
        %saveAsCSV - Save result tables as CSV files, each table in a file
        %   Create a folder with all the tables and a file called "<filename>.csv" with the folder name
        %
        %   Syntax:
        %     log=obj.saveAsCSV(filename)
        %   Input Arguments:
        %     filename - Name of the file where the csv file information is stored
        %   Output Arguments:
        %     log - cMessageLogget object with error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Check Input
            if tidx.NrOfRows<1
                log.messageLog(cType.ERROR,cMessages.NoTableToSave);
                return
            end
            % Check Folder and print info file
            [~,name,ext]=fileparts(filename);
            folder=strcat('.',filesep,name,'_csv');
            %Write the info directory
            try
                fid = fopen(filename, 'wt');
                fprintf (fid, '%s', folder);
                fclose (fid);
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                return
            end
            if ~exist(folder,'dir')
                mkdir(folder);
            end
            % Save Index file
            fname=strcat(folder,filesep,'index',ext);
            slog=exportCSV(tidx.Values,fname);
            if ~slog.status
                log.addLogger(slog);
                log.messageLog(cType.ERROR,cMessages.IndexTableNotSave);
            end
            % Save each table in a file
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                fname=strcat(folder,filesep,tbl.Name,ext);
                slog=exportCSV(tbl.Values,fname);
                if ~slog.status
                    log.addLogger(slog);
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,fname);
                end
            end
        end
        
        function log=saveAsXLS(obj,filename)
        %saveAsXLS - Save the result tables in a Excel file, each table in a worksheet.
        %   Syntax:
        %     log=obj.saveASXLS(filename)
        %   Input Arguments:
        %     filename - name of the worksheet file
        %   Output Arguments:
        %     log - cMessageLogger object with error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Check Input
            if tidx.NrOfRows<1
                log.messageLog(cType.ERROR,cMessages.NoTableToSave);
                return
            end
            % Open file
            if isOctave
                try
                    fId=xlsopen(filename,1);
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                    return
                end
            else
                fId=filename;
            end
            % Save table index sheet
            if isOctave
                [fId,status]=oct2xls(tidx.Values,fId,'Index');
                if ~status || isempty(fId)
                    log.messageLog(cType.ERROR,cMessages.IndexTableNotSave);
                    return
                end
            else
                try
                    writecell(tidx.Values,fId,'Sheet','Index');
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,cMessages.IndexTableNotSave);
                    return
                end
            end
            % Save tables
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                if isOctave
                    [fId,status]=oct2xls(tbl.Values,fId,tbl.Name);
                    if ~status || isempty(fId)
                        log.messageLog(cType.ERROR,cMessages.TableNotSaved,tbl.Name);
                    end
                else
                    try
                        writecell(tbl.Values,fId,'Sheet',tbl.Name);
                    catch err
                        log.messageLog(cType.ERROR,err.message);
                        log.messageLog(cType.ERROR,cMessages.TableNotSaved,tbl.Name);
                    end
                end
            end
            if isOctave
                fId=xlsclose(fId);
                if ~isempty(fId)
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                end
            end
        end
                
        function log=saveAsHTML(obj,filename)
        %saveAsHTML - Save result tables as HTML files.
        %	Create a index file and a folder containing all the table files
        %
        %   Syntax:
        %     log=obj.saveAsHTML(filename)
        %   Input Arguments:
        %     filename - Name of the index file
        %   Output Arguments:
        %     log - cMessageLogger object with error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
                % Check Input
            if tidx.NrOfRows<1
                log.messageLog(cType.ERROR,cMessages.NoTableToSave);
                return
            end
            % Get folder name and create it.
            [~,name,ext]=fileparts(filename);
            folder=strcat('.',filesep,name,'_html');
            if ~exist(folder,'dir')
                mkdir(folder);
            end
            % Create html index page
            html=cBuildHTML(tidx,folder);
            log=html.saveTable(filename);
            % Save each table in a file
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                fname=strcat(folder,filesep,tbl.Name,ext);
                html=cBuildHTML(tbl);
                slog=html.saveTable(fname);
                if ~slog.status
                    log.addLogger(slog);
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,fname);
                end
            end
        end
        
        function log=saveAsTXT(obj,filename)
        %saveAsTXT - Save the result tables if a formatted text file
        %   Syntax:
        %     log=saveAsTXT(filename)
        %   Input Arguments:
        %     filename - name of the worksheet file
        %   Output Arguments:
        %     log - cMessageLogger object with save status and error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Open text file
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                return
            end
            % Print tables into file
            cellfun(@(x) printTable(x,fId),tidx.Content);
            fclose(fId);
        end
        
        function log=saveAsLaTeX(obj,filename)
        %saveAsLaTeX - Save the tables into a file in LaTeX format
        %   Syntax:
        %     log=saveAsLaTeX(filename)
        %   Input Arguments:
        %     filename - name of the file
        %   Output Arguments:
        %     log - cMessageLogger object with save status and error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Open text file
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                return
            end
            % Save the tables in the file
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                ltx=cBuildLaTeX(tbl);
                fprintf(fId,'%s',ltx.getLaTeXcode);
            end
            fclose(fId);
        end

        function log=exportMarkdown(obj,filename)
        %exportMarkdown - Export the result tables into a Markdown file
        %   Syntax:
        %     log=exportMarkdown(filename)
        %   Input Arguments:
        %     filename - name of the file
        %   Output Arguments:
        %     log - cMessageLogger object with save status and error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Open text file
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                return
            end
            % Save the tables in the file
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                md=cBuildMarkdown(tbl);
                fprintf(fId,'%s',md.getMarkdownCode);
            end
            fclose(fId);
        end
    end
end