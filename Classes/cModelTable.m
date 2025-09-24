classdef cModelTable < cMessageLogger
%cModelTable - Class container for the values read by cReadModelTable
%   This class validate and store the data model values
%
%   cModelTable constructor:
%     obj = cModelResults(table,props)
%
%   cModelTable properties:
%     Values - Table data values
%     Fields - Fields of the table
%     Data   - Data of the table (without fields)
%     Keys   - Keys or row names of the table data
%   
%   cModelTable methods:
%     getStructData   - Get the table values as struct
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
    end

    properties(Access=private)
        config  % Tables properties
    end

    methods
        function obj=cModelTable(table,props)
        %cModelTable - Construct an instance of this class
        %   Validate the table data
        %
        %   Syntax:
        %     obj = cModelTable(table,props)
        %   Input Arguments:
        %     table - cell array with the table data
        %     props - struct with the data model definition
        %
            % Check Input
            if ~iscell(table) || ~isstruct(props)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessage.ShowHelp);
                return
            end
            if ~any(isfield(props,{'id','name','optional','fields'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            % Validate Table
            obj.Values=table;
            obj.config=props;
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
            res = size(obj,1) - 1;
        end

        function res=get.NrOfCols(obj)
            res = size(obj,2);
        end

        function res=getStructData(obj)
        %getStructData - Get a struct with the table values
        %   Syntax:
        %     res = obj.getStructData();
        %   Output parameter:
        %     res - struct with the columns data
            res=cell2struct(obj.Data,obj.Fields,2);
        end

        function res=getTableData(obj)
            p=struct('Name',obj.config.name,...
                'Description',obj.config.descr,...
                'State','DATA');
            res=cTableData(obj.Data(:,2:end),obj.Keys',obj.Fields,p);
            res.setStudyCase(p);
        end


        function res=size(obj,dim)
        %size - Overload size method
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
        %
            % Initilize variables            
            log=cMessageLogger();
            p=obj.config;
            N=numel(p.fields);
            if numel(obj.Fields) < N
                log.messageLog(cType.ERROR,'Invalid number of fields %d in table %s',numel(obj.Fields),p.name);
                return
            end
            % Loop over the fields definition
            for i=1:N
                dt=p.fields(i).datatype;
                fld=obj.Fields{i};
                pfld=p.fields(i).name;
                if ~strcmpi(fld,pfld) && (dt ~= cType.DataType.SAMPLE)
                    log.messageLog(cType.ERROR,'Invalid field %s in table %s',fld,p.name);
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
                    log.messageLog(cType.ERROR,'Invalid data type for column %s in sheet %s',fld,p.name);
                    continue
                end
            end
        end
    end

    methods(Static,Access=private)
        function tst=validateKey(log,data)
        %validateKey - Validate key data
        %   Syntax:
        %     test = cModelTable.validateKey(log,data)
        %   Input Arguments
        %     log   - logger to store messages
        %     data  - field data
        %   Output Arguments:
        %     tst - true | false
        %
            tst=true;
            %Check if the keys has the correct pattern
            ier=cParseStream.checkListKeys(data);
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,'Key %s is invalid',data{i});
                end
            end
            ier=cParseStream.checkDuplicates(data);
            %Check if the keys has duplicates
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,'Key %s is duplicate',data{i});
                end
            end
        end

        function tst=validateNumeric(data)
        %validateNumeric - Validate numeric data
        %   Syntax:
        %     test = cModelTable.validateNumeric(data)
        %   Input Arguments
        %     data  - field data
        %   Output Arguments:
        %     tst - true | false
        %
            % Check if data column is mumeric
            idx=cellfun(@isnumeric,data);
            if ~all(idx)
                tst=false;
                return
            end
            % Check if values are non-negative
            tst=all(cell2mat(data) >- cType.EPS);
        end

        function tst=validateSample(log,data)
        %validateSample - Validate numeric data block
        %   Syntax:
        %     test = cModelTable.validateSample(log,data)
        %   Input Arguments
        %     data  - field data
        %     log   - logger to store messages
        %   Output Arguments:
        %     tst - true | false
        %
            % Initialize data
            tst=true;
            samples=data(1,:);
            % Check sample names
            ier=cParseStream.checkListNames(samples);
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,'Invalid sample name',samples{i});
                end
            end
            % Check duplicate names
            ier=cParseStream.checkDuplicates(samples);
            if ~isempty(ier)
                tst=false;
                for i=ier
                    log.messageLog(cType.ERROR,'Duplicate sample name',samples{i});
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