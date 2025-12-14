function tbl = analyzeExamples(varargin)
%analyzeExamples - Analyze all data model files in Examples folder
%   This function searches for all *_model files (any format) in the Examples
%   subfolders and creates a summary table with key properties of each model.
%
%   Syntax:
%     tbl = analyzeExamples()
%     tbl = analyzeExamples('Format', formatType)
%     tbl = analyzeExamples('SaveAs', filename)
%
%   Input Arguments (Optional Name-Value pairs):
%     'Format' - File format to search for: 'JSON', 'XLSX', 'XML', 'CSV', 'MAT', 'ALL'
%                Default: 'ALL'
%     'SaveAs' - Filename to save the results table (CSV, XLSX, or MAT)
%                Default: '' (no save)
%     'Debug'  - Enable debug mode (true/false)
%                Default: false
%
%   Output Arguments:
%     tbl - MATLAB table with model information including:
%           * ExampleName    - Name of the example (without '_model' suffix)
%           * ExampleFolder  - Folder containing the example
%           * FileFormat     - Format of the file (JSON, XLSX, etc.)
%           * FilePath       - Full path to the model file
%           * NrOfFlows      - Number of flows
%           * NrOfProcesses  - Number of processes
%           * NrOfWastes     - Number of waste flows
%           * NrOfResources  - Number of resource flows
%           * NrOfOutputs    - Number of system outputs
%           * NrOfProducts   - Number of final products
%           * NrOfStates     - Number of exergy states
%           * NrOfSamples    - Number of resource cost samples
%           * HasWaste       - Model has waste definition
%           * HasResourceCost - Model has resource cost data
%           * CanDiagnosis   - Model can perform diagnosis
%           * CanSummary     - Model can generate summary reports
%
%   Example:
%     % Analyze all examples
%     tbl = analyzeExamples();
%
%     % Analyze only JSON files and save results
%     tbl = analyzeExamples('Format', 'JSON', 'SaveAs', 'examples_summary.xlsx');
%
%   See also ReadDataModel, convertDataModel, cDataModel
%

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'Format', 'ALL', @(x) any(strcmpi(x, ['ALL', cType.DataFormat])));
    addParameter(p, 'SaveAs', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'Debug', false, @islogical);
    parse(p, varargin{:});
    
    formatFilter = upper(p.Results.Format);
    saveFile = p.Results.SaveAs;
    debugMode = p.Results.Debug;
    
    % Setup source folder
    sourceFolder = fullfile(cType.TaesLabPath, 'Examples');
    
    fprintf('\n=== Analyzing Examples in: %s ===\n', sourceFolder);
    
    % Find all model files based on format filter
    allModelFiles = [];
    
    if strcmp(formatFilter, 'ALL')
        formats = cType.DataFormat;
    else
        formats = {formatFilter};
    end
    
    % Search for files with each format
    for i = 1:length(formats)
        fmt = formats{i};
        ext = cType.FileExt.(fmt);
        pattern = ['*_model', ext];
        files = dir(fullfile(sourceFolder, '**', pattern));
        
        if ~isempty(files)
            for j = 1:length(files)
                files(j).format = fmt;
            end
            allModelFiles = [allModelFiles; files]; %#ok<AGROW>
        end
    end
    
    if isempty(allModelFiles)
        fprintf('No model files found in %s\n', sourceFolder);
        tbl = table();
        return;
    end
    
    fprintf('Found %d model files\n', length(allModelFiles));
    fprintf('\n');
    
    % Initialize result arrays
    nFiles = length(allModelFiles);
    exampleNames = cell(nFiles, 1);
    exampleFolders = cell(nFiles, 1);
    fileFormats = cell(nFiles, 1);
    filePaths = cell(nFiles, 1);
    nrFlows = zeros(nFiles, 1);
    nrProcesses = zeros(nFiles, 1);
    nrWastes = zeros(nFiles, 1);
    nrResources = zeros(nFiles, 1);
    nrOutputs = zeros(nFiles, 1);
    nrProducts = zeros(nFiles, 1);
    nrStates = zeros(nFiles, 1);
    nrSamples = zeros(nFiles, 1);
    hasWaste = false(nFiles, 1);
    hasResourceCost = false(nFiles, 1);
    canDiagnosis = false(nFiles, 1);
    canSummary = false(nFiles, 1);
    
    % Process each file
    validCount = 0;
    for i = 1:nFiles
        file = allModelFiles(i);
        sourceFile = fullfile(file.folder, file.name);
        
        % Extract example name (without _model suffix)
        [~, baseName, ~] = fileparts(file.name);
        exampleName = strrep(baseName, '_model', '');
        
        % Extract folder name (last component of path)
        [parentFolder, ~, ~] = fileparts(file.folder);
        folderParts = strsplit(parentFolder, filesep);
        folderName = folderParts{end};
        
        fprintf('[%3d/%3d] Processing: %s/%s\n', i, nFiles, folderName, file.name);
        
        % Read Data Model
        try
            data = ReadDataModel(sourceFile, 'Debug', debugMode);
            
            if ~isValid(data)
                fprintf('         [INVALID] Could not load model\n');
                continue;
            end
            
            % Extract properties
            validCount = validCount + 1;
            exampleNames{validCount} = exampleName;
            exampleFolders{validCount} = folderName;
            fileFormats{validCount} = file.format;
            filePaths{validCount} = sourceFile;
            nrFlows(validCount) = data.NrOfFlows;
            nrProcesses(validCount) = data.NrOfProcesses;
            nrWastes(validCount) = data.NrOfWastes;
            nrResources(validCount) = data.NrOfResources;
            nrOutputs(validCount) = data.NrOfSystemOutputs;
            nrProducts(validCount) = data.NrOfFinalProducts;
            nrStates(validCount) = data.NrOfStates;
            nrSamples(validCount) = data.NrOfSamples;
            hasWaste(validCount) = data.isWaste;
            hasResourceCost(validCount) = data.isResourceCost;
            canDiagnosis(validCount) = data.isDiagnosis;
            canSummary(validCount) = data.isSummary;
            
            fprintf('         Flows=%d, Processes=%d, States=%d\n', ...
                    data.NrOfFlows, data.NrOfProcesses, data.NrOfStates);
            
        catch ME
            fprintf('         [ERROR] %s\n', ME.message);
            continue;
        end
    end
    
    % Trim arrays to valid count
    exampleNames = exampleNames(1:validCount);
    exampleFolders = exampleFolders(1:validCount);
    fileFormats = fileFormats(1:validCount);
    filePaths = filePaths(1:validCount);
    nrFlows = nrFlows(1:validCount);
    nrProcesses = nrProcesses(1:validCount);
    nrWastes = nrWastes(1:validCount);
    nrResources = nrResources(1:validCount);
    nrOutputs = nrOutputs(1:validCount);
    nrProducts = nrProducts(1:validCount);
    nrStates = nrStates(1:validCount);
    nrSamples = nrSamples(1:validCount);
    hasWaste = hasWaste(1:validCount);
    hasResourceCost = hasResourceCost(1:validCount);
    canDiagnosis = canDiagnosis(1:validCount);
    canSummary = canSummary(1:validCount);
    
    % Create table
    tbl = table(exampleNames, exampleFolders, fileFormats, filePaths, ...
                nrFlows, nrProcesses, nrWastes, nrResources, ...
                nrOutputs, nrProducts, nrStates, nrSamples, ...
                hasWaste, hasResourceCost, canDiagnosis, canSummary, ...
                'VariableNames', {'ExampleName', 'ExampleFolder', 'FileFormat', 'FilePath', ...
                                  'NrOfFlows', 'NrOfProcesses', 'NrOfWastes', 'NrOfResources', ...
                                  'NrOfOutputs', 'NrOfProducts', 'NrOfStates', 'NrOfSamples', ...
                                  'HasWaste', 'HasResourceCost', 'CanDiagnosis', 'CanSummary'});
    
    % Summary
    fprintf('\n=== Analysis Summary ===\n');
    fprintf('Total files found:    %d\n', nFiles);
    fprintf('Valid models loaded:  %d\n', validCount);
    fprintf('Failed to load:       %d\n', nFiles - validCount);
    fprintf('\n');
    
    % Display statistics
    if validCount > 0
        fprintf('=== Model Statistics ===\n');
        fprintf('Flows:     min=%d, max=%d, mean=%.1f\n', ...
                min(nrFlows), max(nrFlows), mean(nrFlows));
        fprintf('Processes: min=%d, max=%d, mean=%.1f\n', ...
                min(nrProcesses), max(nrProcesses), mean(nrProcesses));
        fprintf('States:    min=%d, max=%d, mean=%.1f\n', ...
                min(nrStates), max(nrStates), mean(nrStates));
        fprintf('With waste:        %d (%.0f%%)\n', ...
                sum(hasWaste), 100*sum(hasWaste)/validCount);
        fprintf('With cost data:    %d (%.0f%%)\n', ...
                sum(hasResourceCost), 100*sum(hasResourceCost)/validCount);
        fprintf('Can diagnosis:     %d (%.0f%%)\n', ...
                sum(canDiagnosis), 100*sum(canDiagnosis)/validCount);
        fprintf('Can summary:       %d (%.0f%%)\n', ...
                sum(canSummary), 100*sum(canSummary)/validCount);
        fprintf('\n');
    end
    
    % Save results if requested
    if ~isempty(saveFile)
        try
            [~, ~, ext] = fileparts(saveFile);
            if isempty(ext)
                saveFile = [saveFile, '.xlsx'];
                ext = '.xlsx';
            end
            
            if strcmpi(ext, '.mat')
                save(saveFile, 'tbl');
            elseif strcmpi(ext, '.csv')
                writetable(tbl, saveFile);
            elseif strcmpi(ext, '.xlsx')
                writetable(tbl, saveFile);
            else
                warning('Unsupported file format: %s. Using .xlsx', ext);
                saveFile = [saveFile, '.xlsx'];
                writetable(tbl, saveFile);
            end
            
            fprintf('Results saved to: %s\n', saveFile);
        catch ME
            data.printWarning('Failed to save results: %s', ME.message);
        end
    end
end
