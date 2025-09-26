classdef (Sealed) cReadModelXLS < cReadModelTable
%cReadModelXLS -Implement the cReadModelTable to read XLSX data model files
%   This class read a XLSX file containing the thermoeconomic model data
%   and build the data model
%
%   cReadModelCSV constructor
%     obj=cReadModelCSV(filename)
%
%   See also cReadModel, cReadModelTable
%
    methods
        function obj = cReadModelXLS(filename)
        %cReadModelXLS - Build an instance of the class
        %   Read a XLSX data model file
        %   Syntax:
        %     obj = cReadNodelXLS(filename)
        %   Input Argument:
		%	  filename - xlsx file containig the model of the plant
        %   Output Argument
        %     obj - cReadModel object
		%
            % Read configuration file
            config=getDataModelConfig(obj);
            if isempty(config)
                return
            end
            opts=[config.optional];
            wshts={config.name};
            if isOctave
				try
					xls=xlsopen(filename);
                	sheets=xls.sheets.sh_names;
				catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,cMessages.FileNotRead,filename);
					return
				end
            else %is Matlab interface
                try
				    sheets=sheetnames(filename);
				    xls=filename;
                catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,cMessages.FileNotRead,filename);
					return
                end
            end
            tables=struct();
            check=ismember(wshts,sheets);
            % Read tables
            for i=1:numel(config)
                sht=wshts{i};
                props=config(i);
                if check(i)
                    tbl=cReadModelXLS.import(xls,sht,props);
                    if tbl.status
                        tables.(sht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,cMessages.SheetNotRead,sht);
                        continue
                    end
                elseif ~opts(i)
					obj.messageLog(cType.INFO,'Optional Sheet %s is not available',sht);
                    continue
                else
                    obj.messageLog(cType.ERROR,cMessages.SheetNotExist);
                end
            end
            % Set Model properties
            if isValid(obj)                   
                obj.modelTables=tables;
                obj.setModelProperties(filename);
                obj.ModelData=obj.buildModelData(tables);
            end
        end 
    end

    methods(Static,Access=private)
        function tbl=import(xls,wsht,props)
        %import - Read sheet and store into a cModelTable object
        %   Syntax:
        %     tbl = import(xls,wsht,props)
        %   Input Arguments:
        %     xls   - XLSX filename
        %     wsht  - Worksheet of the file to read
        %     props - Properties of the table
        %   Output Argument
        %     res - cModelTable object
        %
            tbl=cMessageLogger;
            if isOctave
		        try
			        values=xls2oct(xls,wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
			        return
		        end
            else %Matlab
		        try
		            values=readcell(xls,'Sheet',wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
                    return
		        end
            end
            tbl=cModelTable(values,props);
        end
    end
end