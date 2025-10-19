function res = importCSV(filename)
%importCSV - Read a CSV file and return its contents as a cell array
%   Validates filename and reads CSV contents to cell array.
%   Uses platform-specific CSV reading for MATLAB/Octave compatibility.
%
%   Syntax:
%       res = importCSV(filename)
%
%   Input Arguments:
%       filename - A string representing the path to the CSV file to read.
%
%   Output Arguments:
%       res - A cell array containing the contents of the CSV file.
%
%   Examples:
%       res = importCSV('data.csv');
%
    res=cType.EMPTY_CELL;
    % Check input arguments 
    if nargin ~= 1
        error(buildMessage(mfilename, cMessages.NarginError,cMessages.ShowHelp));
    end
    if ~isFilename(filename) || cType.getFileType(filename) ~= cType.FileType.CSV
        error(buildMessage(mfilename, cMessages.InvalidInputFile,cMessages.ShowHelp));
    end
    if ~exist(filename,'file')
        error(buildMessage(mfilename, cMessages.FileNotFound, filename));
    end
    % Detect platform and read CSV
    if isOctave()
		try
			res=csv2cell(filename);
        catch err
			error(buildMessage(mfilename, err.message));
		end
    else %Matlab
		try
		    res=readcell(filename);
        catch err
			error(buildMessage(mfilename, err.message));
		end
    end
end