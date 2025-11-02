# List of Taes Toolbox Classes

| Class                  | Description                                                                   |
| ---------------------- | ----------------------------------------------------------------------------- |
| cBuildHTML             | Convert a cTable object into HTML files.                                      |
| cBuildLaTeX            | Convert cTable object into a LaTeX code table.                                |
| cBuildMarkdown         | Convert cTable object into a Markdown code table.                             |
| cDataModel             | Create the data model object.                                                 |
| cDataset               | Class container to store objects and access them by key.                      |
| cDiagnosis             | Thermoeconomic diagnosis of a plant state change.                             |
| cDiagramFP             | Build the Diagram FP adjacency tables.                                        |
| cDictionary            | Class container to store and access data by key or index.                     |
| cDigraph               | Plot the productive structure digraphs.                                       |
| cDigraphAnalysis       | Analyze a directed graph (digraph).                                           |
| cExergyCost            | Calculate the exergy cost of flows and processes.                             |
| cExergyData            | Get and validates the exergy data values for a state of the plant             |
| cExergyModel           | Build the Flow-Process exergy model.                                          |
| cFormatData            | Get the format configuration data used to display tables of results.          |
| cGraphCost             | Plot the Irreversibility-cost graph.                                          |
| cGraphCostRSC          | Plot the Resources Cost Distribution graph.                                   |
| cGraphDiagnosis        | Plot the diagnosis graphs.                                                    |
| cGraphDiagramFP        | Plot the FP Diagram.                                                          |
| cGraphRecycling        | Plot the waste recycling cost graphs.                                         |
| cGraphResults          | Abstract class used to show graphs in interactive mode and apps.              |
| cGraphSummary          | Plot the summary graphs for selecting flows or processes.                     |
| cGraphWaste            | Plot the Waste Allocation Graph.                                              |
| cMessageBuilder        | Create a message for logger                                                   |
| cMessageLogger         | Create and manage a messages logger for cTaesLab objects.                     |
| cMessages              | Static class which defines the TaesLab messages.                              |
| cModelData             | Container class for the Data Model structure.                                 |
| cModelResults          | Class container for the model results.                                        |
| cModelTable            | Class container for the values read by cReadModelTable                        |
| cParseStream           | Class with static methods to parse stream definition                          |
| cProductiveDiagram     | Build the productive diagrams adjacency tables                                |
| cProductiveStructure   | Build the productive structure of a plant.                                    |
| cQueue                 | Simple FIFO queue based on a dinamic cell array                               |
| cReadModel             | Abstract class to implemenent the model reader classes.                       |
| cReadModelCSV          | Implements the cReadModelTable to read CSV data model files.                  |
| cReadModelJSON         | Implement the cReadModelStruct to read JSON data model files.                 |
| cReadModelStruct       | Abstract class to read structured data model.                                 |
| cReadModelTable        | Abstract class to read table data model.                                      |
| cReadModelXLS          | cReadModelXLS -Implement the cReadModelTable to read XLSX data model files    |
| cReadModelXML          | cReadModelXML implements the cReadModelStruct to read XML data model files.   |
| cResourceData          | Gets and validates the external cost resources of a productive structure.     |
| cResultId              | Abstract class to manage the result identification.                           |
| cResultInfo            | Class to manage the result information and tables.                            |
| cResultSet             | Abstract class to manage the result sets.                                     |
| cResultTableBuilder    | Build the cResultInfo objects for the calculation layer                       |
| cSparseRow             | Store and operate with matrices that contain few non-null rows.               |
| cSummaryOptions        | Determine the summary options depending on the data model                     |
| cSummaryResults        | Get the summary results tables of the model.                                  |
| cSummaryTable          | Store the properties and values of each summary table.                        |
| cTable                 | Abstract class for tabular data.                                              |
| cTableCell             | Implements cTableResult interface to store results as cell arrays.            |
| cTableData             | Implement cTable to store data model tables.                                  |
| cTableIndex            | Create a cTable with the index table of a cResultInfo.                        |
| cTableMatrix           | Implements cTableResult interface to store matrix results.                    |
| cTableResult           | Abstrat class to store results into a cTable.                                 |
| cTablesDefinition      | Get the results tables properties.                                            |
| cTaesLab               | Base class of the TaesLab toolbox.                                            |
| cThermoeconomicModel   | Create the thermoeconomic model results object.                               |
| cType                  | Static class to manage the constants of TaesLab                               |
| cViewTable             | Show a result table using a GUI (uitable)                                     |
| cWasteAnalysis         | Analyze the potential cost saving of waste recycling.                         |
| cWasteData             | Get the waste data information.                                               |
