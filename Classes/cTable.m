classdef (Abstract) cTable < cMessageLogger
%cTable - Abstract class for tabular data.
%   This is the base class for tables. It is not intended to be
%   instantiated directly. Use cTableData, cTableCell or cTableMatrix instead.
%   The table definition includes the row and column names, the values, a description,
%   the state and sample names, and the graph type associated to the table, and other properties
%   The class also includes common methods, applied to the derived classes to show, export and save
%   the table in different formats.
%
%   cTable properties:
%     NrOfCols  	 - Number of Columns
%     NrOfRows     - Number of Rows
%     RowNames     - Row Names (key codes)
%     ColNames     - Column Names
%     Data	       - Data values
%     Values       - Table values
%     Name         - Table Name
%     Description  - Table Descripcion
%     State        - State Name of values
%     Sample       - Resource sample name
%     Resources    - Contains reources info
%     GraphType    - Graph Type associated to table
%
%   cTable methods:
%     getProperties   - Get table properties
%     setStudyCase    - Set state and sample values
%     setDescription  - Set Table Header or Description 
%     showTable       - show the tables in diferent interfaces
%     exportTable     - export table in diferent formats
%     saveTable       - save a table into a file in diferent formats
%     isNumericTable  - check if all data of the table are numeric
%     isNumericColumn - check if a column data is numeric
%     isGraph         - check if the table has a graph associated
%     getColumnFormat - get the format of the columns
%     getColumnWidth  - get the width of the columns
%     getStructData   - get data as struct array
%     getMatlabTable  - get data as MATLAB table
%     getStructTable  - get a structure with the table info
%     setColumnValues - set the values of a column
%     setRowValues    - set the values of a row
%
%   See also cTableData, cTableResult
%
    properties(GetAccess=public, SetAccess=protected)
        NrOfCols  	    % Number of Columns
        NrOfRows        % Number of Rows
        RowNames		% Row Names (key codes)
        ColNames		% Column Names
        Data			% Data values
        Values          % Table values
        Name            % Table Name
        Description     % Table Descripcion
        State           % State Name
        Sample          % Sample Name
        Resources=false % Contains resources info
        GraphType=0     % Graph Type associated to table
    end
    
    properties(Access=protected)
        fcol            % Array with columns format
        wcol            % Array with columns width
    end

    methods
        function res=get.Values(obj)
        % Get the table Values. Includes ColNames, RowNames and Data
            res=cType.EMPTY_CELL;
            if obj.status
                res=[obj.ColNames;[obj.RowNames',obj.Data]];
            end
        end

        function res=getProperties(obj)
        %getProperties - Get table properties
        %   Syntax:
        %     res=obj.getProperties
        %   Output Arguments:
        %     res - structure with table properties
        %
            res=struct('Name',obj.Name,'Description',obj.Description,...
                'State',obj.State,'Sample',obj.Sample,'Resources',obj.Resources,...
                'GraphType',obj.GraphType);
        end

        function setStudyCase(obj,info)
        %setStudyCase - Set state and sample values. Internal function
        %   Syntax:
        %     obj.setStudyCase(filename)
        %   Input Arguments:
        %     info - Struct with state and sample names
        %   
            obj.State=info.State;
            if obj.Resources && isfield(info,'Sample')
                obj.Sample=info.Sample;
            else
                obj.Sample=cType.EMPTY_CHAR;
            end
        end

        function setDescription(obj,descr)
        %setDescription - Set Table Header or Description.
        %   Internal Use. Permite to reuse a table format with other names
        %   Syntax:
        %     obj.setTableName(filename)
        %   Input Arguments:
        %     description - Description/header of the table
        %
            obj.Description=descr;
        end

        function showTable(obj,option)
        %showTable - View Table in console GUI or HTML
        %   Usually is called from cResultSet.showResults
        %
        %   Syntax:
        %     obj.showTable(option)
        %   Input Arguments:
        %     option - select form to view a table
        %       cType.TableView.NONE
        %       cType.TableView.CONSOLE (default option)
        %       cType.TableView.GUI
        %       cType.TableView.HTML
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
        %exportTable - Get table values in diferent formats
        %   Syntax:
        %     res = obj.exportTable(varmode)
        %   Input Arguments:
        %     options - VarMode options
        %       cType.VarMode.NONE: Return a struct with the cTable objects
        %       cType.VarMode.CELL: Return a struct with cell values
        %       cType.VarMode.STRUCT: Return a struct with structured array values
        %       cType.VarModel.TABLE: Return a struct of Matlab tables
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
        %isNumericTable - Check if the data of the table is numeric
        %   Syntax:
        %     res = obj.isNumericTable
        %   Output arguments:
        %     res - true | false
            res=all(obj.fcol(2:end)-1);
        end
        
        function res = isNumericColumn(obj,idx)
        %isNumericColumn - Check if a column is numeric (base method)
        %   Syntax:
        %     res = obj.isNumericColumn(idx)
        %   Input Arguments:
        %     idx - data column number
        %   Output arguments:
        %     res - true | false
            res=(obj.fcol(idx)==cType.ColumnFormat.NUMERIC);
        end

        function res=isGraph(obj)
        %isGraph - Check if the table has a graph associated
        %   Syntax:
        %     res=obj.isGraph
        %   Output Arguments:
        %     res - true | false
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function res=getColumnFormat(obj)
        %getColumnFormat - Get the format of each column table
        %   Syntax:
        %     res = obj.getColumnFormat
        %   Output Arguments:
        %     res - Cell array indicating the format of each column
        %   See also cType.ColumnFormat
            res=obj.fcol;
        end

        function res=getColumnWidth(obj)
        %getColumnWidth - Get the maximun width of each column
        %   Syntax:
        %     res = obj.getColumnWidth
        %   Output Arguments:
        %     res - Vector array indicating the width of each column
        %
            res=obj.wcol;
        end
        
        function res = getStructData(obj)
        %getTable - Get table data as struct array
        %   Syntax:
        %     res = obj.getStructData
        %   Output Arguments:
        %     res - struct array containing the data of the table
        %       Each column name is a field of the structure
        %
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        %getMatlabTable - Get Table as Matlab table
        %   Syntax:
        %     res = obj.getMatlabTable
        %   Output Arguments:
        %     res - Matlab table object with values of the cTable object
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
        %getStructTable - Get a structure with the table info
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with the data and info of the table
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function res=getColumnValues(obj,idx)
        %getColumnValues - Get the values of a column table
        %   Syntax:
        %     res = obj.setColumnValues(idx)
        %   Input Arguments:
        %     idx - Column data index
        %   Output Arguments:
        %     value - array if column is numeric or cell array otherwise
            if isNumericColumn(obj,idx+1)
                res=cell2mat(obj.Data(:,idx));
            else
                res=obj.Data(:,idx);
            end
        end

        function res=getColumnData(obj,idx)
        %getColumnData - Get a key/value array struct of a column table
        %   Syntax:
        %     res = obj.setColumnData(idx)
        %   Input Arguments:
        %     idx - Column data index
        %   Output Arguments:
        %     res - array struct key/value         
            try
                res=cell2struct([obj.RowNames',obj.Data(:,idx)],cType.KEYVAL,2);
            catch
                res=[];
            end
        end

        function log=setColumnValues(obj,idx,value)
        %setColumnValues - Set the values of a column table
        %   Syntax:
        %     log = obj.setColumnValues(idx,values)
        %   Input Arguments:
        %     idx - vector with columns index to replace
        %     value - cell array with the values to replace
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
        %setRowValues - Set the values of a table row
        %   Syntax:
        %     log = obj.setRowValues(idx,values)
        %   Input Arguments:
        %     idx - vector with rows index to replace
        %     value - cell array with the values to replace
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
            [fileType,ext]=cType.getFileType(filename);
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
                    log.messageLog(cType.ERROR,cMessages.InvalidFileExt,ext);
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
        %exportCSV - save table values as CSV file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
        %
            log=exportCSV(obj.Values,filename);
        end

        function log=exportXLS(obj,filename)
        %exportXLS - save table values as XLS file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %exportTXT - Save table as text file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %exportHTML - save table as HTML file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %exportLaTeX - generates the LaTex table code file of cTable object
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %exportMarkdown - generates the Markdown table code file of cTable object
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %exportJSON - save table as JSON file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
        %
            log=cMessageLogger(); 
            data=obj.getStructTable;
            try
                text=jsonencode(data,'PrettyPrint',true);
                fid=fopen(filename,'wt');
                fwrite(fid,text);
                fclose(fid);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,cMessages.FileNotSaved,filename);
            end
        end

        function log=exportXML(obj,filename)
        % save data model as XML file
        %   Input:
        %     filename - name of the output file
        %   Output:
        %     log: cMessageLogger class containing status and messages
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
        %showTableGUI - View the values of the table (tbl) in a uitable graphic object
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
        %showTableHTML - View a table in the web browser
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
        %checkTableSize - Check the size of the table
        %   Syntax:
        %     status = obj.checkTableSize
        %   Output Arguments:
        %     status - true | false
        %
            status = (size(obj.Data,1)==obj.NrOfRows) && (size(obj.Data,2)==obj.NrOfCols-1);
        end  
    end
end