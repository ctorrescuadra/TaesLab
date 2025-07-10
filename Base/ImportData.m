function res=ImportData(filename,varargin)
%ImportData - Import Data to a cTableData from CSV or XLSX files
%
%   Syntax
%     res=ImportXLSX(filename,Name,Value)
%  
%   Input Arguments
%     filename - Name of the file, including .xlsx extension
%       char array
%
%   Name-Value Arguments
%     Name: Name of the table. 
%       char array       
%     Description: Description of the table
%       char array
%     Sheet: Name of the data sheet, in case of XLSX files.
%       If ommitted the first sheet is used.
%       char array
%     If Name or Description are omitted, if filename is CSV use
%       the name of the file without extension, if filename is XLSX
%       use the name of the sheet
%
%   Output Arguments
%     tbl - cTableData with the content of the file/sheet
%
%   Example
%     <a href="matlab:open TableInfoDemo.mlx">Tables Info Demo</a>
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
        res.printError(cMessages.FileNotExist,filename);
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
    if ~tbl.status
        printLogger(tbl)
    end
end

function tbl=importCSV(filename,props)
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
    if ~tbl.status
        printLogger(tbl)
    end
end