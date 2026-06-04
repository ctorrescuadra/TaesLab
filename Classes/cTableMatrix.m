classdef (Sealed) cTableMatrix < cTableResult
%cTableMatrix - Concrete cTableResult subclass for matrix-structured result tables.
%   cTableMatrix stores thermoeconomic result tables whose data forms a numeric
%   matrix (e.g. flow-process adjacency tables, cost-allocation matrices, FP
%   tables, diagnosis matrices). It is derived from cTableResult and adds
%   optional row/column total rows, a single shared Format string for all data
%   cells, and a GraphOptions bitmask used by the graph layer.
%
%   Row and column totals are appended during construction when the corresponding
%   props flags are set. All data cells are stored as numeric values and
%   formatted uniformly using the Format string.
%
%   cTableMatrix properties:
%     SummaryType  - Summary type tag used by getDescriptionLabel (see cType)
%     GraphOptions - Bitmask controlling graph behaviour (see is* query methods)
%     RowTotal     - True if a 'Total' row was appended during construction
%     ColTotal     - True if a 'Total' column was appended during construction
%
%   cTableMatrix properties (inherited from cTableResult):
%     Format   - sprintf format string shared by all data columns
%     Unit     - Unit label for the data values
%     NodeType - Row key node type (see cType.NodeType)
%
%   cTableMatrix properties (inherited from cTable):
%     Data        - Cell array with the table data (NrOfRows x NrOfCols-1)
%     Values      - Full table cell array: ColNames prepended, RowNames in col 1
%     RowNames    - Row key names (1 x NrOfRows cell array)
%     ColNames    - Column names  (1 x NrOfCols cell array)
%     NrOfRows    - Number of data rows (including Total row if present)
%     NrOfCols    - Number of columns (including row-name column and Total column if present)
%     Name        - Table identifier name
%     Description - Table header or description text
%     State       - Thermodynamic state name associated with the data
%     Sample      - Resource cost sample name
%     Resources   - True if the table contains resource cost information
%     GraphType   - Graph type associated with the table (see cType.GraphType)
%
%   cTableMatrix methods:
%     cTableMatrix           - Constructor
%     getMatrixValues        - Return table data as a numeric matrix
%     formatData             - Return data formatted with the shared Format string
%     getStructData          - Return table data as a struct array, optionally formatted
%     getMatlabTable         - Return table as a MATLAB table object with extra properties
%     getStructTable         - Return table data and metadata as a struct
%     getDescriptionLabel    - Return the heading string used by printTable and graphs
%     printTable             - Print the table to the console or a file
%     isUnitCostTable        - True if GraphOptions bit 1 is set (unit cost table)
%     isFlowsTable           - True if GraphOptions bit 2 is set (flows table)
%     isGeneralCostTable     - True if GraphOptions bit 3 is set (general cost table)
%     isSummaryTable         - True if GraphOptions bit 4 is set (summary table)
%     isResourceCostTable    - True if GraphOptions bit 5 is set (resource cost table)
%     isTotalMalfunctionCost - True if GraphOptions bit 6 is set (total malfunction cost table)
%
%   cTableMatrix methods (inherited from cTableResult):
%     exportTable   - Export table in different variable formats
%     getCellData   - Return table values as a cell array, optionally formatted
%     getProperties - Return a struct with the result-specific table properties
%
%   cTableMatrix methods (inherited from cTable):
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
%   See also cTableResult, cTable, cTableCell, cGraphResults
%
    properties (GetAccess=public,SetAccess=private)
        SummaryType     % Summary type tag used by getDescriptionLabel (see cType)
        GraphOptions    % Bitmask controlling graph behaviour (see is* query methods)
        RowTotal        % True if a 'Total' row was appended during construction
        ColTotal        % True if a 'Total' column was appended during construction
    end

    methods
        function obj=cTableMatrix(data,rowNames,colNames,props)
        %cTableMatrix - Construct an instance of this class
        %   When props.RowTotal is true a 'Total' row containing column sums is
        %   appended. When props.ColTotal is true a 'Total' column containing row
        %   sums is appended. The intersection cell (Total/Total) is set to zero.
        %   Syntax:
        %     obj = cTableMatrix(data,rowNames,colNames,props)
        %   Input Arguments:
        %     data     - numeric matrix with the table data (NrOfRows x NrOfCols-1)
        %     rowNames - cell array with the row key names
        %     colNames - cell array with the column names (first entry is the row-key header)
        %     props    - struct with additional table properties:
        %       Name        - table identifier name
        %       Description - table header or description text
        %       Unit        - unit label for the data values
        %       Format      - sprintf format string shared by all data columns
        %       GraphType   - graph type associated with the table (see cType.GraphType)
        %       GraphOptions - bitmask for graph behaviour flags
        %       SummaryType  - summary type tag (see cType)
        %       RowTotal    - true to append a column-sum 'Total' row
        %       ColTotal    - true to append a row-sum 'Total' column
        %       NodeType    - row key node type (see cType.NodeType)
        %   Output Arguments:
        %     obj - cTableMatrix object
        %
            % Compute Totals if is required          
            if props.RowTotal
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if props.ColTotal
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            if props.ColTotal && props.RowTotal
                data(end,end)=0.0;
            end
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
            obj.Data=num2cell(zerotol(data));
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            if obj.checkTableSize
                obj.setProperties(props);
            else
                obj.messageLog(cType.ERROR,cMessages.InvalidTableSize,size(data));
            end
        end
        
        function res=getMatrixValues(obj)
        %getMatrixValues - Return table data as a numeric matrix
        %   Syntax:
        %     res = obj.getMatrixValues
        %   Output Arguments:
        %     res - numeric array (NrOfRows x NrOfCols-1) with the data values
        %
            res=cell2mat(obj.Data);
        end

        function res=formatData(obj)
        %formatData - Return data formatted with the shared Format string
        %   Applies sprintf(obj.Format, x) to every data cell.
        %   Syntax:
        %     res = obj.formatData
        %   Output Arguments:
        %     res - cell array (NrOfRows x NrOfCols-1) of formatted strings
        %
            res=cellfun(@(x) sprintf(obj.Format,x),obj.Data,'UniformOutput',false);
        end

        function res=getStructData(obj,fmt)
        %getStructData - Return table data as a struct array
        %   Overrides cTable.getStructData to support optional column formatting.
        %   Syntax:
        %     res = obj.getStructData(fmt)
        %   Input Arguments:
        %     fmt - (optional) true to apply the shared Format string to numeric values;
        %           false (default) to return raw values
        %   Output Arguments:
        %     res - struct array (NrOfRows x 1) where field names are taken from ColNames
        %
            if nargin==1
                fmt=false;
            end
            if fmt
                val=[obj.RowNames',obj.formatData];
            else
                val=[obj.RowNames',obj.Data];
            end
            res=cell2struct(val,obj.ColNames,2);
        end

        function res=getMatlabTable(obj)
        %getMatlabTable - Return table as a MATLAB table object with extra properties
        %   Extends cTable.getMatlabTable by adding GraphOptions, Format and Units
        %   as custom table properties. Not supported on Octave.
        %   Syntax:
        %     res = obj.getMatlabTable
        %   Output Arguments:
        %     res - MATLAB table object, or the cTableMatrix object itself on Octave
        %
            res=getMatlabTable@cTable(obj);
            if isMatlab
                res=addprop(res,["GraphOptions","Format","Units"],...
                    ["table","table","table"]);
                res.Properties.CustomProperties.GraphOptions=obj.GraphOptions;
                res.Properties.CustomProperties.Format=obj.Format;
                res.Properties.CustomProperties.Units=obj.Unit;
            end
        end

        function res=getStructTable(obj)
        %getStructTable - Return table data and metadata as a struct
        %   Overrides cTable.getStructTable to include Unit and Format fields.
        %   Syntax:
        %     res = obj.getStructTable
        %   Output Arguments:
        %     res - struct with fields: Name, Description, State, Unit, Format, Data
        %           (Data is a struct array as returned by getStructData)
        %
            data=getStructData(obj);
            res=struct('Name',obj.Name,'Description',obj.Description,...
                    'State',obj.State,'Unit',obj.Unit,'Format',obj.Format,'Data',data);
        end

        function res=getDescriptionLabel(obj)
        %getDescriptionLabel - Return the heading string used by printTable and graphs
        %   Includes the description, unit and state/sample identifiers.
        %   For summary tables the State or Sample label is overridden with 'SUMMARY'.
        %   For resource-cost tables the format is 'Description Unit - [State/Sample]'.
        %   For other tables the format is 'Description Unit - State'.
        %   Syntax:
        %     res = obj.getDescriptionLabel
        %   Output Arguments:
        %     res - char array with the formatted table heading
        %
            switch obj.SummaryType
                case cType.STATES
                    obj.State='SUMMARY';
                case cType.RESOURCES
                    obj.Sample='SUMMARY';
            end
            if obj.Resources
                stc=horzcat('[',obj.State,'/',obj.Sample,']');
            else
                stc=obj.State;
            end
            res=horzcat(obj.Description,' ',obj.Unit,' - ',stc );
        end

        function printTable(obj,fId)
        %printTable - Print the table in a formatted layout to the console or a file
        %   All data columns use the shared Format string. The first column is
        %   left-aligned text; all data columns are right-aligned numeric.
        %   When RowTotal is true the last row is separated by a divider line and
        %   the Total/Total cell is left blank. If the table exceeds
        %   cType.MAX_PRINT_COLS columns a placeholder message is printed instead.
        %   Syntax:
        %     obj.printTable(fId)
        %   Input Arguments:
        %     fId - (optional) file identifier returned by fopen.
        %           If omitted, output goes to the console (stdout, fId=1).
        %   See also fopen
            if nargin==1
                fId=1;
            end
            if obj.NrOfCols > cType.MAX_PRINT_COLS
                fprintf(fId,'\n');
                fprintf(fId,'%s\n',obj.getDescriptionLabel);
                fprintf(fId,'\n');   
                fprintf(fId,'--- Table exceed number of columns to print --- \n');
                fprintf(fId,'\n');   
                return
            end
            nrows=obj.NrOfRows;
			ncols=obj.NrOfCols;
            wc=obj.getColumnWidth;
            % first column header size
            len=wc(1)+1;
            fkey=[' %-',num2str(len),'s'];
            % Rest of columns
            tmp=regexp(obj.Format,'[0-9]+','match','once');
            fval=['%',tmp,'s'];
            hformat=[fkey,repmat(fval,1,ncols-1)];
            sformat=[fkey,repmat(obj.Format,1,ncols-1),'\n'];
            % Print formatted table
            header=sprintf(hformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
			fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');       
			fprintf(fId,'%s\n',header);
            fprintf(fId,'%s\n',lines);
            arrayfun(@(i) fprintf(fId,sformat,obj.RowNames{i},obj.Data{i,:}),1:nrows-1);
            % Total summary by rows            
            if obj.RowTotal
                fprintf(fId,'%s\n',lines);
                tmp=obj.Data(end,:);
                if obj.ColTotal
                    tmp{end,end}=cType.EMPTY_CHAR;
                end
                fprintf(fId,sformat,obj.RowNames{end},tmp{:});       
            else
                fprintf(fId,sformat,obj.RowNames{end},obj.Data{end,:}); 
            end
            fprintf(fId,'\n');
        end
        %%%%
        % Graphic Interface functions
        %%%%
        function res = isUnitCostTable(obj)
        %isUnitCostTable - True if GraphOptions bit 1 is set (unit cost table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isUnitCostTable
        %   Output Arguments:
        %     res - logical scalar
        %
            res=bitget(obj.GraphOptions,1);
        end

        function res = isFlowsTable(obj)
        %isFlowsTable - True if GraphOptions bit 2 is set (flows table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isFlowsTable
        %   Output Arguments:
        %     res - logical scalar
        %
            res=bitget(obj.GraphOptions,2);
        end

        function res = isGeneralCostTable(obj)
        %isGeneralCostTable - True if GraphOptions bit 3 is set (general cost table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isGeneralCostTable
        %   Output Arguments:
        %     res - logical scalar
        %
            res=bitget(obj.GraphOptions,3);
        end

        function res=isSummaryTable(obj)
        %isSummaryTable - True if GraphOptions bit 4 is set (summary table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isSummaryTable
        %   Output Arguments:
        %     res - logical scalar
        %
            res=bitget(obj.GraphOptions,4);
        end

        function res=isResourceCostTable(obj)
        %isResourceCostTable - True if GraphOptions bit 5 is set (resource cost table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isResourceCostTable
        %   Output Arguments:
        %     res - logical scalar
            res=bitget(obj.GraphOptions,5);
        end

        function res = isTotalMalfunctionCost(obj)
        %isTotalMalfunctionCost - True if GraphOptions bit 6 is set (total malfunction cost table)
        %   Used by the graph layer to configure axis labels.
        %   Syntax:
        %     res = obj.isTotalMalfunctionCost
        %   Output Arguments:
        %     res - logical scalar
        %
            res=bitget(obj.GraphOptions,6);
        end
    end

    methods(Access=private)
        function setProperties(obj,p)
        %setProperties - Set all additional properties from the props struct
        %   Copies each field listed in cType.TableMatrixProps from p into the
        %   corresponding object property, then initialises fcol and wcol.
        %   Syntax:
        %     obj.setProperties(p)
        %   Input Arguments:
        %     p - struct with cTableMatrix property fields (see constructor)
        %
            list=cType.TableMatrixProps;
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
        %setColumnFormat - Store the format code of each column
        %   Sets the protected property fcol. The row-name column is TEXT (1);
        %   all data columns are NUMERIC (2).
        %   Syntax:
        %     obj.setColumnFormat
        %   See also cType.ColumnFormat
        %
            tmp=repmat(cType.ColumnFormat.NUMERIC,1,obj.NrOfCols-1);
            obj.fcol=[cType.ColumnFormat.CHAR,tmp];
        end
    
        function setColumnWidth(obj)
        %setColumnWidth - Compute and store the display width of each column
        %   Sets the protected property wcol. The row-name column width is the
        %   maximum key string length plus two. All data column widths are
        %   extracted from the first integer token in the Format string.
        %   Syntax:
        %     obj.setColumnWidth
        %
            lkey=max(cellfun(@length,obj.Values(:,1)))+2;
            tmp=regexp(obj.Format,'[0-9]+','match','once');
            lfmt=str2double(tmp);
            obj.wcol=[lkey,repmat(lfmt,1,obj.NrOfCols-1)];
        end
    end
end