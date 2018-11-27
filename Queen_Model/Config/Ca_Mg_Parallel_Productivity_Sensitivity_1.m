clear

Change_Times = 10e6;
Magnesium_Change_Times = Change_Times;
Calcium_At_Change = [10;18];
Magnesium_At_Change = [50;34];

Calcium_Start = 20;
Calcium_End = 10;

Magnesium_Start = 30;
Magnesium_End = 50;

Run_Length = 70e6;

Strengths = [0;0.7;0.9;1/0.9;1/0.7];

% Upload 600ppm_14_Short before running

% Set up cluster
Cluster = parcluster();
Cluster.SubmitArguments = '-l walltime=12:00:00';

for Magnesium_Change_Index = 1:numel(Magnesium_At_Change);
    for Time_Index = 1:numel(Change_Times);
        for Calcium_Change_Index = 1:numel(Calcium_At_Change);
            Gecco = GECCO();
            
            % Make necessary changes
            Gecco.ShouldSaveFlag = 1;
            Gecco.SaveToSameFileFlag = 0;
            Gecco.SaveToRunFilesFlag = 1;
        
            for Productivity_Change_Index = 1:numel(Strengths);
                if Productivity_Change_Index~=1;
                    Gecco.AddRun();
                end
                Gecco.Runs(Productivity_Change_Index).AddChunk();
                
                % Make necessary changes
                Gecco.Runs(Productivity_Change_Index).Chunks(1).Time_In(2) = Change_Times(Time_Index);
                Gecco.Runs(Productivity_Change_Index).Chunks(1).Time_Out(2) = Change_Times(Time_Index);
                Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_In(1) = Change_Times(Time_Index);
                Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_Out(1) = Change_Times(Time_Index);
                Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_In(2) = Run_Length;
                Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_Out(2) = Run_Length;
                
                File = "/home/rw12g11/600ppm_14_Short.nc";
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Load(File);
                Gecco.LoadFinal(File);
                
                % CREATE THE DIRECTORY BEFORE RUNNING
                Gecco.Runs(Productivity_Change_Index).Information.Output_Filepath = "/scratch/rw12g11/Ca_Mg_Productivity_Sensitivity/10e6";
                Gecco.Runs(Productivity_Change_Index).Information.Output_Filename = strcat("T",num2str(Change_Times(Time_Index)),"CC",num2str(Calcium_At_Change(Calcium_Change_Index)),"MC",num2str(Magnesium_At_Change(Magnesium_Change_Index)),"P",num2str(Productivity_Change_Index),".nc");
                
                % Calculations for transients
                Calcium_Point = Calcium_At_Change(Calcium_Change_Index);
                Calcium_Time = Change_Times(Time_Index);
                
                Magnesium_Point = Magnesium_At_Change(Magnesium_Change_Index);
                Magnesium_Time = Magnesium_Change_Times(Time_Index);
                
                % Perform y = mx+c for both segments
                Calcium_m(1) = (Calcium_Point-Calcium_Start)/(Calcium_Time-0);
                Calcium_m(2) = (Calcium_End-Calcium_Point)/(Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_In(2)-Calcium_Time);
                
                Calcium_c(1) = Calcium_Start;
                Calcium_c(2) = Calcium_Point-(Calcium_m(2)*Calcium_Time);
                
                Magnesium_m(1) = (Magnesium_Point-Magnesium_Start)/(Magnesium_Time-0);
                Magnesium_m(2) = (Magnesium_End-Magnesium_Point)/(Gecco.Runs(Productivity_Change_Index).Chunks(2).Time_In(2)-Magnesium_Time);
                
                Magnesium_c(1) = Magnesium_Start;
                Magnesium_c(2) = Magnesium_Point-(Magnesium_m(2)*Magnesium_Time);
                
                % Add the right transients
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(1)),".*t)+",num2str(Calcium_c(1))))};
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Calcium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Calcium_m(2)),".*t)+",num2str(Calcium_c(2))))};
                
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(1,1:3) = {1,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(1)),".*t)+",num2str(Magnesium_c(1))))};
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Transients.Carbonate_Chemistry.Magnesium(2,:) = {2,':',str2func(strcat("@(t,Conditions)(",num2str(Magnesium_m(2)),".*t)+",num2str(Magnesium_c(2))))};
                
                % Do weathering calculations
                OceanArray = double(Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Architecture.Hypsometric_Bin_Midpoints<round(Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Initials.Sea_Level));
                
                Silicate_Weathering = (Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Initials.Conditions(12)*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Initials.Conditions(13).*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Weathering.Silicate_Weatherability);
                Carbonate_Weathering = sum((1-OceanArray).*(Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Initials.Seafloor.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Exposure).*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Initials.Carbonate_Weathering_Fraction.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Weathering.Carbonate_Weatherability);
                
                Phosphate_From_Silicate = Silicate_Weathering.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Silicate;
                Phosphate_From_Carbonate = Carbonate_Weathering.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Carbonate;
                
                % Manipulate the coefficients
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Silicate = Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Silicate.*Strengths(Productivity_Change_Index);
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Carbonate = Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Carbonate.*Strengths(Productivity_Change_Index);
                
                New_Phosphate_From_Silicate = Silicate_Weathering.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Silicate;
                New_Phosphate_From_Carbonate = Carbonate_Weathering.*Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Carbonate;
                
                Gecco.Runs(Productivity_Change_Index).Regions.Conditions.Constants.Phosphate.Proportionality_To_Nothing = (Phosphate_From_Silicate-New_Phosphate_From_Silicate) + (Phosphate_From_Carbonate-New_Phosphate_From_Carbonate);
            end
        
            % Submit job
            Gecco.RunModelOnIridis(Cluster);
        end        
    end
end