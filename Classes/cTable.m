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