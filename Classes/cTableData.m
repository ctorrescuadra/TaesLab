classdef cTableData < cTable
% cTableData implement cTable to use in cReadModelTable
%   Methods:
%       cTableData(data,rowNames,colnames)
%       cTableData.create(values)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(name,descr)
%       obj.printTable(fId)
%       obj.viewTable(options)
%       log=obj.saveTable(filename)
%       res=obj.exportTable(varmode)
%       res=obj.isNumericTable
%       res=obj.isNumericColumn(idx)
%       res=obj.getColumnFormat
%       res=obj.getColumnWidth
%       res=obj.formatData
%       obj.setColumnValues(idx,values)
%       obj.setRowValues(idx,values)
% See also cTable
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

        function setProperties(obj,name,descr)
        % Set Table Description and Name from cType
        %   Input:
        %       idx - Table index
            obj.Name=name;
            obj.Description=descr;
        end

        function res=getColumnWidth(obj)
        % Get column width info
            res=zeros(1,obj.NrOfCols);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    res(j+1)=cw+1;
                else
                    res(j+1)=max(cellfun(@length,obj.Values(:,j+1)))+2;
                end
            end
        end

        function res=formatData(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=obj.Data;
            for j=1:obj.NrOfCols-1
                if isNumericColumn(obj,j)
                    data=cellfun(@num2str,obj.Data(:,j),'UniformOutput',false);
                    dl=max(cellfun(@length,data));
                    cw=max([dl,length(obj.ColNames{j}),cType.DEFAULT_NUM_LENGHT]);
                    fmt=['%',num2str(cw),'s'];
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),data,'UniformOutput',false);
                end
            end
        end

        function printTable(obj,fid)
        % Get table as text or print in conoloe
            if nargin==1
                fid=1;
            end
            fdata=obj.formatData;
            wc=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            for j=1:obj.NrOfCols-1
                if fcol(j)==cType.ColumnFormat.NUMERIC
                    lfmt{j+1}=['%',num2str(wc(j+1)),'s '];
                end
            end
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fid,lformat,obj.RowNames{i},fdata{i,:});
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