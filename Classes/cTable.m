classdef (Abstract) cTable < cMessageLogger
%cTable - Abstract base class for tabular data.
%   cTable defines the common interface and shared implementation for all table
%   types in TaesLab. It is not intended to be instantiated directly; use the
%   concrete subclasses cTableData, cTableCell or cTableMatrix instead.
%
%   A cTable object holds row and column names, a data cell array, a description
%   string, state/sample identifiers, and a graph-type tag. It provides methods
%   to display, export and save the table in multiple formats.
%
%   cTable properties:
%     NrOfCols    - Number of columns (including the row-name column)
%     NrOfRows    - Number of data rows
%     RowNames    - Row key names (1 x NrOfRows cell array)
%     ColNames    - Column names  (1 x NrOfCols cell array)
%     Data        - Data values   (NrOfRows x NrOfCols-1 cell array)
%     Values      - Full table cell array: ColNames prepended, RowNames in col 1
%     Name        - Table identifier name
%     Description - Table header or description text
%     State       - Thermodynamic state or data label associated with the table
%     Sample      - Resource cost sample name
%     Resources   - True if the table contains resource cost information
%     GraphType   - Graph type associated with the table (see cType.GraphType)
%
%   cTable methods:
%     getProperties   - Return a struct with the main table properties
%     setStudyCase    - Set the State and Sample identifiers
%     setDescription  - Set the table description text
%     showTable       - Display the table (console, GUI or HTML)
%     exportTable     - Return table data in different variable formats
%     saveTable       - Save the table to a file (CSV, XLSX, JSON, XML, TXT, HTML, LaTeX, MD, MAT)
%     size            - Return table size (overloads built-in size)
%     isNumericTable  - True if all data columns are numeric
%     isNumericColumn - True if a specified column is numeric
%     isGraph         - True if a graph type is associated with the table
%     formatData      - Return raw data (base implementation; overridden by subclasses)
%     getColumnFormat - Return the format code array for all columns
%     getColumnWidth  - Return the display width array for all columns
%     getColumnValues - Return the values of a data column as array or cell
%     getColumnData   - Return a key/value struct array for a data column
%     getStructData   - Return table data as a struct array
%     getMatlabTable  - Return table as a MATLAB table object (MATLAB only)
%     getStructTable  - Return a struct with table name, description and data
%     setColumnValues - Replace the values of one or more data columns
%     setRowValues    - Replace the values of one or more data rows
%
%   See also cTableData, cTableCell, cTableMatrix
%
    properties(GetAccess=public, SetAccess=protected)
        NrOfCols        % Number of columns (including the row-name column)
        NrOfRows        % Number of data rows
        RowNames        % Row key names (1 x NrOfRows cell array)
        ColNames        % Column names  (1 x NrOfCols cell array)
        Data            % Data values   (NrOfRows x NrOfCols-1 cell array)
        Values          % Full table cell array (ColNames + RowNames + Data)
        Name            % Table identifier name
        Description     % Table header or description text
        State           % State or data label associated with the table
        Sample          % Resource cost sample name
        Resources=false % True if the table contains resource cost information
        GraphType=0     % Graph type associated with the table (see cType.GraphType)
    end
    
    properties(Access=protected)
        fcol            % Column format code array (see cType.ColumnFormat)
        wcol            % Column display width array
    end

    methods
        function res=get.Values(obj)
        %get.Values - Return the full table cell array
        %   Combines ColNames (first row), RowNames (first column) and Data.
        %   Returns cType.EMPTY_CELL if the object is invalid.
            res=cType.EMPTY_CELL;
            if obj.status
                res=[obj.ColNames;[obj.RowNames',obj.Data]];
            end
        end

        function res=getProperties(obj)
        %getProperties - Return a struct with the main table properties
        %   Syntax:
        %     res = obj.getProperties
        %   Output Arguments:
        %     res - struct with fields: Name, Description, State, Sample,
        %           Resources, GraphType
        %
            res=struct('Name',obj.Name,'Description',obj.Description,...
                'State',obj.State,'Sample',obj.Sample,'Resources',obj.Resources,...
                'GraphType',obj.GraphType);
        end

        function setStudyCase(obj,info)
        %setStudyCase - Set the State and Sample identifiers
        %   Sets State from info.State. Sets Sample from info.Sample only when
        %   the table carries resource cost information (Resources == true) and
        %   the field exists; otherwise clears Sample.
        %   Syntax:
        %     obj.setStudyCase(info)
        %   Input Arguments:
        %     info - struct with fields State (required) and Sample (optional)
        %
            obj.State=info.State;
            if obj.Resources && isfield(info,'Sample')
                obj.Sample=info.Sample;
            else
                obj.Sample=cType.EMPTY_CHAR;
            end
        end

        function setDescription(obj,descr)
        %setDescription - Set the table description text
        %   Allows reusing a table format definition with a different description.
        %   Syntax:
        %     obj.setDescription(descr)
        %   Input Arguments:
        %     descr - char array with the new description or header text
        %
            obj.Description=descr;
        end

        function showTable(obj,option)
        %showTable - Display the table in the selected output interface
        %   Typically called from cResultSet.showResults.
        %   Syntax:
        %     obj.showTable(option)
        %   Input Arguments:
        %     option - output interface selector (default: cType.TableView.CONSOLE)
        %       cType.TableView.NONE    - do nothing
        %       cType.TableView.CONSOLE - print to the console
        %       cType.TableView.GUI     - display in a uitable GUI window
        %       cType.TableView.HTML    - render in the system web browser
        %
            if ~obj.status
                printLogger(obj);
                return
            end
            if nargin==1
                option=cType.TableView.CONSOLE;
            end
            switch option
            case cType.TableView.NONE
                return
            case cType.TableView.CONSOLE
                printTable(obj);
            case cType.TableView.GUI
                showTableGUI(obj)
            case cType.TableView.HTML
                showTableHTML(obj)
            otherwise
                obj.printWarning(cMessages.InvalidTableView);
            end
        end
        
        function res=exportTable(obj,varmode,~)
        %exportTable - Return table data in different variable formats
        %   Syntax:
        %     res = obj.exportTable(varmode)
        %   Input Arguments:
        %     varmode - output variable type (default: cType.VarMode.NONE)
        %       cType.VarMode.NONE   - return the cTable object itself
        %       cType.VarMode.CELL   - return a cell array (Values property)
        %       cType.VarMode.STRUCT - return a struct array (via getStructData)
        %       cType.VarMode.TABLE  - return a MATLAB table object (MATLAB only)
        %   Output Arguments:
        %     res - table data in the requested variable type
            if ~obj.status
                printLogger(obj);
                return
            end
            if nargin==1
                varmode=cType.VarMode.NONE;
            end        
            switch varmode
                case cType.VarMode.NONE
                    res=obj;
                case cType.VarMode.CELL
                    res=obj.Values;
                case cType.VarMode.STRUCT
                    res=obj.getStructData;
                case cType.VarMode.TABLE
                    if isMatlab
                        res=obj.getMatlabTable;
                    else
                        res=obj;
                    end
                otherwise
                    res=obj;
            end
        end

        function res = isNumericTable(obj)
        %isNumericTable - True if all data columns are numeric
        %   Syntax:
        %     res = obj.isNumericTable
        %   Output Arguments:
        %     res - logical scalar
            res=all(obj.fcol(2:end)-1);
        end
        
        function res = isNumericColumn(obj,idx)
        %isNumericColumn - True if the specified column contains numeric data
        %   idx uses the full column index (1 = row-name column, 2 = first data column).
        %   Syntax:
        %     res = obj.isNumericColumn(idx)
        %   Input Arguments:
        %     idx - column index (1-based, includes the row-name column)
        %   Output Arguments:
        %     res - logical scalar
        %   See also cType.ColumnFormat
            res=(obj.fcol(idx)==cType.ColumnFormat.NUMERIC);
        end

        function res=isGraph(obj)
        %isGraph - True if a graph type is associated with the table
        %   Syntax:
        %     res = obj.isGraph
        %   Output Arguments:
        %     res - logical scalar
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function res=formatData(obj)
        %formatData - Return the raw data cell array (base implementation)
        %   Subclasses override this method to apply column-specific formatting.
        %   Syntax:
        %     res = obj.formatData
        %   Output Arguments:
        %     res - cell array identical to Data (no formatting applied)
            res=obj.Data;
        end

        function res=getColumnFormat(obj)
        %getColumnFormat - Return the format code array for all columns
        %   Syntax:
        %     res = obj.getColumnFormat
        %   Output Arguments:
        %     res - numeric array (1 x NrOfCols) with cType.ColumnFormat codes
        %   See also cType.ColumnFormat
            res=obj.fcol;
        end

        function res=getColumnWidth(obj)
        %getColumnWidth - Return the display width array for all columns
        %   Syntax:
        %     res = obj.getColumnWidth
        %   Output Arguments:
        %     res - numeric array (1 x NrOfCols) with the display width of each column
        %
            res=obj.wcol;
        end
        
        function res=getStructData(obj)
        %getStructData - Return table data as a struct array
        %   Syntax:
        %     res = obj.getStructData
        %   Output Arguments:
        %     res - struct array (NrOfRows x 1) where each field corresponds to
        %           a column name (including the row-name column)
        %
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        %getMatlabTable - Return the table as a MATLAB table object
        %   Not supported on Octave (returns the cTable object instead).
        %   The MATLAB table carries Name, State and GraphType as custom properties
        %   and Description as the table Description.
        %   Syntax:
        %     res = obj.getMatlabTable
        %   Output Arguments:
        %     res - MATLAB table object, or the cTable object itself on Octave
            if ~obj.status
                printLogger(obj)
                return
            end
            if isOctave
                res=obj;
            else
                res=cell2table(obj.Data,'VariableNames',obj.ColNames(2:end),'RowNames',obj.RowNames');
                res=addprop(res,["Name","State","GraphType"],["table","table","table"]);
                res.Properties.Description=obj.Description;
                res.Properties.CustomProperties.Name=obj.Name;
                res.Properties.CustomProperties.State=obj.State;
                res.Properties.CustomProperties.GraphType=obj.GraphType;
            end
        end

        function res=getStructTable(obj)
        %getStructTable - Return a struct with table name, description and data
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with fields: Name, Description, State, Data
        %           (Data is a struct array as returned by getStructData)
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function res=getColumnValues(obj,idx)
        %getColumnValues - Return the values of a data column
        %   Syntax:
        %     res = obj.getColumnValues(idx)
        %   Input Arguments:
        %     idx - data column index (1 = first data column, excludes row-name column)
        %   Output Arguments:
        %     res - numeric array if the column is numeric; cell array otherwise
            if isNumericColumn(obj,idx+1)
                res=cell2mat(obj.Data(:,idx));
            else
                res=obj.Data(:,idx);
            end
        end

        function res=getColumnData(obj,idx)
        %getColumnData - Return a key/value struct array for a data column
        %   Syntax:
        %     res = obj.getColumnData(idx)
        %   Input Arguments:
        %     idx - data column index (1 = first data column, excludes row-name column)
        %   Output Arguments:
        %     res - struct array with fields 'key' (RowNames) and 'value' (column data);
        %           empty array [] if the conversion fails
            try
                res=cell2struct([obj.RowNames',obj.Data(:,idx)],cType.KEYVAL,2);
            catch
                res=[];
            end
        end

        function log=setColumnValues(obj,idx,value)
        %setColumnValues - Replace the values of one or more data columns
        %   Syntax:
        %     log = obj.setColumnValues(idx,value)
        %   Input Arguments:
        %     idx   - column index or index vector (data columns only)
        %     value - cell array (NrOfRows x numel(idx)) with replacement values
        %   Output Arguments:
        %     log - cMessageLogger with the status of the operation
            log=cTaesLab();
            if iscell(value) && size(value,1)==obj.NrOfRows
                obj.Data(:,idx)=value;
            else
                log.printError(cMessages.InvalidTableValues,obj.Name);
            end
        end

        function log=setRowValues(obj,idx,value)
        %setRowValues - Replace the values of one or more data rows
        %   Syntax:
        %     log = obj.setRowValues(idx,value)
        %   Input Arguments:
        %     idx   - row index or index vector
        %     value - cell array (numel(idx) x NrOfCols-1) with replacement values
        %   Output Arguments:
        %     log - cMessageLogger with the status of the operation
        %
            log=cTaesLab();
            if iscell(value) && (size(value,2)==obj.NrOfCols-1)
                obj.Data(idx,:)=value;
            else
                log.printError(cMessages.InvalidTableValues,obj.Name);
            end
        end
 
        function log = saveTable(obj,filename)
        %saveTable - Generate a file with the table values
        %   The file type depends on the extension
        %   Valid extensions are: CSV,XLSX,JSON,XML,TXT,HTML,LaTeX, MD and MAT
        %
        %   Syntax:
        %     log = obj.saveTable(filename)
        %   Input Arguments:
        %     filename - Name of the file
        %   Output Arguments:
        %     log - cMessageLogger object with status and error messages
        %
            log=cMessageLogger();
            if (nargin~=2) || ~obj.status || ~isFilename(filename)
                log.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            [fileType,fileExt]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    log=exportCSV(obj,filename);
                case cType.FileType.XLSX
                    log=exportXLS(obj,filename);
                case cType.FileType.JSON
                    log=exportJSON(obj,filename);
                case cType.FileType.XML
                    log=exportXML(obj,filename);
                case cType.FileType.TXT
                    log=exportTXT(obj,filename);
                case cType.FileType.HTML
                    log=exportHTML(obj,filename);
                case cType.FileType.LaTeX
                    log=exportLaTeX(obj,filename);
                case cType.FileType.MAT
                    log=exportMAT(obj,filename);
                case cType.FileType.MD
                    log=exportMarkdown(obj,filename);
                case cType.FileType.M
                    log=exportContents(obj,filename);
                otherwise
                    log.messageLog(cType.ERROR,cMessages.InvalidFileExt,upper(fileExt));
            end
            if log.status
                log.messageLog(cType.INFO,cMessages.TableFileSaved,obj.Name, filename);
            end
        end
    
        function res=size(obj,dim)
        %size - Size of the table. Overload of size function.
        %   Syntax:
        %     res=size(obj,dim)
        %   Input Arguments:
        %     dim - (optional) dimension to return
        %           1 - number of rows
        %           2 - number of columns
        %   Output Arguments:
        %     res - size of the table or size of the selected dimension
        %
            if nargin==1
                res=size(obj.Values);
            else
                res=size(obj.Values,dim);
            end
        end
    end
    
    methods(Access=protected)
        function log=exportCSV(obj,filename)
        %exportCSV - Save table values as a CSV file
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=exportCSV(obj.Values,filename);
        end

        function log=exportXLS(obj,filename)
        %exportXLS - Save table values as an XLSX file
        %   The table is written to a sheet named obj.Name.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            data=obj.Values;
            if isOctave
                xls=xlsopen(filename,1);
                [xls,status]=oct2xls(data,xls,obj.Name);
                xls=xlsclose(xls);
                if ~status || isempty(xls)
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                end
            else 
                try
                    writecell(data,filename,'Sheet',obj.Name);      
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
                end
            end
        end  
               
        function log=exportTXT(obj,filename)
        %exportTXT - Save table as a plain-text file
        %   Uses printTable to write a formatted layout.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            try
                fId = fopen (filename, 'wt');
                printTable(obj,fId)
                fclose(fId);
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end
                
        function log=exportHTML(obj,filename)
        %exportHTML - Save table as an HTML file
        %   Delegates to cBuildHTML.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            html=cBuildHTML(obj);
            if html.status
                log=html.saveTable(filename);
            else
                log.addLogger(html);
            end
        end
    
        function log=exportLaTeX(obj,filename)
        %exportLaTeX - Save table as a LaTeX tabular file
        %   Delegates to cBuildLaTeX.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            ltx=cBuildLaTeX(obj);
            if ltx.status
                log=ltx.saveTable(filename);
            else
                log.addLogger(ltx);
            end
        end

        function log=exportMarkdown(obj,filename)
        %exportMarkdown - Save table as a Markdown file
        %   Delegates to cBuildMarkdown.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            md=cBuildMarkdown(obj);
            if md.status
                log=md.saveTable(filename);
            else
                log.addLogger(md);
            end
        end

        function log=exportJSON(obj,filename)
        %exportJSON - Save table as a JSON file
        %   Serialises the struct returned by getStructTable.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            data=obj.getStructTable;
            log = exportJSON(data,filename);
        end

        function log=exportXML(obj,filename)
        %exportXML - Save table as an XML file
        %   Serialises the struct returned by getStructTable using writestruct.
        %   Input Arguments:
        %     filename - path to the output file
        %   Output Arguments:
        %     log - cMessageLogger with status and error messages
        %
            log=cMessageLogger();
            data=obj.getStructTable;
            try
                writestruct(data,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end

        function showTableGUI(obj)
        %showTableGUI - Display the table in a uitable GUI window
        %   Delegates to cViewTable.
        %   Syntax:
        %     obj.showTableGUI
        %
            vt=cViewTable(obj);
            if vt.status
                vt.showTable
            else
                vt.printError(cMessages.InvalidTableGUI,obj.Name);
            end
        end
    
        function showTableHTML(obj)
        %showTableHTML - Render the table in the system web browser
        %   Delegates to cBuildHTML.
        %   Syntax:
        %     obj.showTableHTML
        %
            vh=cBuildHTML(obj);
            if vh.status
                vh.showTable
            else
                printLogger(vh);
            end
        end

        function status = checkTableSize(obj)
        %checkTableSize - True if Data dimensions match NrOfRows and NrOfCols
        %   Used during construction to validate that the supplied data array
        %   is consistent with the row and column name arrays.
        %   Syntax:
        %     status = obj.checkTableSize
        %   Output Arguments:
        %     status - logical scalar
        %
            status = (size(obj.Data,1)==obj.NrOfRows) && (size(obj.Data,2)==obj.NrOfCols-1);
        end  
    end
end