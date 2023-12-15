classdef cTableIndex < cTable
% cTableIndex create a cTable which contains the tables of a cResultInfo object
%   Methods:
%       obj=cTableIndex(res)
%       status=obj.checkTableSize;
%       obj.setState
%       bj.printTable
%       obj.viewTable(obj)
%       log=obj.saveTable(filename)
%       res=exportTable(obj)
% See also cTable
    properties (GetAccess=public,SetAccess=private)
        Content % Cell array with the cResultInfo tables
    end
    methods
        function obj=cTableIndex(res)
        % cTableIndex cTable object constructor
        %   Input:
        %       res - cResultInfo object
            if ~isa(res,'cResultInfo')
                obj.messageLog(cType.ERROR,'Invalid input argument')
                return
            end
            tnames=res.getListOfTables;
            obj.ColNames={'Key','Description'};
            obj.RowNames=tnames';
            obj.NrOfCols=numel(obj.ColNames);
            obj.NrOfRows=numel(obj.RowNames);
            obj.Data=cellfun(@(x) res.Tables.(x).Description,tnames,'UniformOutput',false);
            obj.Name=cType.ResultIndex{res.ResultId};
            obj.Description=res.ResultName;
            obj.State=res.State;
            obj.Content=struct2cell(res.Tables);
            obj.status=cType.VALID;
        end

        function res=getColumnFormat(obj)
            res=obj.isNumericColumn(1)+1;
        end

        function res=getColumnWidth(obj)
            res=zeros(1,obj.NrOfCols);
            for i=1:obj.NrOfCols
                res(i)=max(cellfun(@length,obj.Values(:,i)))+2;
            end
        end

        function res=formatData(obj)
            res=obj.Data;
        end

        function printTable(obj,fid)
        % Get table as text
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