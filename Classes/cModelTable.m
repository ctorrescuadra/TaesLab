classdef cModelTable < cMessageLogger
%cModelTable - Utility class to validate and store model tables values from cReadModelTable

    properties(GetAccess=public,SetAccess=private)
        Values  % Values read from table data
        Fields  % Fields of the table
        Data    % Table Data
        Keys    % Data keys 
    end

    methods
        function obj=cModelTable(table,props)
            if ~iscell(tables) || ~isstruct(props)
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument,cMessage.ShowHelp);
                return
            end
            if ~any(isfield(props,{'id','name','optional','fields'}))
                obj.messageLog(cType.ERROR,cMessages.InvalidArgument);
                return
            end
            obj.Values=table;
            log=obj.ValidateTable(props);
            if ~log.status
                obj.addLogger(log);
            end
        end

        function res=get.Fields(obj)
            res = obj.Values(1,:);
        end

        function res=get.Data(obj)
            res = obj.Values(2:end,:);
        end

        function res=get.Keys(obj)
            res = obj.Values(:,1);
        end

        function res=getStructData(obj)
            res=cell2struct(obj.Data,obj.Fields,2);
        end
    end

    methods(Access=private)
        function log=validateTable(p)
            log=cMessageLog();
            N=numel(p.fields);
            if numel(obj.Fields) < N
                log.messageLog(cType.ERROR,'Invalid number of fields %d in table %s',numel(obj.Fields),p.name);
                return
            end
            for i=1:numel(p)
                dt=p.fields(i).datatype;
                if ~strcmpi(obj.Fields{i},p.fields{i}) && (dt ~= cType.DataType.SAMPLE)
                    log.messageLog(cType.ERROR,'Invalid field %s in table %s',obj.Fields{i},p.name);
                    continue
                end
                colData=obj.Data(:,i);
                sampleData=obj.Values(:,i:end);
                switch dt
                    case cType.DataType.KEY
                        cModelTable.validateKey(log,colData)
                    case cType.DataType.CHAR
                        cModelTable.validateString(log,colData);
                    case cType.DataType.NUMERIC
                        cModelTable.validateNumeric(log,colData);
                    case cType.DataType.SAMPLE
                        cModelTable.validateSample(log,sampleData);
                end
            end
        end
    end
end