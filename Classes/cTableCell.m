classdef (Sealed) cTableCell < cTableResult
% cTableCell Implements cTable interface to store the tabular results of ExIOLab as array cells.
%   Methods:
%       obj=cTableCell(data,rowNames,colNames)
%       status=obj.checkTableSize;
%       obj.setState
%       obj.setProperties(p)
%       status=obj.isNumericTable
%       status=obj.isNumericColumn(i)
%       res=obj.getColumnFormat
%       res=obj.getColumnWidth
%       res=obj.getStructData(fmt)
%       res=obj.getStructTable(fmt)
%       res=obj.getMatlabTable
%       res=obj.formatData
%       res=obj.exportTable(varmode,fmt)
%       obj.printTable
%       obj.viewTable
%       log=obj.saveTable(filename)
%       status=obj.isGraph
%       obj.showGraph(options)
%       res=obj.getDescriptionLabel
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
            obj.NrOfRows=length(rowNames);
            obj.NrOfCols=length(colNames);
            obj.status=obj.checkTableSize;
            if ~obj.isValid
                obj.messageLog('Invalid table size (%d,%d)',size(data,1),size(data,2));
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
            obj.GraphType=p.GraphType;
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
                res=addprop(res,["State","GraphType","ShowNumber","Format"],["table","table","table","variable"]);
                res.Properties.CustomProperties.State=obj.State;
                res.Properties.CustomProperties.GraphType=obj.GraphType;
                res.Properties.CustomProperties.Format=obj.Format(2:end);
                res.Properties.CustomProperties.ShowNumber=obj.ShowNumber;
            end
        end

        function res=getStructData(obj,fmt)
        % Return table as structure
        %  Input:
        %   fmt - (true/false) use table format
            if nargin==1
                fmt=false;
            end
            if fmt
                val=[obj.RowNames',obj.formatData];
            else
                val=[obj.RowNames',obj.Data];
            end
            res=cell2struct(val,obj.FieldNames,2);
        end

        function res=getStructTable(obj)
            N=obj.NrOfCols-1;
            fields(N)=struct('Name','','Format','','Unit','','Data',[]);
            for i=1:N
                data=cell2struct([obj.RowNames',obj.Data(:,i)],{'key','value'},2);
                fields(i)=struct('Name',obj.FieldNames{i+1},...
                     'Format',obj.Format{i+1},...
                     'Unit',obj.Unit{i+1},...
                     'Data',data);
            end
            res=struct('Name',obj.Name,'Description',obj.Description,...
            'State',obj.State,'Fields',fields);
        end
		
        function res=isNumericColumn(obj,j)
            res=strContains(obj.Format{j+1},'f');
        end

        function res=getColumnWidth(obj)
            M=obj.NrOfCols;
            res=zeros(1,M);
            res(1)=max(cellfun(@length,obj.Values(:,1)))+2;
            for j=2:M
                if isNumericColumn(obj,j-1)
                    tmp=regexp(obj.Format{j},'[0-9]+','match','once');
                    res(j)=str2double(tmp);
                else
                    res(j)=max(cellfun(@length,obj.Values(:,j)))+2;
                end
            end
        end

        function res=getColumnFormat(obj)
        % Get the format of each column (TEXT or NUMERIC)
            res=arrayfun(@(x) isNumericColumn(obj,x),1:obj.NrOfCols-1)+1;
        end
        
        function res=getDescriptionLabel(obj)
        % Get the description of each table
            res=obj.Description;
        end

        function printTable(obj,fId)
        % Print table on console in a pretty formatted way
            if nargin==1
                fId=1;
            end
            wcol=obj.getColumnWidth;
            fcol=obj.getColumnFormat;
            hfmt=arrayfun(@(x) ['%-',num2str(x),'s'],wcol,'UniformOutput',false);
            sfmt=hfmt;
            for j=2:obj.NrOfCols
                if fcol(j-1)==cType.ColumnFormat.NUMERIC
                    hfmt{j}=[' %',num2str(wcol(j)),'s'];
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
            lines=cType.getLine(length(header)+1);
            fprintf(fId,'%s\n',lines);
            for i=1:obj.NrOfRows
                fprintf(fId,sformat,data{i,:});
                fprintf(fId,'\n');
            end	
            fprintf(fId,'\n');
        end
    end
end
