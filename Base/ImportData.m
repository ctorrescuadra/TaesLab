function res=ImportData(filename,varargin)
%ImportData - Import external data to a cTableData from CSV or XLSX files.
%
%   Syntax:
%     res=ImportData(filename,Name,Value)
%  
%   Input Arguments:
%     filename - Name of the file, including .xlsx extension
%       char array
%
%   Name-Value Arguments:
%     Name: Name of the table. 
%       char array       
%     Description: Description of the table
%       char array
%     Sheet: Name of the data sheet, in case of XLSX files.
%       If ommitted the first sheet is used.
%       char array
%     If Name or Description are omitted, when filename is CSV use
%       the name of the file without extension, when filename is XLSX
%       use the name of the sheet
%
%   Output Arguments:
%     tbl - cTableData object with the content of the file/sheet
%
%   Notes:
%     - If the file is CSV, the first row is considered as header
%       and the rest as data. If the file is XLSX, empty rows and columns
%       are removed.
%     - If the file is XLSX and the sheet does not exist, an error is returned.
%     - If the file is XLSX and the sheet is not provided, the first sheet is used.
%     - If the file is CSV or XLSX and the Name or Description are not provided,
%       use the name of the file without extension, when filename is CSV,
%       and use the name of the sheet when filename is XLSX.
%
%   Example:
%     <a href="matlab:open ImportDataDemo.mlx">Import Data Demo</a>
%  
%   See also cTableData
%
    res=cMessageLogger();
    % Check Mandatory parameter
    if nargin<1 
        res.printError(cMessages.ShowHelp);
        return
    end
    if ~isFilename(filename)
        res.printError(cMessages.InvalidInputFile);
        return
    end
    if ~exist(filename,'file')
        res.printError(cMessages.FileNotFound,filename);
        return
    end
    % Optional parameters
    p = inputParser;
    p.addParameter('Sheet',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Name',cType.EMPTY_CHAR,@ischar);
    p.addParameter('Description',cType.EMPTY_CHAR,@ischar);
    try
		p.parse(varargin{:});
    catch err
		res.printError(err.message);
        res.printError(cMessages.ShowHelp);
        return
    end
    props=p.Results;
    % Import file depending extension
    fileType=cType.getFileType(filename);
    switch fileType  
        case cType.FileType.CSV
            res=importCSV(filename,props);
        case cType.FileType.XLSX
            res=importXLSX(filename,props);
        otherwise
            res.printError(cMessages.InvalidFileExt,filename);
            return
    end
    if ~res.status
        printLogger(res)
    end
end

function tbl=importCSV(filename,props)
%importCVS - import CSV files to cTableData object
    tbl=cMessageLogger();
    if isOctave
		try
			values=csv2cell(filename);
        catch err
			tbl.printError(err.message);
			return
		end
    else %Matlab
		try
		    values=readcell(filename);
        catch err
			tbl.printError(err.message);
            return
		end
    end
    [~,name]=fileparts(filename);
    if isempty(props.Name)
        props.Name=name;
    end
    if isempty(props.Description)
        props.Name=name;
    end
    % Create the table
    tbl=cTableData.create(values,props);
end

function tbl=importXLSX(filename,props)
%importCVS - import CSV files to cTableData object
    tbl=cMessageLogger();
    % Open the file
    if isOctave
		try
			xls=xlsopen(cfgfile);
            shts=xls.sheets.sh_names;
		catch err
            tbl.printError(err.message);
			tbl.printError(cMessages.FileNotRead,filename);
			return
		end
    else %is Matlab interface
        try
			shts=sheetnames(filename);
			xls=filename;
        catch err
            tbl.printError(err.message);
		    tbl.printError(cMessages.FileNotRead,filename);
			return
        end
    end
    % Check if sheet exists
    wsht=props.Sheet;
    if isempty(wsht)
        wsht=shts{1};
    end
    if ~ismember(wsht,shts)
        tbl.printError(cMessages.SheetNotExist,wsht);
        return
    end
    % Read sheet
    if isOctave
		try
			values=xls2oct(xls,wsht);
        catch err
			tbl.printError(err.message);
			return
		end
    else %Matlab
		try
		    values=readcell(xls,'Sheet',wsht);
        catch err
            tbl.printError(err.message);
            return
		end
    end
    if isempty(props.Name)
        props.Name=wsht;
    end
    if isempty(props.Description)
        props.Name=wsht;
    end
    tbl=cTableData.create(values,props);
end