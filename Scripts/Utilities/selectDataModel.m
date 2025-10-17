function model=selectDataModel()
% selectDataModel - Interactive selection of data model
%  OUTPUT:
%	model - cReadModel object
% 
	model=cMessageLogger();
	[~,name]=fileparts(pwd);
	default_file=strcat(name,'_model.xlsx');
	data_file=fileChoice('Select data model file',default_file);
	if ~exist(data_file,'file')
	    model.messageLog(cType.ERROR,cMessages.FileNotFound,data_file);
        return
	end
	% Read and Check model
	model=cDataModel.create(data_file);
end