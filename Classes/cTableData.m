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
        function obj = cTableData(data,rowNames,colNames)
        %cTableData Construct an instance of this class
        %  data could be cell data or struct data
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.Data=data;
            obj.NrOfCols=length(obj.ColNames);
            obj.NrOfRows=length(obj.RowNames);
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                message=sprintf('Invalid table size (%d,%d)',size(data,1),size(data,2));
                obj.messageLog(cType.ERROR,message);
            end
        end

        function setDescription(obj,idx)
        % Set Table Description and Name from cType
        %   Input:
        %       idx - Table index
            obj.Description=cType.TableDataDescription{idx};
            obj.Name=cType.TableDataName{idx};
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=repmat(cType.colType(1),1,obj.NrOfCols);
        end
    end
end