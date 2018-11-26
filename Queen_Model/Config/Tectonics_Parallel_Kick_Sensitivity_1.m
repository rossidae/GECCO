clear

Change_Times = 10e6;
Lag_At_Change = [1.6e6:0.4e6:2.4e6,2.6e6:0.4e6:3.6e6];

Run_Length = 70e6;
Lag_Start = 2.5e6;

% Upload 600ppm_14_Short before running

% Set up cluster
% Cluster = parcluster();
% Cluster.SubmitArguments = '-l walltime=12:00:00';

for Time_Index = 1:numel(Change_Times);
        Gecco = GECCO();
        
        % Make necessary changes
        Gecco.ShouldSaveFlag = 1;
        Gecco.SaveToSameFileFlag = 0;
        Gecco.SaveToRunFilesFlag = 1;
        
        for Lag_Change_Index = 1:numel(Lag_At_Change);
            if Lag_Change_Index~=1;
                Gecco.AddRun();
            end
            Gecco.Runs(Lag_Change_Index).AddChunk();
            
            % Make necessary changes
            Gecco.Runs(Lag_Change_Index).Chunks(1).Time_In(2) = Change_Times(Time_Index);
            Gecco.Runs(Lag_Change_Index).Chunks(1).Time_Out(2) = Change_Times(Time_Index);
            Gecco.Runs(Lag_Change_Index).Chunks(2).Time_In(1) = Change_Times(Time_Index);
            Gecco.Runs(Lag_Change_Index).Chunks(2).Time_Out(1) = Change_Times(Time_Index);
            Gecco.Runs(Lag_Change_Index).Chunks(2).Time_In(2) = Run_Length;
            Gecco.Runs(Lag_Change_Index).Chunks(2).Time_Out(2) = Run_Length;
            
%             File = strcat("/scratch/rw12g11/Tectonics_Ensemble/10e6/","T",num2str(Change_Times(Time_Index)),"LC",num2str(Lag_At_Change(Lag_Change_Index)),".nc");
%             Gecco.LoadFinal(File);
%             Gecco.Runs(Lag_Change_Index).Regions.Conditions.Constants.Load(File);
            
            File = strcat("G:/Documents/Work/PhD/Results/Queen_Model/Transients/Tectonics_Ensemble/10e6/","T",num2str(Change_Times(Time_Index)),"LC",num2str(Lag_At_Change(Lag_Change_Index)),".nc");
            Gecco.Runs(Lag_Change_Index).Regions.Conditions.Constants.Load(File);
            Gecco.Runs(Lag_Change_Index).Regions.Conditions.Constants.Outgassing.Mean_Lag = Gecco.Runs(Lag_Change_Index).Regions.Conditions.Constants.Outgassing.Mean_Lag(end);
            Gecco.LoadFinal(File);
            
            % Reduce transient size
          
            % Need to change the core
            Gecco.Runs(Lag_Change_Index).Regions.Conditions.Functionals.SetCore("Core_Tectonics");
            
            % CREATE THE DIRECTORY BEFORE RUNNING
            Gecco.Runs(Lag_Change_Index).Information.Output_Filepath = "/scratch/rw12g11/Tectonics_Productivity_Sensitivity/10e6";
            Gecco.Runs(Lag_Change_Index).Information.Output_Filename = strcat("T",num2str(Change_Times(Time_Index)),"LC",num2str(Lag_At_Change(Lag_Change_Index)),"K",num2str(Lag_Change_Index),".nc");
            
            Gecco.Runs(Lag_Change_Index).Regions.Conditions.PerformStandardOutgassingPerturbation();
        end
        
        % Submit job
        Gecco.RunModelOnIridis(Cluster);
end