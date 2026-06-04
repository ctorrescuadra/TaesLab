classdef (Sealed) cTableCell < cTableResult
%cTableCell - Concrete cTableResult subclass for mixed-type result tables.
%   cTableCell stores thermoeconomic result tables that contain a mix of text
%   and numeric columns (e.g. process descriptions combined with efficiency or
%   cost values). It is derived from cTableResult and adds per-column data-type
%   tracking, field-name aliases, and an optional row-number column.
%
%   Column formatting is driven by the Format cell array: columns whose format
%   string contains 'f' are treated as numeric and formatted with sprintf;
%   all other columns are treated as text.
%
%   cTableCell properties:
%     DataType   - Numeric array with the data type code of each column (see cType.Format)
%     FieldNames - Cell array of field name aliases for each column (including row-name column)
%     ShowNumber - True to print a leading row-number column in printTable
%
%   cTableCell properties (inherited from cTableResult):
%     Format   - Format string array for each column (1 x NrOfCols cell array)
%     Unit     - Unit label array for each column (1 x NrOfCols cell array)
%     NodeType - Row key node type (see cType.NodeType)
%
%   cTableCell properties (inherited from cTable):
%     Data        - Cell array with the table data (NrOfRows x NrOfCols-1)
%     Values      - Full table cell array: ColNames prepended, RowNames in col 1
%     RowNames    - Row key names (1 x NrOfRows cell array)
%     ColNames    - Column names  (1 x NrOfCols cell array)
%     NrOfRows    - Number of data rows
%     NrOfCols    - Number of columns (including the row-name column)
%     Name        - Table identifier name
%     Description - Table header or description text
%     State       - Thermodynamic state name associated with the data
%     Sample      - Resource cost sample name
%     Resources   - True if the table contains resource cost information
%     GraphType   - Graph type associated with the table (see cType.GraphType)
%
%   cTableCell methods:
%     cTableCell          - Constructor
%     formatData          - Return data with numeric columns formatted as strings
%     getMatlabTable      - Return table as a MATLAB table object with units and formats
%     getStructData       - Return table data as a struct array, optionally formatted
%     getStructTable      - Return table data and column metadata as a struct
%     getDescriptionLabel - Return the heading string used by printTable and graphs
%     getColumnValues     - Return the values of a column identified by its FieldName
%     printTable          - Print the table to the console or a file
%
%   cTableCell methods (inherited from cTableResult):
%     exportTable   - Export table in different variable formats
%     getCellData   - Return table values as a cell array, optionally formatted
%     getProperties - Return a struct with the result-specific table properties
%
%   cTableCell methods (inherited from cTable):
%     getStructData   - Return table data as a struct array (overridden here)
%     getMatlabTable  - Return table as a MATLAB table object (overridden here)
%     getColumnWidth  - Return the display width of each column
%     getColumnFormat - Return the format code of each column (see cType.ColumnFormat)
%     getColumnData   - Return a key/value struct array for a data column
%     setColumnValues - Replace the values of one or more data columns
%     setRowValues    - Replace the values of one or more data rows
%     setStudyCase    - Set the State and Sample identifiers
%     setDescription  - Set the table description text
%     isNumericColumn - True if the specified column contains numeric data
%     isNumericTable  - True if all data columns are numeric
%     isGraph         - True if a graph type is associated with the table
%     showTable       - Display the table (console, GUI or HTML)
%     saveTable       - Save the table to a file (CSV, XLSX, JSON, XML, TXT, HTML, LaTeX, MD)
%
%   See also cTableResult, cTable, cTableMatrix
%
    properties (GetAccess=public,SetAccess=private)
        DataType    % Numeric array with the data type code of each column (see cType.Format)
        FieldNames  % Field name aliases for each column, including the row-name column
        ShowNumber  % True to print a leading row-number column in printTable
    end
	
    methods
        function obj=cTableCell(data,rowNames,colNames,props)
        %cTableCell - Construct an instance of this class
        %   Syntax:
        %     obj = cTableCell(data,rowNames,colNames,props)
        %   Input Arguments:
        %     data     - cell array with the table data (NrOfRows x NrOfCols-1)
        %     rowNames - cell array with the row key names
        %     colNames - cell array with the column names (first entry is the row-key header)
        %     props    - struct with additional table properties:
        %       Name        - table identifier name
        %       Description - table header or description text
        %       DataType    - numeric array with the data type code of each column
        %       Unit        - cell array with the unit label of each column
        %       Format      - cell array with the sprintf format string of each column
        %       GraphType   - graph type associated with the table (see cType.GraphType)
        %       FieldNames  - cell array with field name aliases for each column
        %       ShowNumber  - true to print a leading row-number column
        %       NodeType    - row key node type (see cType.NodeType)
        %   Output Arguments:
        %     obj - cTableCell object
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
        %formatData - Return data with numeric columns formatted as strings
        %   Columns whose Format string contains 'f' are formatted with sprintf;
        %   all other columns are returned unchanged.
        %   Syntax:
        %     res = obj.formatData
        %   Output Arguments:
        %     res - cell array (NrOfRows x NrOfCols-1) with formatted data values
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
        %getMatlabTable - Return table as a MATLAB table object with units and formats
        %   Extends cTable.getMatlabTable by adding VariableUnits, VariableDescriptions,
        %   Format and ShowNumber as table properties. Not supported on Octave.
        %   Syntax:
        %     res = obj.getMatlabTable
        %   Output Arguments:
        %     res - MATLAB table object, or the cTableCell object itself on Octave
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
        %getStructData - Return table data as a struct array
        %   Overrides cTable.getStructData to use FieldNames as struct field names
        %   and to support optional column formatting.
        %   Syntax:
        %     res = obj.getStructData(fmt)
        %   Input Arguments:
        %     fmt - (optional) true to apply column formatting to numeric values;
        %           false (default) to return raw values
        %   Output Arguments:
        %     res - struct array (NrOfRows x 1) where field names are taken from FieldNames
        %
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
        %getStructTable - Return table data and column metadata as a struct
        %   Overrides cTable.getStructTable to include per-column metadata
        %   (FieldName, Format, Unit) in addition to the data rows.
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with fields:
        %       Name        - table identifier name
        %       Description - table description text
        %       State       - state label
        %       Fields      - struct array (1 x NrOfCols-1) with Name, Format, Unit per column
        %       Data        - table data as a struct array (see getStructData)
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

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Return the heading string used by printTable and graphs
        %   For resource-cost tables the format is 'Description - [State/Sample]'.
        %   For other tables the format is 'Description - State'.
        %   Syntax:
        %     res = obj.getDescriptionLabel
        %   Output Arguments:
        %     res - char array with the formatted table heading
        %
            if obj.Resources
                res=horzcat(obj.Description,' - [',obj.State,'/',obj.Sample,']');
            else
                res=horzcat(obj.Description,' - ',obj.State);
            end
        end

        function printTable(obj,fId)
        %printTable - Print the table in a formatted layout to the console or a file
        %   Text columns are left-aligned; numeric columns use the column Format string.
        %   When ShowNumber is true a leading 'Id' column with 1-based row numbers is printed.
        %   Syntax:
        %     obj.printTable(fId)
        %   Input Arguments:
        %     fId - (optional) file identifier returned by fopen.
        %           If omitted, output goes to the console (stdout, fId=1).
        %   See also fopen
        %
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
        %getColumnValues - Return the values of a column identified by its FieldName
        %   Overrides cTable.getColumnValues to look up the column by field name
        %   rather than by index.
        %   Syntax:
        %     res = obj.getColumnValues(key)
        %   Input Arguments:
        %     key - char array matching an entry in FieldNames
        %   Output Arguments:
        %     res - numeric array if the column is numeric; cell array if text;
        %           cType.EMPTY if key is not found
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
        %setProperties - Set all additional properties from the props struct
        %   Copies each field listed in cType.TableCellProps from p into the
        %   corresponding object property, then initialises fcol and wcol.
        %   Syntax:
        %     obj.setProperties(p)
        %   Input Arguments:
        %     p - struct with cTableCell property fields (see constructor)
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

        function setColumnFormat(obj)
        %setColumnFormat - Compute and store the format code of each column
        %   Sets the protected property fcol. The code is NUMERIC (2) for columns
        %   whose DataType exceeds cType.Format.TEXT; TEXT (1) otherwise.
        %   Syntax:
        %     obj.setColumnFormat
        %   See also cType.ColumnFormat, cType.Format
        %
            obj.fcol=(obj.DataType>cType.Format.TEXT)+1;
        end

        function setColumnWidth(obj)
        %setColumnWidth - Compute and store the display width of each column
        %   Sets the protected property wcol. For numeric columns the width is
        %   extracted from the Format string (first integer token). For text
        %   columns it is the maximum string length across all cells plus two.
        %   Syntax:
        %     obj.setColumnWidth
        %
            M=obj.NrOfCols;
            res=zeros(1,M);
            for j=1:M
                if isNumericColumn(obj,j)
                    tmp=regexp(obj.Format{j},'[0-9]+','match','once');
                    res(j)=str2double(tmp);
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
            obj.wcol=res;
        end
    end
end
