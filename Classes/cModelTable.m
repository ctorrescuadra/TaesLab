classdef cModelTable < cMessageLogger
%cModelTable - Class container for the values read by cReadModelTable
%   This class validate and store the data model values
%   The table definition is provided by a struct with the table properties
%   as read by cReadModelTables from the file printconfig.json.
%   The table data is provided by a cell array read by cReadModelTables
%   
%   cModelTable properties:
%     NrOfRows - Number of table rows
%     NrOfCols - Number of table columns
%     Values - Table data values
%     Fields - Fields of the table
%     Data   - Data of the table (without fields)
%     Keys   - Keys or row names of the table data
%     Name   - Name of the table
%   
%   cModelTable methods:
%     cModelTable  - Construct an instance of this class
%     getStructData - Get the values as struct
%     getTableData  - Get the values as cTable
%     printTable    - Print the table on console
%     size          - Size of the table model. Overload size method
%
%   See cReadModelTables, printconfig.json
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
        %cModelTable - Construct an instance of this class
        %   Validate the table data and store the values
        %
        %   Syntax:
        %     obj = cModelTable(table,props)
        %   Input Arguments:
        %     table - cell array with the table data
        %     props - struct with the data model definition
        %   Output Arguments:
        %     obj   - cModelTable object

            % Check Input
            if ~iscell(vals) || ~isstruct(props)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessage.ShowHelp);
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
        %getStructData - Get a struct with the table values
        %   Syntax:
        %     res = obj.getStructData();
        %   Output parameter:
        %     res - struct with the columns data
        %
                res=cell2struct(obj.Data,obj.Fields,2);
        end

        function res=getTableData(obj)
        %getTableData - Get a cTable with the table model info.
        %   Syntax:
        %     res = obj.getTableData
        %   Output parameter:
        %     res - cTable object
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
        %validateTable - Check the table values
        %   Syntax:
        %     log = obj.validateTable(p)
        %   Output Arguments:
        %     log - cMessageLog with the validation status and error messages
        
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
        %checkValues - Check if the values have missing values
        %   Syntax:
        %     tst = cModelTable.checkMissingValues(log,table,values)
        %   Input Arguments:
        %     log    - cMessageLogger to log errors 
        %     table  - Name of the table (char array)
        %     values - Values to check
        %   Output Arguments:
        %     tst - true | false
        %
            tst=true;
            %Search columns with missing cells
            if isOctave
                idx=all(cellfun(@isempty,values));
            else %isMatlab
                idx=all(cellfun(@(x) isa(x,'missing') || isempty(x),values));
            end
            % Log error
            if any(idx)
                tst=false;
                for i=find(idx)
                    obj.messageLog(cType.ERROR,cMessages.InvalidFieldNumber,i,obj.config.name);
                end
            end
        end
    end

    methods(Static,Access=private)
        function tst=validateKey(log,data)
        %validateKey - Validate key data
        %   Syntax:
        %     test = cModelTable.validateKey(log,data)
        %   Input Arguments:
        %     log   - logger to store messages
        %     data  - field data
        %   Output Arguments:
        %     tst - true | false

            %Check if the keys has the correct pattern
            ier=cParseStream.checkListKeys(data);
            if ~isempty(ier)
                for i=ier
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
        %validateNumeric - Validate numeric data
        %   Syntax:
        %     test = cModelTable.validateNumeric(data)
        %   Input Arguments:
        %     data  - field data
        %   Output Arguments:
        %     tst - true | false
        %
            tst=false;
            % Check if data column is numeric
            idx=cellfun(@isnumeric,data);
            if ~all(idx)
                return
            end
            % Check if values are non-negative
            tst=all(cell2mat(data) >- cType.EPS);
        end

        function tst=validateSample(log,data)
        %validateSample - Validate numeric data block
        %   Syntax:
        %     test = cModelTable.validateSample(log,data)
        %   Input Arguments:
        %     data  - field data
        %     log   - logger to store messages
        %   Output Arguments:
        %     tst - true | false
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
            tst = tst & all(A(:) > -cType.EPS);
        end
    end
end