classdef (Abstract) cTable < cStatusLogger
% cTable Abstract class implementation for tabular data
%   The table definition include row and column names and description
%   Methods:
%       status=obj.checkTableSize;
%       obj.setState
%       obj.printTable(fId)
%       obj.viewTable(options)
%       log=obj.saveTable(filename)
%       res=obj.exportTable(varmode)
%       res=obj.isNumericTable
%       res=obj.isNumericColumn(idx)
%       res=obj.getColumnFormat
%       res=obj.getColumnWidth
%       res=obj.formatData
%       res=obj.isGraph
%       obj.setColumnValues(idx,values)
%       obj.setRowValues(idx,values)
% See also cTableData, cTableResult
    properties(GetAccess=public, SetAccess=protected)
        NrOfCols  	    % Number of Columns
        NrOfRows        % Number of Rows
        RowNames		% Row Names (key codes)
        ColNames		% Column Names
        Data			% Data values
        Values          % Table values
        Description=''  % Table Descripcion
        Name=''         % Table Name
        State=''        % State Name
        GraphType=0     % Graph Type associated to table
    end
    properties(Access=protected)
        fcol            % Array with columns format
        wcol            % Array with columns width
    end
    methods
        function res=get.Values(obj)
        % get the table Values
            res=[obj.ColNames;[obj.RowNames',obj.Data]];
        end 
         
        function status = checkTableSize(obj)
        % Check the size of the table
            status = (size(obj.Data,1)==obj.NrOfRows) && (size(obj.Data,2)==obj.NrOfCols-1);
        end

        function setState(obj,state)
        % Set state value
            obj.State=state;
        end

        function res=getDescriptionLabel(obj)
        % Get the description of each table
            res=obj.Description;
        end

        function viewTable(obj,option)
        % View Table in GUI or HTML
        %   Usage:
        %       option - select form to view a table
        %           cType.TableView.CONSOLE
        %           cType.TableView.GUI
        %           cType.TableView.HTML
        %
            if nargin==1
                option=cType.TableView.CONSOLE;
            end
            switch option
            case cType.TableView.CONSOLE
                printTable(obj);
            case cType.TableView.GUI
                viewTableGUI(obj)
            case cType.TableView.HTML
                viewTableHTML(obj)
            end

        end
        
        function log = saveTable(obj,filename)
        % saveTable generate a file with the table values
        %   The file types depends on the extension
        %   Valid extensions are: CSV,XLSX,JSON,XML,TXT,HTML,LaTeX and MAT
        %   Usage:
        %       log = obj.saveTable(filename)
        %   Input:
        %       filename - Nane of the file
        %   Output:
        %       log - cStatusLogger object with error messages
        %
            log=cStatusLogger(cType.VALID);
            [fileType,ext]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    log=exportCSV(obj.Values,filename);
                case cType.FileType.XLSX
                    log=exportXLS(obj.Values,filename);
                case cType.FileType.JSON
                    log=exportJSON(obj.getStructTable,filename);
                case cType.FileType.XML
                    log=exportXML(obj.getStructTable,filename);
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
        end

        function res=exportTable(obj,varmode)
        % Get table values in diferent formats
            if nargin==1
                varmode=cType.VarMode.NONE;
            end        
            switch varmode
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
        % Check is the data of the table is numeric
            res=all(cellfun(@isnumeric,obj.Data(:)));
        end
        
        function res = isNumericColumn(obj,idx)
        % Check if a column is numeric (base mathod)
            tmp=cellfun(@isnumeric,obj.Data(:,idx));
            res=all(tmp(:));
        end

        function setColumnFormat(obj)
        % Define the format of each column (TEXT or NUMERIC)
            tmp=arrayfun(@(x) isNumericColumn(obj,x),1:obj.NrOfCols-1)+1;
            obj.fcol=[cType.ColumnFormat.CHAR,tmp];
        end

        function res=getColumnFormat(obj)
        % Get the columns format
            res=obj.fcol;
        end

        function res=getColumnWidth(obj)
        % Get the columns width
            res=obj.wcol;
        end
        
        function res = getStructData(obj)
        % Get Table data as struct array
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        % Get Table as Matlab table
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
            data=cell2struct([obj.RowNames',obj.Data],obj.ColNames,2);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function log=setColumnValues(obj,idx,value)
        % Set the values of a column table
            log=cStatus(cType.VALID);
            if iscell(value) && size(value,1)==obj.NrOfRows
                obj.Data(:,idx)=value;
            else
                log.printError('Invalid table %s values',obj.Name);
            end
        end

        function log=setRowValues(obj,idx,value)
        % Set the values of a row table
            log=cStatus(cType.VALID);
            if iscell(value) && (size(value,2)==obj.NrOfCols-1)
                obj.Data(idx,:)=value;
            else
                log.printError('Invalid table %s values',obj.Name);
            end
        end
        
        function res=isGraph(obj)
        % Check if the table has a graph associated
            res=(obj.GraphType ~= cType.GraphType.NONE);
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
        function viewTableGUI(obj)
            % View the values of the table (tbl) in a uitable graphic object
                vt=cViewTable(obj);
                if isValid(vt)
                    vt.showTable
                else
                    printLogger(vt);
                end
            end
    
            function viewTableHTML(obj)
            % View a table in the web browser
                vh=cBuildHTML(obj);
                if isValid(vh)
                    vh.showTable
                else
                    printLogger(vh);
                end
            end
    end
end