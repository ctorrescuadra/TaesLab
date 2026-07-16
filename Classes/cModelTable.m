classdef (Sealed) cModelTable < cMessageLogger
%cModelTable - Validated container for a single data model table.
%   Stores and validates one table read by a cReadModelTable subclass.
%   The expected table layout (field names, data types, optional flag) is
%   supplied as a props struct derived from printformat.json. The raw
%   cell array is validated for missing values, correct field names, and
%   per-column data types (KEY, CHAR, NUMERIC, or SAMPLE blocks).
%
%   An object is invalid (isValid returns false) when required validation
%   steps fail; all errors are accumulated in the object logger.
%
%   cModelTable Properties:
%     NrOfRows - Number of data rows (excluding the header row)
%     NrOfCols - Number of columns
%     Values   - Full cell array including the header row
%     Fields   - Header row: column field names (cell row vector)
%     Data     - Data rows without the header (cell array)
%     Keys     - First column of Data: row identifier strings
%     Name     - Table name, from the props configuration struct
%
%   cModelTable Methods:
%     cModelTable   - Construct an instance and validate the raw cell array
%     getStructData - Return table data as a struct array
%     getTableData  - Return table data as a cTableData object
%     printTable    - Print the table on the console
%     size          - Return table dimensions (overloads built-in size)
%
%   See also cReadModelTable, cReadModelXLS, cReadModelCSV
%   
    properties(GetAccess=public,SetAccess=private)
        NrOfRows % Number of Rows
        NrOfCols % Number of Columns
        Values   % Values read from table data
        Fields   % Fields of the table
        Data     % Table Data
        Keys     % Data keys
        Name     % Table Name
    end

    properties(Access=private)
        config  % Tables properties
    end

    methods
        function obj=cModelTable(vals,props)
        %cModelTable - Construct an instance and validate the raw cell array.
        %   Validates that vals is a cell array and props is a struct with
        %   the required fields (id, name, optional, fields). Checks for
        %   missing values, verifies the column count, and runs per-column
        %   type validation. Errors are stored in the logger; check
        %   isValid(obj) after construction.
        %
        %   Syntax:
        %     obj = cModelTable(vals, props)
        %
        %   Input Arguments:
        %     vals  - Cell array with the raw table data. The first row
        %             must contain the field names (column headers); the
        %             remaining rows contain the data values.
        %     props - Struct with the table definition as loaded from
        %             printformat.json (fields: id, name, optional, fixed,
        %             fields array with name and datatype per column)
        %
        %   Output Arguments:
        %     obj   - cModelTable object

            % Check Input
            if ~iscell(vals) || ~isstruct(props)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessages.ShowHelp);
                return
            end
            if ~any(isfield(props,{'id','name','optional','fields'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            obj.config=props;
            % Check Missing Values
            if ~obj.checkMissingValues(vals)
                return
            end
            % Check number of fields
            N=numel(props.fields);
            if size(vals,2) < N
                obj.messageLog(cType.ERROR,cMessages.InvalidFieldNumber,size(vals,2),props.name);
                return
            end
            %Copy only mandatory fields
            if props.fixed               
                obj.Values=vals(:,1:N);
            else
                obj.Values=vals;
            end
            % Validate table fields
            log=obj.validateTable;
            if ~log.status
                obj.addLogger(log);
            end
        end

        function res=get.Fields(obj)
        %Get Fields property
            res = obj.Values(1,:);
        end

        function res=get.Data(obj)
        %Get Data property
            res = obj.Values(2:end,:);
        end

        function res=get.Keys(obj)
        %Get Keys property
            res = obj.Values(2:end,1);
        end

        function res=get.NrOfRows(obj)
        %Get number of rows
            res = length(obj.Keys);
        end

        function res=get.NrOfCols(obj)
        %Get number of cols
            res = length(obj.Fields);
        end

        function res=get.Name(obj)
        %Get table name
            res = obj.config.name;
        end

        function res=getStructData(obj)
        %getStructData - Return table data as a struct array.
        %   Converts the Data cell array to a struct array using the field
        %   names from the Fields header row. Each struct element corresponds
        %   to one data row.
        %
        %   Syntax:
        %     res = obj.getStructData()
        %
        %   Output Arguments:
        %     res - Struct array with one element per data row, with field
        %           names matching the table column headers.
        %
                res=cell2struct(obj.Data,obj.Fields,2);
        end

        function res=getTableData(obj)
        %getTableData - Return table data wrapped in a cTableData object.
        %   Creates a cTableData from the full Values cell array using the
        %   table name and description from the props configuration struct.
        %
        %   Syntax:
        %     res = obj.getTableData()
        %
        %   Output Arguments:
        %     res - cTableData object ready for display or export.
        %
        %   See also cTableData
        %
            p=struct('Name',obj.config.name,...
                'Description',obj.config.descr,...
                'State','DATA');
            res=cTableData.create(obj.Values,p);
            res.setStudyCase(p);
        end

        function printTable(obj)
        %printTable - Print data on console, using cTable interface.
        %   Syntax:
        %     printTable(obj)
        %
            printTable(getTableData(obj));
        end

        function res=size(obj,dim)
        %size - Size of the table model. Overload size method
        %   Syntax:
        %     res = obj.size
        %     res = obj.size(dim)
        %   Input Arguments:
        %     dim - Dimension to get the size (1 - rows, 2 - columns)
        %   Output Arguments:
        %     res - size of the table model
        %
            if nargin==1
                res=size(obj.Values);
            else
                res=size(obj.Values,dim);
            end
        end
    end

    methods(Access=private)
        function log=validateTable(obj)
        %validateTable - Validate field names and per-column data types.
        %   Iterates over the field definitions in the props config struct
        %   and checks each column against its declared datatype (KEY,
        %   CHAR, NUMERIC, or SAMPLE). Field name mismatches and type
        %   failures are logged to the returned logger.
        %
        %   Syntax:
        %     log = obj.validateTable()
        %
        %   Output Arguments:
        %     log - cMessageLogger containing any validation errors found.
        %           Check log.status to determine if all columns passed.
        %
            % Initilize variables            
            log=cMessageLogger();
            p=obj.config;
            % Check if the fields are chars
            idx=cellfun(@ischar,obj.Fields);
            if ~all(idx)
                ier=find(~idx);col=num2str(ier(1));
                obj.messageLog(cType.ERROR,cMessages.InvalidField,col,p.name);
                return
            end
            % Loop over the fields definition
            for i=1:numel(p.fields)
                dt=p.fields(i).datatype;
                fld=obj.Fields{i};
                pfld=p.fields(i).name;
                if ~strcmpi(fld,pfld) && (dt ~= cType.DataType.SAMPLE)
                    log.messageLog(cType.ERROR,cMessages.InvalidField,fld,p.name);
                    continue
                end
                colData=obj.Data(:,i);
                sampleData=obj.Values(:,i:end);
                % Validate each field depending on datatype
                switch dt
                    case cType.DataType.KEY
                        tst=cModelTable.validateKey(log,colData);
                    case cType.DataType.CHAR
                        tst=all(cellfun(@ischar,colData));
                    case cType.DataType.NUMERIC
                        tst=cModelTable.validateNumeric(colData);
                    case cType.DataType.SAMPLE
                        tst=cModelTable.validateSample(log,sampleData);
                end
                if ~tst
                    log.messageLog(cType.ERROR,cMessages.InvalidFieldDatatype,fld,p.name);
                    continue
                end
            end
        end

        function tst=checkMissingValues(obj,values)
        %checkMissingValues - Check whether the cell array contains missing values.
        %   Scans every column of values for empty cells or MATLAB missing
        %   values. Logs a MissingValues error for each affected column.
        %
        %   Syntax:
        %     tst = obj.checkMissingValues(values)
        %
        %   Input Arguments:
        %     values - Cell array of raw table data (including header row)
        %
        %   Output Arguments:
        %     tst - true when no missing values are found; false otherwise.
        %
            tst=true;
            %Search columns with missing cells
            if isOctave
                idx=any(cellfun(@isempty,values));
            else %isMatlab
                idx=any(cellfun(@(x) isa(x,'missing') || isempty(x),values));
            end
            % Log error
            if any(idx)
                tst=false;
                for i=find(idx)
                    obj.messageLog(cType.ERROR,cMessages.MissingValues,i,obj.config.name);
                end
            end
        end
    end

    methods(Static,Access=private)
        function tst=validateKey(log,data)
        %validateKey - Validate a KEY-type column.
        %   Checks that every entry in data matches the required key pattern
        %   and that no duplicates exist. Errors are logged to log.
        %
        %   Syntax:
        %     tst = cModelTable.validateKey(log, data)
        %
        %   Input Arguments:
        %     log  - cMessageLogger to receive error messages
        %     data - Cell column vector of key strings to validate
        %
        %   Output Arguments:
        %     tst  - true when all keys are valid and unique; false otherwise.
        %
        %   See also cParseStream.checkListKeys, cParseStream.checkDuplicates
        %

            %Check if the keys has the correct pattern
            ier=cParseStream.checkListKeys(data);
            if ~isempty(ier)
                for i=transpose(ier)
                    log.messageLog(cType.ERROR,cMessages.InvalidKey,data{i});
                end
            end
            %Check if the keys has duplicates
            ier=cParseStream.checkDuplicates(data);
            if ~isempty(ier)
                for i=ier
                    log.messageLog(cType.ERROR,cMessages.DuplicateKey,data{i});
                end
            end
            tst = isempty(ier);
        end

        function tst=validateNumeric(data)
        %validateNumeric - Validate a NUMERIC-type column.
        %   Checks that every cell in data is numeric and that all values
        %   are non-negative (within floating-point tolerance).
        %
        %   Syntax:
        %     tst = cModelTable.validateNumeric(data)
        %
        %   Input Arguments:
        %     data - Cell column vector expected to contain numeric scalars
        %
        %   Output Arguments:
        %     tst  - true when all values are numeric and non-negative;
        %            false otherwise.
        %
            tst=false;
            % Check if data column is numeric
            idx=cellfun(@isnumeric,data);
            if ~all(idx)
                return
            end
            % Check if values are non-negative
            x=cell2mat(data);
            tst=all(x >- tolerance(x));
        end

        function tst=validateSample(log,data)
        %validateSample - Validate a SAMPLE-type column block.
        %   Validates the header row of the sample block for valid and
        %   unique sample names, then checks that all data cells are
        %   numeric and non-negative. Errors are logged to log.
        %
        %   Syntax:
        %     tst = cModelTable.validateSample(log, data)
        %
        %   Input Arguments:
        %     log  - cMessageLogger to receive error messages
        %     data - Cell array spanning the full sample block, including
        %            the header row (sample names) and all data rows
        %
        %   Output Arguments:
        %     tst  - true when all sample names are valid and all data
        %            values are numeric and non-negative; false otherwise.
        %
        %   See also cParseStream.checkListNames, cParseStream.checkDuplicates
        %
            tst=true;
            % Check sample names
            samples=data(1,:);
            ier=cParseStream.checkListNames(samples);
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,cMessages.InvalidCaseName,samples{i});
                end
            end
            % Check duplicate names
            ier=cParseStream.checkDuplicates(samples);
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,cMessages.DuplicateCaseName,samples{i});
                end
            end
            % Check if the block data is numeric and non-negative
            try
                A=cell2mat(data(2:end,:));
            catch
                tst=false;
                return
            end
            reltol=tolerance(A);
            tst = tst & all(A(:) > -reltol);
        end
    end
end