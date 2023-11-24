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
                obj.messageLog(cType.ERROR,'Invalid table size (%d,%d)',size(data,1),size(data,2));
            end
        end

        function setDescription(obj,idx)
        % Set Table Description and Name from cType
        %   Input:
        %       idx - Table index
            obj.Description=cType.TableDataDescription{idx};
            obj.Name=cType.TableDataName{idx};
        end

        function res=getColumnWidth(obj)
            M=obj.NrOfCols;
            res=zeros(1,M);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=2:M
                if obj.isNumericColumn(j-1)
                    res(j)=cType.DEFAULT_NUM_LENGHT;
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
        end      
    end
    methods (Static,Access=public)
        function tbl=create(values)
            % Create a cTableData from values
            rowNames=values(2:end,1);
            colNames=values(1,:);
            data=values(2:end,2:end);
            tbl=cTableData(data,rowNames',colNames);
        end
    end
end