% Thermoeconomic Analysis Toolbox
% Version 1.4 (R2023b) 13-Ene-2024
%
% Apps
%   TaesApp                 - TaesLab App.
%
% Read Data Models
%   ReadDataModel           - Read a data model file.
%   CheckDataModel          - Read a data model file and check if all elements are valid.        
%
% Get the Thermoeconomic Results
%   ThermoeconomicTool      - Get the complete thermoeconomic model of a plant
%   ProductiveStructure     - Show information of productive structure of a plant
%   ProductiveDiagram       - Get the adjacency tables of the productive structure
%   ThermoeconomicState     - Shows the exergy values of a plant state
%   ThermoeconomicAnalysis  - Provide a termoeconomic analysis of a plant state
%   ThermoeconomicDiagnosis - Compares a plant state with its reference state
%   SummaryResults          - Get the summary results of a data model
%   WasteRecycling          - Provide waste recycling analysis of the plant
%   DiagramFP               - Get the Diagram FP info of a plant state
%   ExergyCostCalculator    - Calculate the exergy cost values of a plant state
%
% Save Results Information
%   SaveDataModel           - Saves the data model into a file.
%   SaveDiagramFP           - Saves the Diagram FP adjacency tables into a file
%   SaveProductiveDiagram   - Saves the productive structure adjacency tables into a file.
%   SaveResults             - Saves a cResultInfo object into a file.
%   SaveModelResults        - Saves the model results of a plant state into a file.
%   SaveSummaryResults      - Saves the summary cost tables into a file
%   SaveTable               - Save a result table into a file
%   ExportDataModel         - Copy a model data file in another format
%
% Tables Directory
%   ListResultTables        - List the result tables properties
%   ListCodeTable           - List the internal code of the result tables
%
% Results Presentation
%   ViewTable               - View a model result table
%	ShowGraph               - Show the graph of a model result table
%
% GUI functions
%   ThermoeconomicPanel     - GUI to select the thermoeconomic model parameters.
%   ViewResults             - View the model results in a GUI
%   ShowTables              - Show Tables and Graphs from the matlab workarea
%
% See also cResultInfo, cThermoeconomicModel.
