classdef (Sealed) cReadModelXLS < cReadModelTable
%cReadModelXLS - Reads an XLSX thermoeconomic data model workbook.
%   Concrete implementation of cReadModelTable for XLSX format. Each
%   expected data model section corresponds to a worksheet. Sheet names
%   and field layouts are driven by printformat.json. Optional sheets
%   are skipped silently when absent from the workbook.
%
%   MATLAB uses sheetnames + readcell; Octave uses xlsopen + xls2oct.
%
%   cReadModelXLS Properties (inherited from cReadModel / cReadModelTable):
%     ModelFile   - Absolute path of the source XLSX file
%     ModelName   - Model name (file name without extension)
%     ModelData   - Validated cModelData object
%     ModelTables - Struct of cModelTable objects keyed by sheet name
%
%   cReadModelXLS Methods:
%     cReadModelXLS    - Construct an instance and read all worksheets
%     getDataModel     - Build and return a cDataModel object (inherited)
%     printModelTables - Display all loaded tables on the console (inherited)
%
%   See also cReadModel, cReadModelTable, cModelData, cModelTable
%
    methods
        function obj = cReadModelXLS(filename)
        %cReadModelXLS - Construct an instance and read all XLSX worksheets.
        %   Opens the workbook, discovers available sheet names, then
        %   iterates over the tables defined in printformat.json and imports
        %   each matching sheet into a cModelTable. Construction errors are
        %   stored in the logger; check isValid(obj) after construction.
        %
        %   Syntax:
        %     obj = cReadModelXLS(filename)
        %
        %   Input Arguments:
        %     filename - Path to the XLSX workbook file
        %
        %   Output Arguments:
        %     obj - cReadModelXLS object
        %
        %   See also cReadModelXLS.getDataModel
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
                elseif opts(i)
					obj.messageLog(cType.INFO,'Optional Sheet %s is not available',sht);
                    continue
                else
                    obj.messageLog(cType.ERROR,cMessages.SheetNotExist);
                end
            end
            % Set Model properties
            if isValid(obj)                   
                obj.ModelTables=tables;
                obj.setModelProperties(filename);
                obj.ModelData=obj.buildModelData(tables);
            end
        end 
    end

    methods(Static,Access=private)
        function tbl=import(xls,wsht,props)
        %import - Read one worksheet and wrap it in a cModelTable.
        %   Uses xls2oct (Octave) or readcell (MATLAB) to load the raw
        %   cell array from the specified worksheet, then delegates
        %   validation to cModelTable.
        %
        %   Syntax:
        %     tbl = cReadModelXLS.import(xls, wsht, props)
        %
        %   Input Arguments:
        %     xls   - Workbook handle (Octave) or XLSX file path (MATLAB)
        %     wsht  - Worksheet name to read
        %     props - Table definition struct from printformat.json
        %
        %   Output Arguments:
        %     tbl - cModelTable object, or cMessageLogger on read error.
        %           Check tbl.status before use.
        %
            tbl=cMessageLogger();
            % Read values from file
            if isOctave
		        try
			        values=xls2oct(xls,wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
			        return
		        end
            else %isMatlab
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