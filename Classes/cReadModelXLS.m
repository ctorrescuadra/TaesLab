classdef (Sealed) cReadModelXLS < cReadModelTable
% cReadModelXLS implements the cReadModel to read XLSX data model files
%   This class read a XLSX file containing the thermoeconomic model data
%   and store it into a structure data
%   Methods:
%       obj=cReadModelXLS(cfgfile)
%	Methods inhereted from cReadModelTable
%		res=obj.getTableModel
%   See also cReadModel, cReadModelTable
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
					obj.messageLog(cType.ERROR,'File %s cannot be opened',cfgfile);
					return
				end
            else %is Matlab interface
                try
				    sht=sheetnames(cfgfile);
				    xls=cfgfile;
                catch err
                    obj.messageLog(cType.ERROR,err.message);
					obj.messageLog(cType.ERROR,'File %s cannot be opened',cfgfile);
					return
                end
            end
            check=ismember(Sheets,sht);
            % Read mandatory tables
            tables=struct();
            for i=cType.MandatoryTables
                wsht=Sheets{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht);
                    if tbl.isValid
                        tbl.setProperties(wsht,cType.TableDataDescription{i})
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading sheet %s',wsht);
                        return
                    end
                else
					obj.messageLog(cType.ERROR,'Sheet %s does not exists',wsht);
                    return
                end
            end
            % Read optional tables 
            for i=cType.OptionalTables
                wsht=Sheets{i};
                if check(i)
                    tbl=cReadModelXLS.importSheet(xls,wsht);
                    if tbl.isValid
                        tbl.setProperties(wsht,cType.TableDataDescription{i})
                        tables.(wsht)=tbl;
                    else
                        obj.addLogger(tbl);
					    obj.messageLog(cType.ERROR,'Error reading sheet %s',wsht);
                        return
                    end
                end  
            end
            % Set Model properties
            obj.setModelProperties(cfgfile);
            sd=obj.buildDataModel(tables);
            if isValid(obj)
                obj.ModelData=cModelData(sd);
                obj.modelTables=tables;
            end
        end 
    end

    methods(Static,Access=private)
        function tbl=importSheet(xls,wsht)
        %Import a workbook/sheet 
            tbl=cStatusLogger;
            if isOctave
		        if ~isstruct(xls)
			        tbl.messageLog(cType.ERROR,'Invalid XLS pointer');
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
                    tbl.messageLog(cType.ERROR,'File %s not found',xls);
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
            tbl=cTableData.create(values);
        end
    end
end