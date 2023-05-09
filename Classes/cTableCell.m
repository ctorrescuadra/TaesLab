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
        ShowNumber  % logical variable indicating if line number is printed
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
            obj.Name=p.key;
            obj.Description=p.Description;
            obj.Unit=p.Unit;
            obj.Format=p.Format;
            obj.FieldNames=p.FieldNames;
            obj.ShowNumber=p.ShowNumber;
        end

        function setGraphType(obj,value)
            obj.GraphType=value;
        end

        function res=formatData(obj)
        % Apply format to data
            N=obj.NrOfRows;
            M=obj.NrOfCols-1;
            res=cell(N,M);
            for j=1:M
                fmt=obj.Format{j+1};
                if strContains(fmt,'f') % Octave - MATLAB compatibility
                    res(:,j)=cellfun(@(x) sprintf(fmt,x),obj.Data(:,j),'UniformOutput',false);
                else
                    res(:,j)=obj.Data(:,j);
                end
            end
        end

        function res=getMatlabTable(obj)
        % Return as matlab table if apply
            res=getMatlabTable@cTable(obj);
            if isMatlab
                res.Properties.VariableNames=obj.FieldNames(2:end);
                res.Properties.VariableUnits=obj.Unit(2:end);
                res.Properties.VariableDescriptions=obj.ColNames(2:end);
                res=addprop(res,["State","GraphType","Name","ShowNumber","Format"],["table","table","table","table","variable"]);
                res.Properties.CustomProperties.State=obj.State;
                res.Properties.CustomProperties.GraphType=obj.GraphType;
                res.Properties.CustomProperties.Format=obj.Format(2:end);
                res.Properties.CustomProperties.ShowNumber=obj.ShowNumber;
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
            hfmt=cell(1,obj.NrOfCols);
            sfmt=cell(1,obj.NrOfCols);
            for j=1:obj.NrOfCols
                if ischar(obj.Values{2,j})
                    tmp=obj.Values(:,j);
                    len=max(cellfun(@length,tmp))+1;
                    hfmt{j}=[' %-',num2str(len),'s'];
                    sfmt{j}=hfmt{j};
                else
                    tmp=regexp(obj.Format{j},'[0-9]+','match');
                    hfmt{j}=[' %',tmp{1},'s'];
                    sfmt{j}=[' ',obj.Format{j}];
                end
            end
            % Determine output depending of table definition
            if obj.ShowNumber
                sfmt0=[' ',cType.FORMAT_ID,' '];
                tmp=regexp(sfmt0,'[0-9]+','match');
                hfmt0=[' %',tmp{1},'s '];
                hformat=[hfmt0, hfmt{:}];
                sformat=[sfmt0, sfmt{:}];
                header=sprintf(hformat,'Id',obj.ColNames{:});
                data=[num2cell(1:obj.NrOfRows)' obj.Values(2:end,:)];
           else
                hformat=[hfmt{:}];
                sformat=[sfmt{:}];
                header=sprintf(hformat,obj.ColNames{:});
                data=obj.Values(2:end,:);
            end
            % Print formatted table   
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',obj.getDescriptionLabel);
            fprintf(fId,'\n');
            fprintf(fId,'%s\n',header);
            lines=repmat('-',1,length(header)+1);
            fprintf(fId,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fId,sformat,data{i,:});
                fprintf(fId,'\n');
            end	
            fprintf(fId,'\n');
        end
    end
end
