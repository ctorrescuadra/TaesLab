classdef (Sealed) cTableCell < cTableResult
%cTableCell - Implements cTableResult interface to store results as cell arrays.
% 
%   cTableCell constructor
%     obj = cTableCell(data,rowNames,colNames,props)
%
%   cTableCell properties
%     FieldNames  - Cell array with field names 
%     ShowNumber  - Logical variable indicating if line number is printed
%
%   cTableCell methods
%     printTable           - Print a table on console
%     formatData           - Get formatted data
%     getDescriptionLabel  - Get the title label for GUI presentation
%     getColumnValues      - Get the values of a column (using FieldNames)
%
%   cTable Methods
%     getProperties   - Get table properties
%     setStudyCase    - Set state and sample values
%     setDescription  - Set Table Header or Description
%     showTable       - Show the tables in diferent interfaces
%     exportTable     - Export table in diferent formats
%     saveTable       - Save a table into a file in diferent formats
%     isNumericTable  - Check if all data of the table are numeric
%     isNumericColumn - Check if a column data is numeric
%     isGraph         - Check if the table has a graph associated
%     getColumnFormat - Get the format of the columns
%     getColumnWidth  - Get the width of the columns
%     getStructData   - Get data as struct array
%     getMatlabTable  - Get data as MATLAB table
%     getStructTable  - Get a structure with the table info
%
%   See also cTableResult, cTable
%
    properties (GetAccess=public,SetAccess=private)
        FieldNames  % Cell array with field names (optional)
        ShowNumber  % logical variable indicating if line number is printed
    end
	
    methods
        function obj=cTableCell(data,rowNames,colNames,props)
        %cTableCell - Create Cell Table object
        %   Syntax:
        %     obj = cTableCell(data,rowNames,colNames,props)
        %   Input:
        %     data - data values as cell array
        %     rowNames - row's names as cell array 
        %     colNames - column's  names as cell array
        %     props - additional properties:
        %       Name: Name of the table
        %       Description: table description
        %       Unit: cell array with the unit name of the data columns
        %       Format: cell array with the format of the data columns
        %       GraphType: type of graph asociated
        %       FieldNames: optional field name of the columns
        %       ShowNumber: true/false show column number option
        %       NodeType: Type of node (flow, process, stream)
        %
            % Assign properties
            if iscolumn(rowNames)
                obj.RowNames=transpose(rowNames);
            else
                obj.RowNames=rowNames;
            end
            if iscolumn(colNames)
                obj.ColNames=transpose(colNames);
            else
                obj.ColNames=colNames;
            end
            obj.Data=data;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            if obj.checkTableSize
                obj.setProperties(props)
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end

        function res=formatData(obj)
        %formatData - Apply format to data
        %   Syntax:
        %     res=obj.formatData
        %   Output Results:
        %     res - formatted data (numeric)
        %
            N=obj.NrOfRows;
            M=obj.NrOfCols-1;
            res=cell(N,M);
            for j=1:M
                fmt=obj.Format{j+1};
                if ismember('f',fmt)
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),obj.Data(:,j),'UniformOutput',false);
                else
                    res(:,j)=obj.Data(:,j);
                end
            end
        end

        function res=getMatlabTable(obj)
        %getMatlabTable - Get table as Matlab table object
        % Syntax:
        %   res=obj.getMatlabTable
        % Output Results:
        %   res - Matlab table with data information and properties
        %
            res=getMatlabTable@cTable(obj);
            if isMatlab && obj.status
                res.Properties.VariableNames=obj.FieldNames(2:end);
                res.Properties.VariableUnits=obj.Unit(2:end);
                res.Properties.VariableDescriptions=obj.ColNames(2:end);
                res=addprop(res,["ShowNumber","Format"],["table","variable"]);
                res.Properties.CustomProperties.Format=obj.Format(2:end);
                res.Properties.CustomProperties.ShowNumber=obj.ShowNumber;
            end
        end

        function res=getStructData(obj,fmt)
        % getStructData - Get the table data as struct
        % Syntax:
        %   res = obj.getStructData(fmt)
        % Input Argument:
        %   fmt - Use data table format true | false (default)
        % Output Argument:
        %   res - struct with data information
            if ~obj.status
                printLogger(obj)
                return
            end
            if nargin==1
                fmt=false;
            end
            if fmt
                val=[obj.RowNames',obj.formatData];
            else
                val=[obj.RowNames',obj.Data];
            end
            res=cell2struct(val,obj.FieldNames,2);
        end

        function res=getStructTable(obj)
        % getStructTable - Get the table as a struct. Include properties
        % Syntax:
        %   res = obj.getStructTable
        % Output Argument:
        %   res - struct with data information and properties
            if ~obj.status
                printLogger(obj)
                return
            end
            N=obj.NrOfCols-1;
            data=obj.getStructData;
            fields(N)=struct('Name',cType.EMPTY_CHAR,'Format',cType.EMPTY_CHAR,'Unit',cType.EMPTY_CHAR);
            for i=1:N
                fields(i)=struct('Name',obj.FieldNames{i+1},...
                     'Format',obj.Format{i+1},...
                     'Unit',obj.Unit{i+1});
            end
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Fields',fields,'Data',data);
        end
		
        function res=isNumericColumn(obj,idx)
        % isNumericColumn - Determine if the column 'idx' is numeric. Internal use
        % Syntax:
        %   res=obj.isNumerisColumn(idx)
        % Input Argument:
        %   idx - Column number
        % Output Argument:
        %   res - true | false
            res=(idx>0) && (idx<obj.NrOfCols);
            res= res && ismember('f',obj.Format{idx+1});
        end

        function res=getDescriptionLabel(obj)
        % getDescriptionLabel - Get the description of the table
        %   It is used in printTable and graphs
        %   Include table 'Description' 'State' and Sample
        % Syntax:
        %   res = obj.getDescriptionLabel
        % Output Argument:
        %   res - char array containg the table description 
        %     and the state of the table values
        % 
            if obj.Resources
                res=horzcat(obj.Description,' - [',obj.State,'/',obj.Sample,']');
            else
                res=horzcat(obj.Description,' - ',obj.State);
            end
        end

        function printTable(obj,fId)
        % printTable - Print table on console or in a file in a pretty formatted way
        % Syntax:
        %   obj.printTable(fid)
        % Input Argument:
        %   fId - optional parameter 
        %     If not provided, table is show in console
        %     If provided, table is writen to a file identified by fId
        % See also fopen
            if ~obj.status
                printLogger(obj)
                return
            end
            if nargin==1
                fId=1;
            end
            wcol=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            hfmt=arrayfun(@(x) ['%-',num2str(x),'s'],wcol,'UniformOutput',false);
            sfmt=hfmt;
            for j=2:obj.NrOfCols
                if fcol(j)==cType.ColumnFormat.NUMERIC
                    hfmt{j}=[' %',num2str(wcol(j)),'s'];
                    sfmt{j}=[' ',obj.Format{j}];
                end
            end
            % Determine output depending of table definition
            if obj.ShowNumber
                sfmt0=[' ',cType.FORMAT_ID,' '];
                tmp=regexp(sfmt0,'[0-9]+','match');
                hfmt0=[' %',tmp{1},'s '];
                hformat=[hfmt0, hfmt{:}];
                sformat=[sfmt0, sfmt{:}, '\n'];
                header=sprintf(hformat,'Id',obj.ColNames{:});
                data=[num2cell(1:obj.NrOfRows)' obj.Values(2:end,:)];
           else
                hformat=[hfmt{:}];
                sformat=[sfmt{:},'\n'];
                header=sprintf(hformat,obj.ColNames{:});
                data=obj.Values(2:end,:);
            end
            % Print formatted table   
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',header);
            lines=cType.getLine(length(header)+1);
            fprintf(fId,'%s\n',lines);
            arrayfun(@(i) fprintf(fId,sformat,data{i,:}),1:obj.NrOfRows);
            fprintf(fId,'\n');
        end

        function res=getColumnValues(obj,key)
        % getColumnValues - Get the values of a specfic column
        % Syntax:
        %   res=obj.getColumnValues(key)
        % Input Argument:
        %   key - Name of the column identified by property 'FieldName'
        % Output Argument
        %   res - Values of the column
        %     If column is a string then res is a cell array
        %     If column is numeric then res is a numeric array
        %
            res=cType.EMPTY;
            [~,idx]=ismember(key,obj.FieldNames);
            if ~idx
                return
            end
            tmp=obj.Values(2:end,idx);
            cf=getColumnFormat(obj);
            switch cf(idx)
            case cType.ColumnFormat.CHAR
                res=tmp;
            case cType.ColumnFormat.NUMERIC
                res=cell2mat(tmp);
            end
        end
    end

    methods(Access=private)
        function setProperties(obj,p)
        %setProperties - set the additional properties of the table
        %   Syntax:
        %     setProperties(obj,p)
        %   Input Arguments:
        %     p - struct with the cTableCell properties
        %
            list=cType.TableCellProps;
            for i = 1:numel(list)
                fname = list{i};
                if isfield(p, fname)
                    obj.(fname) = p.(fname);
                end
            end
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function setColumnWidth(obj)
        % define the width of the columns
            M=obj.NrOfCols;
            res=zeros(1,M);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=2:M
                if isNumericColumn(obj,j-1)
                    tmp=regexp(obj.Format{j},'[0-9]+','match','once');
                    res(j)=str2double(tmp);
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
            obj.wcol=res;
        end

        function setColumnFormat(obj)
        % Define the format of each column (TEXT or NUMERIC)
            tmp=arrayfun(@(x) isNumericColumn(obj,x),1:obj.NrOfCols-1)+1;
            obj.fcol=[cType.ColumnFormat.CHAR,tmp];
        end
    end
end
