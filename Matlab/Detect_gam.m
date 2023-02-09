function [ gamma ] = Detect_gam( num_CH, gam_CH, varargin )

%Gamma Detection
% input: total number of channels in recording, channel for gamma analysis
%          (+1 from neuroscope channel number), ensure .lfp file and -states.mat(from StateEditor) is in the folder
%      : uses OOP to load lfp and restrict to states
%      : uses FMAtoolbox adapted for detection, file saving, event file
%        saving
% gamma band = [50 80]
% durations = [30 300 60] (min inter-gamma interval, max gamma duration and
%                           min gamma duration, in ms)
% output: .mat file (named with fbasename+gam_CH)
%          column 1 = start; column 2 = peak; column 3 = end; column 4 =
%          power
%         .gam.evt file (named with fbasename+gam_CH)

%=========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     'gam_thresholds'  thresholds for gamma beginning/end and peak, in multiples
%                   of the stdev (default = [2 5])
%     'state'           select state between NREM, REM, WAKE

% Parse parameter list
for i = 1:2:length(varargin),
	if ~ischar(varargin{i}),
		error(['Parameter ' num2str(i+2) ' is not a property (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).']);
	end
	switch(lower(varargin{i})),
		case 'gam_thresholds',
			gam_thresholds = varargin{i+1};
			if ~isivector(gam_thresholds,'#2','>0'),
				error('Incorrect value for property ''thresholds'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
			end
			gam_lowThresholdFactor = gam_thresholds(1);
			gam_highThresholdFactor = gam_thresholds(2);
        case 'state',
			state = varargin{i+1};
			if ~isstring(state,'NREM','REM', 'WAKE'),
				error('Incorrect value for property ''state'' (type ''help <a href="matlab:help FindRipples">FindRipples</a>'' for details).');
			end
    end
end
            
filename = dir('*.lfp');
[pathstr, fbasename, fileSuffix] = fileparts(filename.name);
nchannels = num_CH;
gamma_channel = gam_CH;  
channelID = gamma_channel - 1;

state_mat = dir('*-states*');
load (state_mat.name);
StateIntervals = ConvertStatesVectorToIntervalSets(states);                 % 6 Intervalsets representing sleep states
REM = StateIntervals{5};
NREM = or(StateIntervals{2}, StateIntervals{3});
WAKE = StateIntervals{1};

% State parameter
if strcmp(state,'NREM'),
    state = NREM;
elseif strcmp(state, 'REM'),
        state = REM;
else strcmp(state, 'WAKE'),
    state = WAKE;
end


lfp = LoadLfp(fbasename,nchannels,gamma_channel);    
fil_sleep = FilterLFP([Range(Restrict(lfp, state), 's') Data(Restrict(lfp, state))], 'passband', [50 80]);
[gamma,sd,bad] = FindRipples(fil_sleep,'thresholds', [gam_lowThresholdFactor gam_highThresholdFactor], 'durations', [30 300 60]);


gamma_file = strcat(fbasename, num2str(gamma_channel), 'gamma');
save (gamma_file, 'gamma')
spindle_events = strcat(fbasename, num2str(gamma_channel), '.gam.evt');
SaveRippleEvents(spindle_events,gamma,channelID);


end

