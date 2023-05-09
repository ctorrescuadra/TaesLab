classdef cTableData < cTable
% cTableData implement cTable to use in cReadModelTable
%   Methods:
%       cReadModelTable(data)
%   Methods implemented from cTable:
%       obj.setDescription
%       status=obj.checkTableSize;
%       res=obj.getStructData
%       res=obj.getMatlabTable [only Matlab]
%
    methods
        function obj = cTableData(data)
        %cTableData Construct an instance of this class
        %  data could be cell data or struct data
            if iscell(data)
                c=data;
            elseif isstruct(data)
                c=[fieldnames(data),struct2cell(data)]';
            else
                obj.messageLog(cType.ERROR,'Invalid input parameter');
            end
            obj.Values=c;
            obj.RowNames=c(2:end,1)';
            obj.ColNames=c(1,:);
            obj.Data=c(2:end,2:end);
            obj.NrOfCols=length(obj.ColNames);
            obj.NrOfRows=length(obj.RowNames);
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                message=sprintf('Invalid table size (%d,%d)',size(data,1),size(data,2));
                obj.messageLog(cType.ERROR,message);
            end
        end

        function setDescription(obj,text)
        % Set Table Description and Name
            obj.Description=text;
            obj.Name=text;
        end
    end
end