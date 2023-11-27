classdef (Abstract) cTable < cStatusLogger
% cTable Abstract class implementation for tabular data
%   The table definition include row and column names and description
%   Methods:
%       obj.setDescription
%       status=obj.checkTableSize;
%       res=obj.getStructData
%       res=obj.getMatlabTable [only Matlab]
%       log=obj.exportCSV(filename)
%       log=obj.exportXLS(filename)
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

        function res=exportTable(obj,varmode,~)
        % get cTable info in diferent types of variables
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

        function viewTable(obj)
        % View the values of the table (tbl) in a uitable graphic object
            vt=cViewTable(obj);
            if isValid(vt)
                vt.showTable
            else
                printLogger(vt);
            end
        end

        function log=exportTXT(obj,filename)
        % exportTXT saves table as TXT file 
        %   Usage:
        %       log=exportTXT(data, filename)
        %   Input:
        %       filename - name of TXT file
        %   OUTPUT
        %       log - cLoggerStatus object containing status and error messages
        %
            log=cStatusLogger(cType.VALID);
            if (nargin~=2) || (~ischar(filename))
                log.messageLog(cType.ERROR,'Invalid input arguments');
                return
            end
            if ~cType.checkFileWrite(filename)
                obj.messageLog(cType.ERROR,'Invalid file name: %s',filename);
                return
            end
            if ~cType.checkFileExt(filename,cType.FileExt.TXT)
                obj.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
                return
            end
            try
                fId = fopen (filename, 'wt');
            catch err
                log.messageLog(cType.ERROR,err.message)
                log.messageLog(cType.ERROR,'Open file %s',filename);
                return
            end
            % Print tables into file
            printTable(obj,fId)
            fclose(fId);
        end

        function res = isNumericTable(obj)
            res=all(cellfun(@isnumeric,obj.Data(:)));
        end

        function res = isNumericColumn(obj,idx)
            tmp=cellfun(@isnumeric,obj.Data(:,idx));
            res=all(tmp(:));
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            tmp=arrayfun(@(x) isNumericColumn(obj,x),1:obj.NrOfCols-1)+1;
            res=[cType.colType(tmp)];
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