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
                    data=cellfun(@(x) num2str(x),obj.Data(:,j-1),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    res(j)=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT])+1;
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
        end

        function res = getStructData(obj)
        % Get Table as struct array
            val = [obj.RowNames',obj.Data];
            res = cell2struct(val,obj.ColNames,2);
        end
    
        function res=getMatlabTable(obj)
        % Get Table as Matlab table
            if isOctave
                res=obj;
            else
                res=cell2table(obj.Data,'VariableNames',obj.ColNames(2:end),'RowNames',obj.RowNames');
                res=addprop(res,"Name","table");
                res.Properties.Description=obj.Description;
                res.Properties.CustomProperties.Name=obj.Name;
            end
        end

        function printTable(obj,fid)
        % Get table as text
            if nargin==1
                fid=1;
            end
            data=obj.Data;
            wcol=obj.getColumnWidth;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wcol,'UniformOutput',false);
            for j=1:obj.NrOfCols-1
                if obj.isNumericColumn(j)
                    data(:,j)=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    lfmt{j+1}=['%',num2str(wcol(j+1)),'s '];
                end
            end
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fid,lformat,obj.RowNames{i},data{i,:});
            end
            fprintf(fid,'\n');
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