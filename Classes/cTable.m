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
    
        function res = getStructData(obj)
        % Get the table as struct array
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end

        function res=getMatlabTable(obj)
        % Get the table as Matlab table
            if isOctave
                res=obj;
            else
                res=cell2table(obj.Data,'VariableNames',obj.ColNames(2:end),'RowNames',obj.RowNames');
                res=addprop(res,"Name","table");
                res.Properties.Description=obj.Description;
                res.Properties.CustomProperties.Name=obj.Name;
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

        function log=exportCSV(obj,filename)
        % Export the table as CSV file
        %   This method is used internally for SaveResults
        %   Input:
        %       filename - Name of the file to save the table
        %   Output:
        %       log - cStatusLogger with the status and messages
            log=cStatusLogger(cType.VALID);
            data=obj.Values;
            if ~cType.checkFileExt(filename,cType.FileExt.CSV)
                obj.messageLog(cType.ERROR,'Invalid file name extension: %s',filename)
                return
            end
            try
                if isOctave
                    cell2csv(filename,data);
                else
                    writecell(data,filename);
                end
            catch err
                log.messageLog(cType.ERROR,err.message);
                log.messageLog(cType.ERROR,'File %s could NOT be saved',filename);
            end
        end

        function res=getColWidth(obj)
            M=obj.NrOfCols;
            res=zeros(1,M);
            for j=1:M
                res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
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