classdef (Sealed) cReadModelXLS < cReadModelTable
% cReadModelXLS implements the cReadModel to read XLSX data model files
%   This class read a XLSX file containing the thermoeconomic model data
%   and build the data model
%
% See also cReadModel, cReadModelTable
%
    methods
        function obj = cReadModelXLS(cfgfile)
        % Construct an instance of the class
		%	cfgfile - xlsx file containig the model of the plant
		%
            % Read configuration file
            Sheets=cType.TableDataName;
            if isOctave
				try
					xls=xlsopen(cfgfile);
                	sht=xls.sheets.sh_names;
				catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,cMessages.FileNotRead,cfgfile);
					return
				end
            else %is Matlab interface
                try
				    sht=sheetnames(cfgfile);
				    xls=cfgfile;
                catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,cMessages.FileNotRead,cfgfile,cfgfile);
					return
                end
            end
            check=ismember(Sheets,sht);
            % Read mandatory tables
            tables=struct();
            p=struct('Name','','Description','');
            for i=cType.MandatoryTables
                wsht=Sheets{i};
                p.Name=wsht;
                p.Description=cType.TableDataDescription{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht,p);
                    if tbl.status
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,cMessages.SheetNotRead,wsht);
                        return
                    end
                else
					obj.messageLog(cType.ERROR,cMessages.SheetNotExist,wsht);
                    return
                end
            end
            % Read optional tables 
            for i=cType.OptionalTables
                wsht=Sheets{i};
                p.Name=wsht;
                p.Description=cType.TableDataDescription{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht,p);
                    if tbl.status
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,cMessages.SheetNotRead,wsht);
                        return
                    end
                end  
            end
            % Set Model properties
            obj.modelTables=tables;
            obj.setModelProperties(cfgfile);
            obj.ModelData=obj.buildModelData(tables);
        end 
    end

    methods(Static,Access=private)
        function tbl=importSheet(xls,wsht,props)
        %Import a workbook/sheet 
            tbl=cMessageLogger;
            if isOctave
		        if ~isstruct(xls)
			        tbl.messageLog(cType.ERROR,cMessages.InvalidXLS);
			        return
		        end
		        % Read file and store into a cell
		        try
			        values=xls2oct(xls,wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
			        return
		        end
            else %Matlab
                if ~exist(xls,'file')
                    tbl.messageLog(cType.ERROR,cMessages.FileNotExist,xls);
                    return
                end
                % Read file and store into a cell
		        try
		            values=readcell(xls,'Sheet',wsht);
                catch err
			        tbl.messageLog(cType.ERROR,err.message);
                    return
		        end
            end
            tbl=cTableData.create(values,props);
        end
    end
end