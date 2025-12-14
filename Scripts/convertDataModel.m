%convertDataModel - Script to batch conversion of data model files
%   The script convert all data model XLSX files on the Examples subfolders
%   to the desired format: JSON, CSV, XML or MAT.
%   The script searches for all *_model.xlsx files recursively under the
%   Examples folder of TaesLabPath.
%
%   Prompt parameters interactively:
%     - Select the target data format
%     - Select all *_model.xlsx files in the Examples subfolders 
%     - By default save the data model copy in the same folder than the source,
%       or select a destination folder relative to TaesLabPath
%     - Overwrite existing files
%     - Debug data model and selected files to save
%
%   Output:
%     Converted files in the selected format
%
%   See also ReadDataModel, saveDataModel, cDataModel, cType, 
%   optionChoice, folderChoice, askQuestion
%
% Setup source folder
sourceFolder=fullfile(cType.TaesLabPath,'Examples');
% Select target data format
[option,targetFormat]=optionChoice('Select Data Model Output Type:',cType.DataFormat(2:end));
fTypeId=option+1;
targetExt=cType.FileExt.(targetFormat);
% Find all Excel files matching *_model.xlsx pattern
fprintf('\n=== %s to %s Conversion ===\n', cType.DataFormat{1},targetFormat);
fprintf('Searching for *_model.xlsx files in: %s\n', sourceFolder);
allFiles = dir(fullfile(sourceFolder, '**', '*.xlsx'));
modelFiles = allFiles(endsWith({allFiles.name}, '_model.xlsx'));    
if isempty(modelFiles)
    fprintf('No *_model.xlsx files found in %s\n', sourceFolder);
    return;
end
fprintf('Found %d model files\n', length(modelFiles));
% Select debug mode option
debugMode=askQuestion('Debug Data Model','N');
% Select Overwrite output files option
overwrite=askQuestion('Overwrite output files','N');
% Select output folder
targetFolder=folderChoice('Select Output Folder');
if strcmp(targetFolder,'.')
    srcPath=true;
else
    srcPath=false;
    targetFolder=fullfile(cType.TaesLabPath,targetFolder);
    if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
    end
end
% Process each file
converted = 0;
skipped = 0;
failed = 0;
for i = 1:length(modelFiles)
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
    % Check Overwrite
    if ~overwrite && exist(targetFile, 'file')
        fprintf('[SKIP] %s (already exists)\n', targetFile);
        skipped = skipped + 1;
        continue;
    end     
    % Read Data Model
    fprintf('[PROCESS] %s\n', sourceFile);
    data = ReadDataModel(sourceFile, 'Debug', debugMode);
    if ~isValid(data)
        failed = failed + 1;
        continue;
    end
    % Debug Mode. Ask to save file
    soption=true;
    if debugMode
        soption=askQuestion('Save the file','Y');
    end
    if ~soption
        continue
    end
    % Save Data Model
    log=saveDataModel(data, targetFile);
    if isValid(log)
        fprintf('[%3d/%3d] Converted: %s\n',i, length(modelFiles), targetFile);
        converted = converted + 1;
    else
        log.printLogger;
        log.printError(cMessages.FileNotSaved,targetFile);
        failed = failed +1;
    end
end
% Summary
fprintf('\n=== Conversion Summary ===\n');
fprintf('Total files:    %d\n', length(modelFiles));
fprintf('Converted:      %d\n', converted);
fprintf('Skipped:        %d\n', skipped);
fprintf('Failed:         %d\n', failed);
fprintf('\n');