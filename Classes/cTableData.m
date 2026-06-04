classdef cTableData < cTable
%cTableData - Concrete cTable subclass for data model tables.
%   cTableData stores and presents input data tables (flows, processes, exergy
%   states, etc.) that are read from data model files. It is derived from cTable
%   and adds column-format detection, column-width calculation, and a
%   formatted console/file printer.
%
%   Unlike cTableResult subclasses, cTableData does not carry thermoeconomic
%   result metadata (Format, Unit, NodeType). Its State property is always set
%   to the literal string 'DATA'.
%
%   cTableData properties (inherited from cTable):
%     Data        - Cell array with the table data
%     Values      - Cell array with data including row and column names
%     RowNames    - Cell array with row key names
%     ColNames    - Cell array with column names
%     NrOfRows    - Number of data rows
%     NrOfCols    - Number of columns (including row-name column)
%     Name        - Table identifier name
%     Description - Table header or description text
%     State       - Always 'DATA' for this class
%     Sample      - Resource cost sample name
%     Resources   - True if the table contains resource cost information
%     GraphType   - Graph type associated with the table (see cType.GraphType)
%
%   cTableData methods:
%     cTableData         - Constructor
%     create             - Create a cTableData from a cell array (static)
%     import             - Create a cTableData from a CSV or JSON file (static)
%     importMatlabTable  - Create a cTableData from a MATLAB table object (static)
%     getStructTable     - Return table data as a struct
%     printTable         - Print the table to the console or a file
%     formatData         - Return data with numeric columns right-justified as strings
%     getDescriptionLabel - Return the description text used as table heading
%
%   cTableData methods (inherited from cTable):
%     exportTable     - Export table in different variable formats
%     getStructData   - Return table data as a struct array
%     getMatlabTable  - Return table as a MATLAB table object (MATLAB only)
%     getColumnValues - Return the values of a data column
%     getColumnData   - Return a key/value struct array for a data column
%     getColumnWidth  - Return the display width of each column
%     getColumnFormat - Return the format code of each column (see cType.ColumnFormat)
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
%   See also cTable, cTableCell, cTableMatrix
%
    methods
        function obj = cTableData(data,rowNames,colNames,props)
        %cTableData - Construct an instance of this class
        %   Syntax:
        %     obj = cTableData(data,rowNames,colNames,props)
        %   Input Arguments:
        %     data     - cell array containing the table data (NrOfRows x NrOfCols-1)
        %     rowNames - cell array with the row key names
        %     colNames - cell array with the column names (first entry is the row-key header)
        %     props    - struct with additional table properties
        %       Name        - table identifier name
        %       Description - table header or description text
        %   Output Arguments:
        %     obj - cTableData object
        
            % Check input arguments
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
            % Set the properties
            obj.Data=data;
            obj.NrOfCols=length(obj.ColNames);
            obj.NrOfRows=length(obj.RowNames);
            obj.State='DATA';
            if obj.checkTableSize
                obj.setProperties(props)
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end

        function res=getStructTable(obj)
        %getStructTable - Return table information as a struct
        %   Overrides cTable.getStructTable.
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with fields:
        %       Name        - table identifier name
        %       Description - table description text
        %       State       - state label ('DATA')
        %       Data        - table data as a struct array (see getStructData)
        %
            data=obj.getStructData;
            res=struct('Name',obj.Name,'Description',obj.Description,...
                'State',obj.State,'Data',data);
        end

        function res=formatData(obj)
        %formatData - Return data with numeric columns converted to right-justified strings
        %   Non-numeric columns are returned unchanged. Numeric values are converted
        %   with num2str and then right-padded to the column width.
        %   Syntax:
        %     res = obj.formatData()
        %   Output Arguments:
        %     res - cell array (NrOfRows x NrOfCols-1) with formatted data values
        %
            res=obj.Data;
            cw=obj.getColumnWidth;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j+1)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    fmt=['%',num2str(cw(j+1)),'s'];
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),data,'UniformOutput',false);
                end
            end
        end

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Return the description text used as the table heading
        %   Called by printTable to obtain the line printed above the column headers.
        %   Syntax:
        %     res = obj.getDescriptionLabel()
        %   Output Arguments:
        %     res - char array with the table Description
        %
            res=obj.Description;
        end

        function printTable(obj,fid)
        %printTable - Print the table in a formatted layout to the console or a file
        %   Left-aligns text columns and right-aligns numeric columns. Prints the
        %   description as a heading followed by a separator line.
        %   Syntax:
        %     obj.printTable(fid)
        %   Input Arguments:
        %     fid - (optional) file identifier returned by fopen.
        %           If omitted, output goes to the console (stdout, fid=1).
        %   See also fopen
        %
            if nargin==1
                fid=1;
            end
            fdata=obj.formatData;
            wc=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            for j=2:obj.NrOfCols
                if fcol(j)==cType.ColumnFormat.NUMERIC
                    lfmt{j}=['%',num2str(wc(j)),'s '];
                end
            end
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s\n',obj.getDescriptionLabel);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            arrayfun(@(i) fprintf(fid,lformat,obj.RowNames{i},fdata{i,:}),1:obj.NrOfRows);
            fprintf(fid,'\n');
        end
    end

    methods(Access=private)
        function setProperties(obj,p)
        %setProperties - Set Name and Description and initialise column format and width
        %   Syntax:
        %     obj.setProperties(p)
        %   Input Arguments:
        %     p - struct with fields Name and Description
        %
            obj.Name=p.Name;
            obj.Description=p.Description;
            obj.setColumnFormat;
            obj.setColumnWidth;
        end

        function setColumnFormat(obj)
        %setColumnFormat - Detect and store the format code of each column
        %   Sets the protected property fcol. A column is NUMERIC (2) if every
        %   data cell is numeric; otherwise it is TEXT (1).
        %   Syntax:
        %     obj.setColumnFormat
        %   See also cType.ColumnFormat
        %
            tmp=cellfun(@isnumeric,obj.Values(2:end,:));
            if isrow(tmp)
                obj.fcol=tmp+1;
            else
                obj.fcol=all(tmp)+1;
            end
        end

        function setColumnWidth(obj)
        %setColumnWidth - Compute and store the display width of each column
        %   Sets the protected property wcol. For numeric columns the width is
        %   the maximum of the formatted value length, the header length and
        %   cType.DEFAULT_NUM_LENGHT, plus one. For text columns it is the
        %   maximum string length across all cells (header included) plus two.
        %   Syntax:
        %     obj.setColumnWidth
            res=zeros(1,obj.NrOfCols);
            for j=1:obj.NrOfCols
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Values(2:end,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    res(j)=cw+1;
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
            obj.wcol=res;
        end
    end
    
    methods (Static,Access=public)
        function tbl=create(values,props)
        %create - Create a cTableData from a cell array of values
        %   Syntax:
        %     tbl = cTableData.create(values,props)
        %   Input Arguments:
        %     values - cell array where the first row contains column names and
        %              the first column contains row key names; must have at
        %              least 2 rows and 2 columns
        %     props  - struct with table properties
        %       Name        - table identifier name
        %       Description - table description text
        %   Output Arguments:
        %     tbl - cTableData object, or a cMessageLogger with error status if
        %           the input is invalid
        %
            tbl=cMessageLogger(cType.INVALID);
            if all(size(values)>1)   
                rowNames=values(2:end,1);
                colNames=values(1,:);
                data=values(2:end,2:end);
                tbl=cTableData(data,rowNames',colNames,props);
            else
                tbl.messageLog(cType.ERROR,cMessages.NoValuesAvailable);
            end
        end

        function tbl=import(filename,props)
        %import - Create a cTableData by reading a CSV or JSON file
        %   For CSV files: the first row must contain column names and the first
        %   column must contain row key names.
        %   For JSON files: the file must decode to a struct array where field
        %   names are column names and values are the data.
        %   Syntax:
        %     tbl = cTableData.import(filename,props)
        %   Input Arguments:
        %     filename - path to the file to import (CSV or JSON)
        %     props    - struct with table properties
        %       Name        - table identifier name
        %       Description - table description text
        %   Output Arguments:
        %     tbl - cTableData object, or a cMessageLogger with error status if
        %           the file cannot be read or has an unsupported format
        %
            tbl=cMessageLogger();
            % Validate filename
            if ~isFilename(filename)
                tbl.messageLog(cType.ERROR,cMessages.InvalidFileName)
                return
            end
            % Determine file type and import data
            [fileType,fileExt]=cType.getFileType(filename);
            switch fileType
                case cType.FileType.CSV
                    values=importCSV(filename);
                case cType.FileType.JSON
                    S=importJSON(tbl,filename);
                    if ~empty(S) && isstruct(S)
                        values=[fieldnames(S)'; struct2cell(S)'];
                    else
                        tbl.messageLog(cType.ERROR,cMessages.InvalidInputFile,filename);
                        return
                    end
                otherwise
                    tbl.messageLog(cType.ERROR,cMessages.InvalidFileExt,upper(fileExt));
                    return
            end
            % Create cTableData object
            tbl=cTableData.create(values,props);
        end

        function obj=importMatlabTable(T)
        %importMatlabTable - Create a cTableData from a MATLAB table object
        %   Not supported on Octave. If the MATLAB table has RowNames they are
        %   used as row keys; otherwise the first variable is used as row keys.
        %   The table's UserData property is mapped to Name and Description to
        %   Description.
        %   Syntax:
        %     obj = cTableData.importMatlabTable(T)
        %   Input Arguments:
        %     T   - MATLAB table object (must have at least 2 rows and 2 columns)
        %   Output Arguments:
        %     obj - cTableData object, or a cMessageLogger with error status if
        %           the input is invalid or the platform is Octave
        %
            obj=cMessageLogger();
            % Check Input Arguments 
            if nargin < 1 || isOctave || isempty(T) || ~istable(T)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Check the size of the table
            if any(size(T)<2)   
                obj.messageLog(cType.ERROR,cMessages.NoValuesAvailable);
                return
            end
            % Build the cTableData from table info
            try
                colNames = T.Properties.VariableNames;
                if ~isempty(T.Properties.RowNames)
                    rowNames = T.Properties.RowNames';
                    data=table2cell(T);
                else
                    values=table2cell(T);
                    rowNames = values(:,1);
                    data=values(:,2:end);
                end
                % Set cTable properties
                if ~isempty(T.Properties.UserData)      
                    props.Name = T.Properties.UserData;
                else
                    props.Name = 'NoName';
                end
                if ~isempty(T.Properties.Description)
                    props.Description = T.Properties.Description;
                else
                    props.Description = 'No Description';
                end
            catch err
                obj.messageLog(cType.ERROR, err.message);
                obj.messageLog(cType.ERROR, cMessages.InvalidTableValues);
                return
            end
            props.Description=horzcat(props.Name,' - ',props.Description);
            obj = cTableData(data,rowNames,colNames,props);
        end
    end
end