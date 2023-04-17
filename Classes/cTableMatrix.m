classdef (Sealed) cTableMatrix < cTableResult
% cTableMatrix Implements cTable interface to store the matrix results of ExIOLab.
%   It store the row/col summary of the matrix
%   Methods:
%       obj=cTableCell(data,rowNames,colNames,RowSum,ColSum)
%       obj.setProperties
%       res=obj.formatData
%       res=obj.getMatlabTable
%       res=obj.getFormatedStruct(fmt)
%       res=obj.getColumnFormat
%       res=obj.getDescriptionLabel
%       obj.printFormatted
%       obj.isGraph
%       obj.isDigraph
%   Methods Inhereted from cTableResult
%       res=obj.getFormattedCell(fmt)
%       obj.ViewTable(state)
%       obj.setDescription
%       status=obj.checkTableSize;
%       res=obj.getStructData
%   See also cTableResult, cTable
%

    properties (Access=private)
        RowSum			% Row summary true/false
        ColSum			% Column summary true/false
    end
    properties (GetAccess=public,SetAccess=private)
        GraphOptions       % Graph Type
    end
    methods
        function obj=cTableMatrix(data,rowNames,colNames,rowSum,colSum)
        % Table constructor
        %  Input:
        %   data - Matrix containing the data
        %   rowNames - Cell Array containing the row's names
        %   colNames - Cell Array containing the column's names
        %   rowSum - true/false row summary computation
        %   colSum - true/false column summary computation
            if rowSum
				nrows=length(rowNames)+1;
				rowNames{nrows}='Total';
                data=[data;zerotol(sum(data))];
            end
            if colSum
				ncols=length(colNames)+1;
                colNames{ncols}='Total';
                data=[data,zerotol(sum(data,2))];
            end
            obj.Data=num2cell(data);
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.Values=[obj.ColNames;[obj.RowNames',obj.Data]]; 
            obj.ColSum=colSum;
            obj.RowSum=rowSum;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames); 
            if colSum && rowSum
                obj.Data{end,end}=0;
            end
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                message=sprintf('Invalid table size (%d,%d)',size(data,1),size(data,2));
                obj.messageLog(cType.ERROR,message);
            end 
        end
        
        function setProperties(obj,p)
        % Set the table properties: Description, Unit, Format, GraphType
            obj.Key=p.key;
            obj.Description=p.Description;
            obj.Unit=p.Unit;
            obj.Format=p.Format;
            obj.GraphType=p.GraphType;
            obj.GraphOptions=p.GraphOptions;
        end

        function res=formatData(obj)
        % Format the data value as characters
            res=cellfun(@(x) sprintf(obj.Format,x),obj.Data,'UniformOutput',false);
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=repmat(cType.colType(2),1,obj.NrOfCols);
        end

        function res=getFormattedStruct(obj,fmt)
        % Get table as formatted structure
        %  Input:
        %   fmt - (true/false) use table format 
            res=obj.getFormattedCell(fmt);
        end

        function res=getDescriptionLabel(obj)
        % Get the description of the table
            res=[obj.Description,' ',obj.Unit];
        end

        function printFormatted(obj,fId)
        % Print table on console in a pretty formatted way
            if nargin==1
                fId=1;
            end
            if obj.NrOfCols > cType.MAX_PRINT_COLS
                fprintf(fId,'\n');
                fprintf(fId,'%s\n',obj.getDescriptionLabel);
                fprintf(fId,'\n');   
                fprintf(fId,'--- Table exceed number of columns to print --- \n');
                fprintf(fId,'\n');   
                return
            end
            nrows=obj.NrOfRows;
			ncols=obj.NrOfCols;
            % first column header size
            tmp=[obj.ColNames{1},obj.RowNames(1:end)];
            len=max(cellfun(@length,tmp))+1;
            fkey=[' %-',num2str(len),'s'];
            % rest of columns
            tmp=regexp(obj.Format,'[0-9]+','match');
            fval=['%',tmp{1},'s'];
            hformat=[fkey,repmat(fval,1,ncols-1)];
            sformat=[fkey,repmat(obj.Format,1,ncols-1),'\n'];
            % Print formatted table
            header=sprintf(hformat,obj.ColNames{:});
            lines=repmat('-',1,length(header)+1);   
			fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');       
			fprintf(fId,'%s\n',header);
            fprintf(fId,'%s\n',lines);
            for i=1:nrows-1
				fprintf(fId,sformat,obj.RowNames{i},obj.Data{i,:});
            end	
            % Total summary by rows
            if obj.RowSum
                fprintf(fId,'%s\n',lines);
                tmp=obj.Data(end,:);
                if obj.ColSum
                    tmp{end,end}='';
                end
                fprintf(fId,sformat,obj.RowNames{end},tmp{:});       
            else
                fprintf(fId,sformat,obj.RowNames{end},obj.Data{end,:}); 
            end
            fprintf(fId,'\n');
        end
        %%%%
        % Graphic Interface functions
        %%%%
        function res=isUnitCostTable(obj)
            res=bitget(obj.GraphOptions,1);
        end

        function res=isFlowsTable(obj)
            res=bitget(obj.GraphOptions,2);
        end

        function res=isGeneralCostTable(obj)
            res=bitget(obj.GraphOptions,3);
        end

        function res=isDigraph(obj)
        % Determine if table has a digraph representation       
            res=(obj.GraphType==cType.GraphType.DIAGRAM_FP);
        end

    end
end