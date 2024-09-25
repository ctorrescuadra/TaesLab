classdef (Abstract) cTable < cMessageLogger
% cTable - Abstract class for tabular data. 
%   The table definition includes the row and column names
% cTable Properties:
%   NrOfCols  	 - Number of Columns
%   NrOfRows     - Number of Rows
%   RowNames     - Row Names (key codes)
%   ColNames     - Column Names
%   Data	     - Data values
%   Values       - Table values
%   Name         - Table Name
%   Description  - Table Descripcion
%   State        - State Name of values
%   GraphType    - Graph Type associated to table
%
% cTable Methods:
%   showTable       - show the tables in diferent interfaces
%   exportTable     - export table in diferent formats
%   saveTable       - save a table into a file in diferent formats
%   isNumericTable  - check if all data of the table are numeric
%   isNumericColumn - check if a column data is numeric
%   isGraph         - check if the table has a graph associated
%   getColumnFormat - get the format of the columns
%   getColumnWidth  - get the width of the columns
%   getStructData   - get data as struct array
%   getMatlabTable  - get data as MATLAB table
%   getStructTable  - get a structure with the table info
%   setColumnValues - set the values of a column
%   setRowValues    - set the values of a row
%
% See also cTableData, cTableResult
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
        GraphType=0     % Graph Type associated to table
    end
    properties(Access=protected)
        fcol            % Array with columns format
        wcol            % Array with columns width
    end
    methods
        function res=get.Values(obj)
        % get the table Values
            res=cType.EMPTY_CELL;
            if obj.status
                res=[obj.ColNames;[obj.RowNames',obj.Data]];
            end
        end 

        function showTable(obj,option)
        % View Table in console GUI or HTML
        %   Usually is called from cResultSet.showResults
        % Syntax:
        %   obj.showTable(option)
        % Input Arguments:
        %   option - select form to view a table
        %       cType.TableView.NONE
        %       cType.TableView.CONSOLE
        %       cType.TableView.GUI
        %       cType.TableView.HTML
        %
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
                obj.printWarning('Invalid Table View option');
            end
        end
        
        function res=exportTable(obj,varmode,~)
        % Get table values in diferent formats
        % Syntax:
        %   res = obj.exportTable(varmode)
        % Input Arguments:
        %   options - VarMode options
        %       cType.VarMode.NONE: Return a struct with the cTable objects
        %       cType.VarMode.CELL: Return a struct with cell values
        %       cType.VarMode.STRUCT: Return a struct with structured array values
        %       cType.VarModel.TABLE: Return a struct of Matlab tables
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
        % Check if the data of the table is numeric
        % Syntax:
        %   res = obj.isNumericTable
        % Output arguments:
        %   res - true | false
            res=all(cellfun(@isnumeric,obj.Data(:)));
        end
        
        function res = isNumericColumn(obj,idx)
        % Check if a column is numeric (base method)
        % Syntax:
        %   res = obj.isNumericColumn(idx)
        % Input Arguments:
        %   idx - data column number
        % Output arguments:
        %   res - true | false
            tmp=cellfun(@isnumeric,obj.Data(:,idx));
            res=all(tmp(:));
        end

        function res=isGraph(obj)
        % Check if the table has a graph associated
            res=(obj.GraphType ~= cType.GraphType.NONE);
        end

        function res=getColumnFormat(obj)
        % Get the format of each column table
        % Syntax:
        %   res = obj.getColumnFormat
        % Output Arguments:
        %   res - Vector indicating the format of each column
        % See also cType.ColumnFormat
            res=obj.fcol;
        end

        function res=getColumnWidth(obj)
        % Get the maximun width of each column
        % Syntax:
        %   res = obj.getColumnWidth
        % Output Arguments:
        %   res - Vector indicating the width of each column
        %
            res=obj.wcol;
        end
        
        function res = getStructData(obj)
        % Get table data as struct array
        % Syntax:
        %   res = obj.getStructData
        % Output Arguments:
        %   res - struct array containing the data of the table
        %     Each column name is a field of the structure
        %
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        % Get Table as Matlab table
        % Syntax:
        %   res = obj.getMatlabTable
        % Output Argument
        %   res - Matlab table object with values of the cTable object
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
        % Get a structure with the table info
        % Syntax:
        %   res = obj.getStructTable
        % Output Argument
        %   res - struct with the data and info of the table
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function log=setColumnValues(obj,idx,value)
        % Set the values of a column table
        % Syntax:
        %   log = obj.setColumnValues(idx,values)
        % Input Arguments:
        %   idx - vector with columns index to replace
        %   value - cell array with the values to replace
        % Output Arguments:
        %   log - cMessageLogger with the status and messages of operation
            log=cMessageLogger();
            if iscell(value) && size(value,1)==obj.NrOfRows
                obj.Data(:,idx)=value;
            else
                log.printError('Invalid table %s values',obj.Name);
            end
        end

        function log=setRowValues(obj,idx,value)
        % Set the values of a row table
        % Syntax:
        %   log = obj.setRowValues(idx,values)
        % Input Arguments:
        %   idx - vector with rows index to replace
        %   value - cell array with the values to replace
        % Output Arguments:
        %   log - cMessageLogger with the status and messages of operation
        %
            log=cMessageLogger();
            if iscell(value) && (size(value,2)==obj.NrOfCols-1)
                obj.Data(idx,:)=value;
            else
                log.printError('Invalid table %s values',obj.Name);
            end
        end
 
        function log = saveTable(obj,filename)
        % Generate a file with the table values
        %   The file types depends on the extension
        %   Valid extensions are: CSV,XLSX,JSON,XML,TXT,HTML,LaTeX and MAT
        % Syntax:
        %   log = obj.saveTable(filename)
        % Input Argument:
        %   filename - Nane of the file
        % Output Argument:
        %   log - cMessageLogger object with status and error messages
        %
            log=cMessageLogger();
            if (nargin~=2) || ~obj.status || ~isFilename(filename)
                log.messageLog(cType.ERROR,'Invalid input arguments');
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
                otherwise
                        log.messageLog(cType.ERROR,'File extension %s is not supported',ext);
            end
            if log.status
                log.messageLog(cType.INFO,'Table %s has been saved in file %s',obj.Name, filename);
            end
        end
    
        function setState(obj,state)
        % Set state value. Internal function 
            obj.State=state;
        end

        function setGraphType(obj,type)
        % Set the GraphType property. Internal function
            obj.GraphType=type;
        end
    
        function res=size(obj,dim)
        % Overload size function
            if nargin==1
                res=size(obj.Values);
            else
                res=size(obj.Values,dim);
            end
        end
    end
    methods(Access=protected)
        function log=exportCSV(obj,filename)
        % exportCSV saves table values as CSV file
            log=exportCSV(obj.Values,filename);
        end

        function log=exportXLS(obj,filename)
        % exportXLS saves table cell as XLS file
            log=cMessageLogger();
            data=obj.Values;
            if isOctave
                xls=xlsopen(filename,1);
                [xls,status]=oct2xls(data,xls,obj.Name);
                xls=xlsclose(xls);
                if ~status || isempty(xls)
                    log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
                end
            else 
                try
                    writecell(data,filename,'Sheet',obj.Name);      
                catch err
                    log.messageLog(cType.ERROR,err.message);
                    log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
                end
            end
        end  
               
        function log=exportTXT(obj,filename)
        % Save a table as text file
            log=cMessageLogger();
            try
                fId = fopen (filename, 'wt');
                printTable(obj,fId)
                fclose(fId);
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end
                
        function log=exportHTML(obj,filename)
        % Save a table as HTML file
            log=cMessageLogger();
            html=cBuildHTML(obj);
            if html.status
                log=html.saveTable(filename);
            else
                log.addLogger(html);
            end
        end
    
        function log=exportLaTeX(obj,filename)
        % exportLaTeX generates the LaTex table code file of cTable object
            log=cMessageLogger();
            ltx=cBuildLaTeX(obj);
            if ltx.status
                log=ltx.saveTable(filename);
            else
                log.addLogger(ltx);
            end
        end

        function log=exportJSON(obj,filename)
        % save data model as JSON file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages and status
            log=cMessageLogger(); 
            data=obj.getStructTable;
            try
                text=jsonencode(data,'PrettyPrint',true);
                fid=fopen(filename,'wt');
                fwrite(fid,text);
                fclose(fid);
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end

        function log=exportXML(obj,filename)
        % save data model as XML file
        %  Input:
        %   filename - name of the output file
        %  Output:
        %   log: cStatusLog class containing error messages ans status
            log=cMessageLogger();
            data=obj.getStructTable;
            try
                writestruct(data,filename,'StructNodeName','root','AttributeSuffix','Id');
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end
    
        function showTableGUI(obj)
        % View the values of the table (tbl) in a uitable graphic object
            vt=cViewTable(obj);
            if vt.status
                vt.showTable
            else
                vt.printError('Invalid uitable %s',obj.name);
            end
        end
    
        function showTableHTML(obj)
        % View a table in the web browser
            vh=cBuildHTML(obj);
            if vh.status
                vh.showTable
            else
                printLogger(vh);
            end
        end

        function status = checkTableSize(obj)
        % Check the size of the table
            status = (size(obj.Data,1)==obj.NrOfRows) && (size(obj.Data,2)==obj.NrOfCols-1);
        end  
    end
end