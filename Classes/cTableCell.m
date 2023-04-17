classdef (Sealed) cTableCell < cTableResult
% cTableCell Implements cTable interface to store the tabular results of ExIOLab as array cells.
%   Methods:
%       obj=cTableCell(data,rowNames,colNames)
%       obj.setProperties
%       res=obj.formatData
%       res=obj.getMatlabTable
%       res=obj.getFormatedStruct(fmt)
%       res=obj.getColumnFormat
%       res=obj.getDescriptionLabel
%       obj.printFormatted
%   Methods Inhereted from cTableResult
%       obj=cTableResult(data,rowNames,colNames)
%       res=obj.getFormattedCell(fmt)
%       obj.ViewTable(state)
%       obj.setDescription
%       status=obj.checkTableSize;
%       res=obj.getStructData
% See also cTableResult, cTable
%
    properties (GetAccess=public,SetAccess=private)
        FieldNames  % Cell array with field names (optional)
    end
	
    methods
        function obj=cTableCell(data,rowNames,colNames)
        % Create table with mandatory info
        %  Input:
        %   data - data values as cell array
        %   rowNames - row's names as cell array 
        %   colNames - column's  names as cell array
        %
            obj.Data=data;
            obj.RowNames=rowNames;
            obj.ColNames=colNames;
            obj.GraphType=cType.GraphType.NONE;
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            obj.Values=[obj.ColNames;[obj.RowNames',obj.Data]];
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                message=sprintf('Invalid table size (%d,%d)',size(data,1),size(data,2));
                obj.messageLog(cType.ERROR,message);
            end 
        end
		
        function setProperties(obj,p)
        % Set table properties: Description, Unit, Format, FieldNames
            obj.Key=p.key;
            obj.Description=p.Description;
            obj.Unit=p.Unit;
            obj.Format=p.Format;
            obj.FieldNames=p.FieldNames;
        end

        function res=formatData(obj)
        % Apply format to data
            N=obj.NrOfRows;
            M=obj.NrOfCols-1;
            res=cell(N,M);
            for j=1:M
                fmt=obj.Format{j+2};
                if strContains(fmt,'f') % Octave - MATLAB compatibility
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),obj.Data(:,j),'UniformOutput',false);
                else
                    res(:,j)=obj.Data(:,j);
                end
            end
        end

        function res=getMatlabTable(obj)
        % Return as matlab table if apply
            if isMatlab
                res=getMatlabTable@cTable(obj);
                res.Properties.VariableNames=obj.FieldNames(2:end);
                res.Properties.VariableUnits=obj.Unit(2:end);
            end
        end

        function res=getFormattedStruct(obj,fmt)
        % Return table as formatted structure
        %  Input:
        %   fmt - (true/false) use table format 
            if fmt
                val=[obj.RowNames',obj.formatData];
            else
                val=[obj.RowNames',obj.Data];
            end
            res=cell2struct(val,obj.FieldNames,2);
        end
		
        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=cellfun(@(x) cType.colType(strContains(x,'f')+1),obj.Format(3:end));
        end

        function res=getDescriptionLabel(obj)
        % Get the description of each table
            res=obj.Description;
        end

        function printFormatted(obj,fId)
        % Print table on console in a pretty formatted way
            if nargin==1
                fId=1;
            end
            ncols=obj.NrOfCols+1;
            hfmt=cell(1,ncols);
            sfmt=cell(1,ncols);
            % first column id
            sfmt{1}=[' ',obj.Format{1},' '];
            tmp=regexp(sfmt{1},'[0-9]+','match');
            hfmt{1}=[' %',tmp{1},'s '];
            % second column key
            tmp={obj.ColNames{1},obj.RowNames{1:end}};
            len=max(cellfun(@length,tmp))+1;
            hfmt{2}=[' %-',num2str(len),'s'];
            sfmt{2}=hfmt{2};
            % rest of columns
            for j=3:ncols
                if ischar(obj.Data{1,j-2})
                    tmp={obj.ColNames{j-1},obj.Data{:,j-2}};
                    len=max(cellfun(@length,tmp))+1;
                    hfmt{j}=[' %-',num2str(len),'s'];
                    sfmt{j}=hfmt{j};
                else
                    tmp=regexp(obj.Format{j},'[0-9]+','match');
                    hfmt{j}=[' %',tmp{1},'s'];
                    sfmt{j}=[' ',obj.Format{j}];
                end
            end
            hformat=[hfmt{:}];
            sformat=[sfmt{:}];
            % Print formatted table
            header=sprintf(hformat,'Id',obj.ColNames{:});   
			fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');
			fprintf(fId,'%s\n',header);
            lines=repmat('-',1,length(header)+1);
			fprintf(fId,'%s\n',lines);
            for i=1:obj.NrOfRows
				fprintf(fId,sformat,i,obj.RowNames{i},obj.Data{i,:});
                fprintf(fId,'\n');
            end	
            fprintf(fId,'\n');
        end
    end
end
