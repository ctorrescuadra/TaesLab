% Thermoeconomic Analysis Toolbox
%   Version 1.8 (R2024b) 01-Oct-2025
%
% Classes
%
%  Base Classes
%   cTaesLab                - Base class of the TaesLab toolbox.
%   cMessageLogger          - Create and manage a message logger for cTaesLab objects.
%
%  Static Classes (Constants)
%   cType                   - Static class to manage the constants of TaesLab.
%   cMessages               - Static class which defines the TaesLab messages.
%   cParseStream            - Static utility class to check and validate strings.
%
%  Read Model Classes
%   cReadModel              - Abstract class to implement the model reader classes.
%   cReadModelStruct        - Abstract class to read a structured data model.
%   cReadModelJSON          - Implements the cReadModel to read JSON data model files.
%   cReadModelXML           - Implements the cReadModel to read XML data model files.
%   cReadModelTable         - Abstract class to read a table data model.
%   cReadModelCSV           - Implements the cReadModel to read CSV data model files.
%   cReadModelXLS           - Implements the cReadModel to read XLSX data model files.
%   cModelTable             - Container class to store the values read by cReadModelTables.
%
%  Data Model Classes
%   cProductiveStructure    - Build the productive structure of a plant.
%   cExergyData             - Get and validate the exergy data values for a state of the plant.
%   cFormatData             - Get the format configuration data used to display tables of results.
%   cResultTableBuilder     - Build the cResultInfo objects for the calculation layer.
%   cResourceData           - Get and validate the external cost resources of a system.
%   cWasteData              - Store the waste data information.
%
%  Result Info Classes
%   cResultId               - Base class for the calculation layer classes.
%   cResultSet              - Base class for results classes.
%   cDataModel              - Create the data model object.
%   cThermoeconomicModel    - Create the thermoeconomic model results object.
%   cResultInfo             - Container class for the application results.
%   cModelData              - Container class for the Data Model structure.
%   cModelResults           - Container class for the Thermoeconomic Model Results
%
%  Thermoeconomic Analysis Classes
%   cExergyModel            - Build the Flow-Process exergy model.
%   cExergyCost             - Calculate the exergy cost of flows and processes.
%   cDiagnosis              - Make a thermoeconomic diagnosis analysis.
%   cWasteAnalysis          - Analyze the potential cost saving of waste recycling.
%   cSummaryResults         - Get the summary results tables of the model.
%   cSummaryOptions         - Determine the summary options depending on the data model.
%   cSummaryTable           - Store the properties and values of each summary table.
%   cDigraphAnalysis        - Analyze the productive structure digraph.
%   cProductiveDiagram      - Build the productive diagrams' adjacency tables.
%   cDiagramFP              - Build the adjacency tables of the Diagram FP.
%
%  Result Tables Classes
%   cTable                  - Abstract class for tabular data.
%   cTableIndex             - Create a cTable with the index table of a cResultInfo.
%   cTableData              - Implement cTable to store data model tables.
%   cTableResult            - Abstract class to store results into a cTable.
%   cTableCell              - Implement cTableResults interface to store the results as cell arrays.
%   cTableMatrix            - Implement cTableResults interface to store the matrix results.
%   cTablesDefinition       - Create a cTable with the table's properties.
%
%  Graph Classes
%   cGraphResults           - Abstract class used to show graphs in interactive mode and apps.
%   cGraphCost              - Plot the irreversibility-cost Table.
%   cGraphCostRSC           - Plot the resource distribution cost graphs.
%   cGraphDiagnosis         - Plot the diagnosis graphs.
%   cGraphDiagramFP         - Plot the FP Diagram.
%   cGraphWaste             - Plot the waste allocation graph.
%   cGraphRecycling         - Plot the waste recycling cost graph.
%   cGraphSummary           - Plot the summary graphs.
%   cDigraph                - Plot the productive structure digraphs.
%
%  Tables Presentation Classes
%   cBuildHTML              - Convert a cTable object into an HTML file.
%   cBuildLaTeX             - Convert a cTable object into a LaTeX code table.
%   cBuildMarkdown          - Convert a cTable object into a Markdown code table.
%   cViewTable              - Show a result table using a GUI (uitable).
%
%  Utility Classes
%   cMessageBuilder         - Create and print messages for cTaesLab objects.
%   cDictionary             - Implement a (key, id) dictionary for TaesLab.
%   cDataset                - Class container to store objects and access them by key.
%   cQueue                  - A simple FIFO queue based on a dynamic cell array.
%   cSparseRow              - Store and operate with matrices that contain few non-null rows.
%







