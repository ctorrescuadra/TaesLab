function convertExamples(targetFormat,varargin)
%convertExamples - Batch convert data model files to a target format
%
%   Syntax:
%     convertExamples(targetFormat)
%     convertExamples(targetFormat, Name, Value)
%
%   Description:
%     Batch conversion utility that finds all Excel data model files matching
%     the pattern '*_model.xlsx' in the Examples folder and converts them to
%     the specified format (JSON, CSV, XML, or MAT).
%
%     The function recursively searches the Examples folder, reads each model
%     using cDataModel.create, and saves it in the target format using
%     saveDataModel. By default, converted files are saved in the same
%     directory as the source file.
%
%     A summary report is displayed showing the total number of files
%     processed, successfully converted, skipped (if Overwrite=false), and
%     failed conversions.
%
%   Input Arguments:
%     targetFormat - Target file format for converted models
%       char array. Valid values: 'JSON', 'CSV', 'XML', 'MAT'
%
%   Name-Value Arguments:
%     SaveFolder - Destination folder for converted files
%       char array. Full path to an existing folder.
%       If not specified, files are saved in the same folder as the source.
%
%     Overwrite - Whether to overwrite existing target files
%       logical. If false, existing files are skipped.
%       Default: false
%
%   Examples:
%     % Convert all Excel models to JSON in the same folder
%     convertExamples('JSON');
%
%     % Convert to CSV in a specific output folder, overwriting existing files
%     convertExamples('CSV', 'SaveFolder', 'C:\Output', 'Overwrite', true);
%
%     % Convert to MAT format without overwriting
%     convertExamples('MAT', 'Overwrite', false);
%
%   Algorithm:
%     1. Validate targetFormat against cType.ModelFormatOptions
%     2. Parse and validate Name-Value arguments (SaveFolder, Overwrite)
%     3. Search for *_model.xlsx files in cType.ExamplesPath
%     4. For each file:
%        a. Check if target file exists and handle Overwrite option
%        b. Load source file using cDataModel.create
%        c. Save to target format using saveDataModel
%        d. Track conversion status (success/skip/fail)
%     5. Display summary report
%
%   Notes:
%     - Only processes Excel files matching '*_model.xlsx' pattern
%     - Source files must be valid TaesLab data model files
%     - Failed conversions are logged but do not stop batch processing
%     - If SaveFolder is specified, it must exist (not created automatically)
%
%   See also:
%     cDataModel, cDataModel.create, saveDataModel, ReadDataModel
%
    log=cTaesLab();
    % Check target format
    modelFormats=cType.ModelFormatOptions;
    if nargin<1 || ~ischar(targetFormat) || ~ismember(targetFormat,modelFormats(2:end))
        log.printError(cMessages.InvalidArgument,cMessages.ShowHelp);
        return
    end
    mId=cType.getModelFormat(targetFormat);
    targetExt=cType.DataModelExt{mId};
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'SaveFolder', cType.EMPTY_CHAR,@ischar);
    addParameter(p, 'Overwrite', false, @islogical);
    try
        p.parse(varargin{:});
    catch err
        log.printError(err.message);
        return
    end
    param = p.Results;
    % Check target format
    if isempty(param.SaveFolder)
        srcPath=true;
    elseif isfolder(param.SaveFolder)
        srcPath=false;
    else
        log.printError(cMessages.FolderNotExists,param.SaveFolder);
        return
    end
    targetFolder=param.SaveFolder;
    % Find all Excel files matching *_model.xlsx pattern
    sourceFolder = fullfile(cType.EXAMPLES_FOLDER,'**');
    modelFiles = filesInfo(sourceFolder,'*_model.xlsx');
    if isempty(modelFiles)
        log.printError(cMessages.NotModelsFound);
        return;
    end
    nFiles=length(modelFiles);
    % Process each file
    cnt = 0;
    skipped = 0;
    failed = 0;
    for i = 1:nFiles
        file = modelFiles(i);
        sourceFile = fullfile(file.folder, file.name);
        % Determine output file path
        [~, baseName, ~] = fileparts(file.name);
        targetFileName=[baseName,targetExt];
        if srcPath
            targetFile=fullfile(file.folder,targetFileName);
        else
            targetFile=fullfile(targetFolder,targetFileName);
        end
        % Overwrite option
        if ~param.Overwrite && exist(targetFile, 'file')
            log.printInfo(cMessages.SkipFileCopy,targetFile)
            skipped = skipped + 1;
            continue;
        end 
        data = cDataModel.create(sourceFile);
        if ~isValid(data) % Count converted files
            failed = failed + 1;
            data.printLogger;
            continue;
        end
        % Save Data Model
        slog=saveDataModel(data, targetFile);
        printLogger(slog);
        if isValid(slog)        
            cnt = cnt + 1;
        else
            failed = failed + 1;
        end   
    end
    % Summary
    fprintf('\n=== Conversion Summary ===\n');
    fprintf('Total files:    %d\n', length(modelFiles));
    fprintf('Converted:      %d\n', cnt);
    fprintf('Skipped:        %d\n', skipped);
    fprintf('Failed:         %d\n', failed);
    fprintf('\n');
end
