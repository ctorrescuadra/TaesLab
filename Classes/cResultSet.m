classdef(Abstract) cResultSet < cResultId
%cResultSet - Abstract class that provides the unified interface for all result containers.
%   Concrete subclasses are cResultInfo, cDataModel, and cThermoeconomicModel.
%   The class provides methods to:
%     - Print result tables to the console
%     - Display result tables in the workspace, a GUI, or an HTML view
%     - Show graphs associated with result tables
%     - Export result tables to MATLAB structures, cell arrays, or table objects
%     - Save result tables to files: XLSX, CSV, TXT, LaTeX, HTML, Markdown, or MAT
%
%   cResultSet Properties:
%     ClassId - Result set class identifier (see cType.ClassId)
%       cType.ClassId.RESULT_INFO  - Analysis result produced by a computation module
%       cType.ClassId.DATA_MODEL   - Data model read from an input file
%       cType.ClassId.RESULT_MODEL - Configured thermoeconomic analysis model
%
%   cResultSet Methods:
%     StudyCase        - Get the current state and sample names
%     ListOfTables     - Get the names of all available tables
%     ListOfGraphs     - Get the names of all graph-capable tables
%     getTableIndex    - Get the table index in the selected format
%     printResults     - Print all result tables on the console
%     showResults      - Display a named table in the selected view
%     showGraph        - Show the graph associated with a table
%     showTableIndex   - Display the table index in the selected view
%     exportResults    - Export all result tables to a MATLAB variable
%     saveResults      - Save all result tables to an external file
%     getTable         - Retrieve a named cTable object from the result set
%     saveTable        - Save a single named table to an external file
%     exportTable      - Export a single named table to a MATLAB variable
%
%   See also cResultId, cResultInfo, cThermoeconomicModel, cDataModel
%
    properties(GetAccess=public,SetAccess=protected)
        ClassId  % Result set class identifier (see cType.ClassId)
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
        %ListOfTables - Get the names of all available tables in the result set
        %   Syntax:
        %     res = obj.ListOfTables
        %   Output Arguments:
        %     res - cell array of character vectors with the table names
        %
            res=cType.EMPTY_CELL;
            tmp=getResultInfo(obj);
            if tmp.status
                res=fieldnames(tmp.Tables);
            end
        end

        function res=ListOfGraphs(obj)
        %ListOfGraphs - Get the names of all graph-capable tables in the result set
        %   Syntax:
        %     res = obj.ListOfGraphs
        %   Output Arguments:
        %     res - cell array of character vectors with the graph table names
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
        %getTableIndex - Get the index table listing all tables in the result set
        %   When called without a varmode argument the returned cTableIndex contains
        %   the cTable objects; otherwise the index is converted to the requested format.
        %
        %   Syntax:
        %     res = obj.getTableIndex
        %     res = obj.getTableIndex(varmode)
        %   Input Arguments:
        %     varmode - Output format (optional)
        %       cType.VarMode.NONE:   cTableIndex object (default)
        %       cType.VarMode.CELL:   cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarMode.TABLE:  MATLAB table
        %   Output Arguments:
        %     res - Table index in the requested format
        %
            tmp=getResultInfo(obj);
            res=getTableIndex(tmp,varargin{:});
        end

        function printResults(obj)
        %printResults - Print the result tables on console
        %   Syntax:
        %     obj.printResults
        %
            tidx=getTableIndex(obj);
            cellfun(@(x) printTable(x),tidx.Content);
        end

        function showResults(obj,name,varargin)
        %showResults - Display a named table or print all tables to the console
        %   When called without arguments all tables are printed on the console.
        %   When a table name is provided, the table is shown in the selected view.
        %
        %   Syntax:
        %     obj.showResults
        %     obj.showResults(name)
        %     obj.showResults(name, view)
        %   Input Arguments:
        %     name - Name of the table to display (character vector)
        %     view - Output view (optional)
        %       cType.TableView.CONSOLE - Print formatted text to the command window
        %       cType.TableView.GUI     - Open in interactive table viewer
        %       cType.TableView.HTML    - Render as HTML page (default)
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
        %showTableIndex - Display the index table listing all available result tables
        %   Syntax:
        %     obj.showTableIndex
        %     obj.showTableIndex(view)
        %   Input Arguments:
        %     view - Output view (optional)
        %       cType.TableView.CONSOLE - Print formatted text to the command window (default)
        %       cType.TableView.GUI     - Open in interactive table viewer
        %       cType.TableView.HTML    - Render as HTML page
        %   
            tbl=getTableIndex(obj);
            if tbl.status
                tbl.showTable(varargin{:});
            else
                obj.printWarning(cMessages.InvalidTableIndex);
            end
        end

        function res=exportResults(obj,varmode,fmt)
        %exportResults - Export all result tables into a MATLAB structure using different formats.
        %   When called without arguments the raw Tables struct (containing cTable objects)
        %   is returned directly. Otherwise each table is converted to the requested format.
        %
        %   Syntax:
        %     res = obj.exportResults
        %     res = obj.exportResults(varmode)
        %     res = obj.exportResults(varmode, fmt)
        %   Input Arguments:
        %     varmode - Output format for each table (optional)
        %       cType.VarMode.NONE:   cTable object (default, also used when nargin==1)
        %       cType.VarMode.CELL:   cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarMode.TABLE:  MATLAB table
        %     fmt - Logical flag to apply column format strings to values (default: false)
        %   Output Arguments:
        %     res - Struct whose fields are the exported tables
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
        %saveResults - Save all result tables to a file; format is determined by the extension
        %   Supported extensions:
        %     .xlsx - Excel workbook, one worksheet per table
        %     .csv  - Folder of CSV files, one file per table
        %     .html - HTML index page with linked table files
        %     .txt  - Plain-text file with all tables
        %     .tex  - LaTeX file with all tables
        %     .md   - Markdown file with all tables
        %     .mat  - MATLAB binary file
        %
        %   Syntax:
        %     log = obj.saveResults(filename)
        %   Input Arguments:
        %     filename - Output file path; the extension determines the save format
        %   Output Arguments:
        %     log - cMessageLogger object with status and error messages
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
            [fileType,fileExt]=cType.getFileType(filename);
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
                    log.messageLog(cType.ERROR,cMessages.InvalidFileExt,upper(fileExt));
                    return
            end
            if log.status
                log.messageLog(cType.INFO,cMessages.InfoFileSaved,obj.ResultName,filename);
            end
        end

        function res=getTable(obj,name)
        %getTable - Retrieve a named table from the result set
        %   Returns a cMessageLogger with an error if the name is not found.
        %
        %   Syntax:
        %     res = obj.getTable(name)
        %   Input Arguments:
        %     name - Name of the table (character vector)
        %   Output Arguments:
        %     res - cTable object, or cMessageLogger on error
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
        %saveTable - Save a single named table to a file; format is determined by the extension
        %
        %   Syntax:
        %     log = obj.saveTable(tname, filename)
        %   Input Arguments:
        %     tname    - Name of the table to save (character vector)
        %     filename - Output file path; the extension determines the save format
        %   Output Arguments:
        %     log - cMessageLogger with the operation status and any error messages
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
        %exportTable - Export a single named table to a MATLAB variable in the selected format
        %   Returns a cMessageLogger with an error if the table name is not found.
        %
        %   Syntax:
        %     res = obj.exportTable(tname)
        %     res = obj.exportTable(tname, varmode)
        %     res = obj.exportTable(tname, varmode, fmt)
        %   Input Arguments:
        %     tname   - Name of the table (character vector)
        %     varmode - Output format (optional)
        %       cType.VarMode.NONE:   cTable object (default)
        %       cType.VarMode.CELL:   cell array
        %       cType.VarMode.STRUCT: structured array
        %       cType.VarMode.TABLE:  MATLAB table
        %     fmt - Logical flag to apply column format strings to values (default: false)
        %   Output Arguments:
        %     res - Table contents in the requested format, or cMessageLogger on error
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
        %saveAsCSV - Save result tables as CSV files, one file per table
        %   Creates a subfolder named '<basename>_csv' containing one CSV file per table
        %   plus an index CSV file, and writes a pointer file at the given filename.
        %
        %   Syntax:
        %     log = obj.saveAsCSV(filename)
        %   Input Arguments:
        %     filename - Path to the pointer file (e.g. 'results.csv')
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
        %
            log=cMessageLogger();
            tidx=getTableIndex(obj);
            % Check Input
            if tidx.NrOfRows<1
                log.messageLog(cType.ERROR,cMessages.NoTableToSave);
                return
            end
            % Check Folder and print info file
            [folder,name,ext]=fileparts(filename);
            fname=strcat(name,'_csv');
            tfolder=fullfile(folder,fname);
            %Write the info directory
            try
                fid = fopen(filename, 'wt');
                fprintf (fid, '%s', fname);
                fclose (fid);
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                return
            end
            if ~exist(tfolder,'dir')
                mkdir(tfolder);
            end
            % Save Index file
            bname=strcat('index',ext);
            fname=fullfile(tfolder,bname);
            slog=exportCSV(tidx.Values,fname);
            if ~slog.status
                log.addLogger(slog);
                log.messageLog(cType.ERROR,cMessages.IndexTableNotSave);
            end
            % Save each table in a file
            for i=1:tidx.NrOfRows
                tbl=tidx.Content{i};
                bname=strcat(tbl.Name,ext);
                fname=fullfile(tfolder,bname);
                slog=exportCSV(tbl.Values,fname);
                if ~slog.status
                    log.addLogger(slog);
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,fname);
                end
            end
        end
        
        function log=saveAsXLS(obj,filename)
        %saveAsXLS - Save all result tables in an Excel workbook, one worksheet per table
        %   An 'Index' worksheet listing all tables is written first.
        %   Compatible with both MATLAB (writecell) and Octave (oct2xls).
        %
        %   Syntax:
        %     log = obj.saveAsXLS(filename)
        %   Input Arguments:
        %     filename - Output Excel file path (.xlsx)
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
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
        %saveAsHTML - Save result tables as HTML files with an index page
        %   Creates a subfolder named '<basename>_html' containing one HTML file per table,
        %   and writes a linked index HTML page at the given filename.
        %
        %   Syntax:
        %     log = obj.saveAsHTML(filename)
        %   Input Arguments:
        %     filename - Path to the HTML index file (e.g. 'results.html')
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
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
        %saveAsTXT - Save all result tables to a single formatted plain-text file
        %   Each table is printed in sequence using its printTable formatter.
        %
        %   Syntax:
        %     log = obj.saveAsTXT(filename)
        %   Input Arguments:
        %     filename - Output text file path (.txt)
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
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
        %saveAsLaTeX - Save all result tables to a single LaTeX-formatted file
        %   Each table is rendered via cBuildLaTeX and written in sequence.
        %
        %   Syntax:
        %     log = obj.saveAsLaTeX(filename)
        %   Input Arguments:
        %     filename - Output LaTeX file path (.tex)
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
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
        %exportMarkdown - Save all result tables to a single Markdown file
        %   Each table is rendered via cBuildMarkdown and written in sequence.
        %
        %   Syntax:
        %     log = obj.exportMarkdown(filename)
        %   Input Arguments:
        %     filename - Output Markdown file path (.md)
        %   Output Arguments:
        %     log - cMessageLogger object with the operation status and error messages
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