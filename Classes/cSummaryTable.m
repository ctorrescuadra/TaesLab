classdef cSummaryTable < cMessageLogger
    properties(GetAccess=public,SetAccess=private)
        Name
        Type
        Values
    end

    methods
        function obj = cSummaryTable(name,type,size)
            obj.Name=name;
            obj.Type=type;
            obj.Values=zeros(size);
        end

        function setValues(obj,idx,val)
            obj.Values(:,idx)=val;
        end
    end
end