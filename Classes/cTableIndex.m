classdef cTableIndex < cTable
% cTableIndex create a cTable which contains the tables of a cResultInfo object
%   Methods:
%       obj=cTableIndex(res)
%       obj.printTable(fId)
%       obj.viewTable(options)
%       log=obj.saveTable(filename)
%       res=obj.exportTable(varmode)
% See also cTable
    properties (GetAccess=public,SetAccess=private)
        Content % Cell array with the cResultInfo tables
        Info    % Info handle
    end
    methods
        function obj=cTableIndex(res)
        % cTableIndex cTable object constructor
        %   Input:
        %       res - cResultInfo object
        %
            % Check input parameters
            if ~isa(res,'cResultInfo')
                obj.messageLog(cType.ERROR,'Invalid input argument')
                return
            end
            % Get tables of the results and build table
            tnames=res.getListOfTables;
            obj.ColNames={'Key','Description','Graph'};
            obj.RowNames=tnames';
            obj.NrOfCols=numel(obj.ColNames);
            obj.NrOfRows=numel(obj.RowNames);
            obj.Data=cell(obj.NrOfRows,2);
            obj.Data(:,1)=cellfun(@(x) res.Tables.(x).Description,tnames,'UniformOutput',false);
            obj.Data(:,2)=cellfun(@(x) log2str(res.Tables.(x).GraphType),tnames,'UniformOutput',false);
            obj.Name=cType.ResultIndex{res.ResultId};
            obj.Description=res.ResultName;
            obj.State=res.State;
            obj.Content=struct2cell(res.Tables);
            obj.Info=res.Info;
            obj.setColumnFormat;
            obj.setColumnWidth;
            obj.status=cType.VALID;
        end

        function setColumnFormat(obj)
        % Get column format for cTableIndex
            obj.fcol=repmat(cType.ColumnFormat.CHAR,1,obj.NrOfCols);
        end

        function res=setColumnWidth(obj)
        % Get column width for cTableIndex
            res=zeros(1,obj.NrOfCols);
            for i=1:obj.NrOfCols
                res(i)=max(cellfun(@length,obj.Values(:,i)))+2;
            end
            obj.wcol=res;
        end

        function res=formatData(obj)
        % Format data. Only numeric fields
            res=obj.Data;
        end

        function printTable(obj,fid)
        % Get table as text or show in console
            if nargin==1
                fid=1;
            end
            wc=obj.getColumnWidth;
            lfmt=arrayfun(@(x) [' %-',num2str(x),'s'],wc,'UniformOutput',false);
            lformat=[lfmt{:},'\n'];
            header=sprintf(lformat,obj.ColNames{:});
            lines=cType.getLine(length(header)+1);
            fprintf(fid,'\n');
            fprintf(fid,'%s',header);
            fprintf(fid,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fid,lformat,obj.RowNames{i},obj.Data{i,:});
            end
            fprintf(fid,'\n');
        end
    end
end