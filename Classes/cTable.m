classdef (Abstract) cTable < cStatusLogger
% cTable Abstract class implementation for tabular data
%   The table definition include row and column names and description
%   Methods:
%       status=tbl.checkDataSize;
%       obj.setState
%       status=obj.checkTableSize;
%       viewTable(obj)
%       log=obj.saveTable(filename)
%       res=obj.isNumericTable
%       res=obj.getColumnFormat
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

        function viewTable(obj)
        % View the values of the table (tbl) in a uitable graphic object
            vt=cViewTable(obj);
            if isValid(vt)
                vt.showTable
            else
                printLogger(vt);
            end
        end

        function viewHTML(obj)
        % View a table in the web browser
            vh=cBuildHTML(obj);
            if isValid(vh)
                vh.showTable
            else
                printLogger(vh);
            end
        end
        
        function log = saveTable(obj,filename)
        % saveTable save a cTable in a file
        %   The file types depends on the extension
        %   Valid extensions are: CSV,XLSX,JSON,XML,TXT and MAT
        %   Usage:
        %       log = obj.saveTable(filename)
        %   Input:
        %       filename - Nane of the file
        %   Output:
        %       log - cStatusLogger object with the methods actions
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
                case cType.FileType.MAT
                    log=exportMAT(obj,filename);
                otherwise
                    log.messageLog(cType.ERROR,'File extension %s is not supported',ext);
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
                res=addprop(res,["Name","State"],["table","table"]);
                res.Properties.Description=obj.Description;
                res.Properties.CustomProperties.Name=obj.Name;
                res.Properties.CustomProperties.State=obj.State;
            end
        end

        function res=getStructTable(obj)
        % Get a structure with the table info
            data=cell2struct([obj.RowNames',obj.Data],obj.ColNames,2);
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Data',data);
        end

        function res=exportTable(obj,varmode)
        % Get table values in diferent formats
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

        function res=size(obj,dim)
        % Overload size function
            if nargin==1
                res=size(obj.Values);
            else
                res=size(obj.Values,dim);
            end
        end
    end
end