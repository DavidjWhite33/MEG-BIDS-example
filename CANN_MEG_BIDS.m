%% BIDS - MEG %%
% Background: The Brain Imaging Data Structure is a standard for organising
% and describing neuroimaging datasets.(BIDS;
% https://bids.neuroimaging.io/) MEG-BIDS is the magnetoencephalography
% extension of BIDS:
% https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/02-magnetoencephalography.html
%
% A number of options exist to assist in converting a raw MEG dataset to a
% BIDS compliant structure. For example: 1. MNE has MNE-BIDS
% https://mne.tools/mne-bids/ 2. 'Biscuit' - a python GUI from Macquarie
% University, using MNE-BIDS and associated functions.
% https://macquarie-meg-research.github.io/Biscuit/ 3. Fieldtrip has
% 'data2bids'. http://www.fieldtriptoolbox.org/reference/data2bids/

% If converting relatively small datasets, or incrementally as project is
% running, Biscuit is a very useful tool. Where large datasets are to be
% converted, a scripting solution (eg. using MNE-BIDS in python or
% data2bids in Fieldtrip/MATLAB seems the best approach (in the interests
% of consistency and time)

% Below is an example usage of data2bids to generate a BIDS compliant
% dataset from MEG data collected on the Elekta Neuromag system at
% Swinburne University, in Melbourne, Australia. Author: David White,
% davidjwhite33@gmail.com

% The dataset is from a multi-site clinical trial exploring a 12-month
% nutrional intervention in older adults with subjective memory impairments
% or mild cognitive impairment (The 'CANN' trial;
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6222033/). MEG data is
% collected at the Melbourne (Swinburne ) site only, with 2 runs of a
% virtual water maze task in addition to 2 resting recordings (6 mins each,
% eyes open, fixation cross). Data was acquired at baseline and after 12
% months treatment.

% Data has been pulled from the Swinburne MEG data storage
% (neuro-mgmt1.cc.swin.edu.au:projects/sinuhe_MEG_data), in this case using
% rsync to manage a local copy of the acquired data over the course of the
% project.

% Directory stucture on this storage uses acquisition date to store data in
% directories within a project folder, with raw MEG data (.fif) are as
% named when acquired. Manual intervention has placed all raw files in a
% single directory, with files named according to ID|task|session, eg.
% 001_rest1_V1.fif. Unfortunately, files have upper or lower case..

% The script below will generate a bids-compliant structure.
% Some additional notes to consider: 
% 1. README file in bids_dir is not generated by this
% script: "a free form text file (README) describing the dataset in more
% details SHOULD be provided. The README file MUST be either in ASCII or
% UTF-8 encoding". 
% 2. coordsystem.json sidecars (optional): head coil
% coordinates not currently written by data2bids, so this recommended info is
% is not in coordsystem.json sidecars ('Biscuit' will read the from the
% fif) 
% 3. channels.tsv files do not contain filter settings, nor info of
% the EOG/ECG channels (these just retain raw labels (BIO001))
% 4. events.json file (optional) could be written ("As with all
% other tabular data, _events files may be accompanied by a JSON file
% describing the columns in detail")


%% Data locations
raw_dir = '/Volumes/CANN/MEG_RAW/raw_restructure/' ;
bids_dir = '/Volumes/CANN/MEG_BIDS/';
problem_log = '/Volumes/CANN/MEG_RAW/raw_restructure/problem_files.txt';
fieldtrip_dir = '/Users/dawhite/Documents/MATLAB/fieldtrip';
addpath(fieldtrip_dir); ft_defaults;

%list fif files within raw_dir
datafiles=dir([raw_dir,'*.*fif']);
datafiles=datafiles(~startsWith({datafiles.name},'._'));
nfifs=length(datafiles); %how many fif files have we found to convert



%% Loop for each datafile
for s=1:nfifs
    
    %% Globals
    %These are (ideally) the same for all scans in a project
    cfg = [];
    cfg.method = 'copy'; % can use 'convert' if doing DICOMs, or 'decorate' if directory structure and filenames are all in BIDS
    cfg.datatype = 'meg';
    
    cfg.bidsroot = bids_dir; %output directory
    cfg.InstitutionName             = 'Swinburne University of Technology';
    cfg.InstitutionAddress          = 'ATC building, 427-451 Burwood Rd. Hawthorn, 3122, VIC, AUSTRALIA';
    cfg.InstitutionalDepartmentName = 'Centre for Human Psychopharmacology / Swinburne Neuroimaging';
    cfg.Manufacturer                = 'Elekta/Neuromag';
    cfg.ManufacturersModelName      = 'TRIUX';
    %   cfg.DeviceSerialNumber          = string
    %   cfg.SoftwareVersions            = string
    
    cfg.dataset_description.writesidecar = 'yes';
    cfg.dataset_description.Name = 'CANN';
    cfg.dataset_description.BIDSVersion = '1.2';
    cfg.dataset_description.Authors             = {'David White', 'Brian Cornwell', 'Andrew Scholey (Swinburne Trial Site PI)'};
    cfg.dataset_description.Acknowledgements    = 'The authors acknowledge the facilities, and the scientific and technical assistance of the National Imaging Facility at the Swinburne University Neuroimaging Facility.';
    cfg.dataset_description.Funding             = 'The research was funded in part by Abbott Nutrition via a Center for Nutrition, Learning, and Memory (CNLM) grant to the University of Illinois, which in turn awarded a research grant to the authors through a competitive peer reviewed process.';
    cfg.dataset_description.ReferencesAndLinks  = {'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6222033/'};
    %   cfg.dataset_description.DatasetDOI          = [];
    %   cfg.dataset_description.License             = string
    %   cfg.dataset_description.HowToAcknowledge    = string
    
    
    % MEG specific fields:
    cfg.meg.PowerLineFrequency            = 50; % REQUIRED. Frequency (in Hz) of the power grid at the geographical location of the MEG instrument (i.e. 50 or 60)
    cfg.meg.DewarPosition                 = 'upright'; % REQUIRED. Position of the dewar during the MEG scan: "upright", "supine" or "degrees" of angle from vertical: for example on CTF systems, upright=15??, supine = 90??.
    cfg.meg.SoftwareFilters               = nan; % REQUIRED. List of temporal and/or spatial software filters applied, orideally key:valuepairsofpre-appliedsoftwarefiltersandtheir parameter values: e.g., {"SSS": {"frame": "head", "badlimit": 7}}, {"SpatialCompensation": {"GradientOrder": Order of the gradient compensation}}. Write "n/a" if no software filters applied.
    cfg.meg.DigitizedLandmarks            = true(1); %or false(1), takes logical input % REQUIRED. Boolean ("true" or "false") value indicating whether anatomical landmark points (i.e. fiducials) are contained within this recording.
    cfg.meg.DigitizedHeadPoints           = true(1); %or false(1), takes logical input % REQUIRED. Boolean ("true" or "false") value indicating whether head points outlining the scalp/face surface are contained within this recording.
    cfg.meg.EOGChannelCount               = 1; % OPTIONAL. Number of EOG channels
    cfg.meg.ECGChannelCount               = 1; % OPTIONAL. Number of ECG channels
    %cfg.meg.MiscChannelCount              = ft_getopt(cfg.meg, 'MiscChannelCount'            ); % OPTIONAL. Number of miscellaneous analog channels for auxiliary signals
    cfg.meg.TriggerChannelCount           = 1; % OPTIONAL. Number of channels for digital (TTL bit level) triggers
    cfg.meg.RecordingType                 = 'continuous'; % OPTIONAL. Defines whether the recording is "continuous" or "epoched"; this latter limited to time windows about events of interest (e.g., stimulus presentations, subject responses etc.)
    cfg.meg.ContinuousHeadLocalization    = true(1); %or false(1), takes logical input % OPTIONAL. Boolean ("true" or "false") value indicating whether continuous head localisation was performed.
    cfg.meg.HeadCoilFrequency             = [293, 307, 314, 321, 328]; % OPTIONAL. List of frequencies (in Hz) used by the head localisation coils ("HLC" in CTF systems, "HPI" in Neuromag/Elekta, "COH" in 4D/BTi) that track the subject's head position in the MEG helmet (e.g. [293, 307, 314, 321])
    cfg.meg.EEGChannelCount               = 0; % OPTIONAL. Number of EEG channels recorded simultaneously (e.g. 21)
    cfg.meg.ECOGChannelCount              = 0; % OPTIONAL. Number of ECoG channels
    cfg.meg.SEEGChannelCount              = 0; % OPTIONAL. Number of SEEG channels
    cfg.meg.EMGChannelCount               = 0; % OPTIONAL. Number of EMG channels
%    cfg.meg.HardwareFilters               = struct('low_cutoff', 0.10000000149011612,'high_cutoff', 330.0); % RECOMMENDED. List of temporal hardware filters applied. Ideally key:value pairs of pre-applied hardware filters and their parameter values: e.g., {"HardwareFilters": {"Highpass RC filter": {"Half amplitude cutoff (Hz)": 0.0159, "Roll-off": "6dB/Octave"}}}. Write n/a if no hardware filters applied.
    
    %cfg.meg.SamplingFrequency             = this is read from the fif header; % REQUIRED.
    %cfg.meg.MEGChannelCount               = this is read from the fif header; % OPTIONAL. Number of MEG channels (e.g. 275)
    %cfg.meg.MEGREFChannelCount            = this is read from the fif header; % OPTIONAL. Number of MEG reference channels (e.g. 23). For systems without such channels (e.g. Neuromag Vectorview), MEGREFChannelCount"=0
    %cfg.meg.RecordingDuration             = this is read from the fif; % OPTIONAL. Length of the recording in seconds (e.g. 3600)
    %cfg.meg.EpochLength                   = []; % OPTIONAL. Duration of individual epochs in seconds (e.g. 1) in case of epoched data
    %cfg.meg.MaxMovement                   = ft_getopt(cfg.meg, 'MaxMovement'                 ); % OPTIONAL. Maximum head movement (in mm) detected during the recording, as measured by the head localisation coils (e.g., 4.8)
    %cfg.meg.SubjectArtefactDescription    = ft_getopt(cfg.meg, 'SubjectArtefactDescription'  ); % OPTIONAL. Freeform description of the observed subject artefact and its possible cause (e.g. "Vagus Nerve Stimulator", "non-removable implant"). If this field is set to "n/a", it will be interpreted as absence of major source of artifacts except cardiac and blinks.
    
    
%    cfg.channels.low_cutoff = 0.10000000149011612 ; %Note: fieldtrip doesn't currently read this form the fif file, and data2bids won't take hard coding in this way % OPTIONAL. Frequencies used for the high-pass filter applied to the channel in Hz. If no high-pass filter applied, use n/a.
%    cfg.channels.high_cutoff = 330.0 ;  %Note: fieldtrip doesn't currently read this form the fif file, and data2bids won't take hard coding in this way  % OPTIONAL. Frequencies used for the low-pass filter applied to the channel in Hz. If no low-pass filter applied, use n/a. Note that hardware anti-aliasing in A/D conversion of all MEG/EEG electronics applies a low-pass filter; specify its frequency here if applicable.
   
    
    %% Dataset-specific inputs
    %These are those inputs which are specific to the datafile at hand.
    %Largely determined from the file itself
    
    cfg.dataset = fullfile(datafiles(s).folder,datafiles(s).name); %define the raw dataset
    curr_file = split(datafiles(s).name,'_'); %get sub, task, session from raw filename
    curr_file = erase(curr_file,'.fif');%remove fif extension
    sess_date = datestr(datafiles(s).date,'yyyyMMdd'); %session date, used for empty room recordings, taken from file creation - this is definitely not ideal. should be formatted according to  RFC3339 as '2019-05-22T15:13:38'
    cfg.sub = char(curr_file(1)); %subject from filename
    cfg.scans.acq_time = datestr(datafiles(s).date,'yyyy-mm-ddThh:MM:SS'); %acquisition time, taken from file creation - this is definitely not ideal
    cfg.meg.AssociatedEmptyRoom = strcat('sub-emptyroom/ses-',sess_date,'/meg/sub-emptyroom_ses-',sess_date,'_task-noise_meg.fif'); % OPTIONAL. Relative path in BIDS folder structure to empty-room file associated with the subjects MEG recording. The path needs to use forward slashes instead of backward slashes (e.g. "sub-emptyroom/ses-<label>/meg/sub-emptyroom_ses-<label>_ta sk-noise_run-<label>_meg.ds").
    
    % When specifying the output directory in cfg.bidsroot, you can also specify
    % additional information to be added as extra columns in the participants.tsv and
    % scans.tsv files. For example:
    %   cfg.participant.age         = scalar
    %   cfg.participant.sex         = string, 'm' or 'f'
    
    
    %session from filename (sessions will be ses-v1 or ses-v2)
    if curr_file(3)=='v1' || curr_file(3)=='V1'
        cfg.ses = 'v1';
    elseif curr_file(3)=='v2' || curr_file(3)=='V2'
        cfg.ses = 'v2';
    else
        disp('PROBLEM: unable to determine session from filename')
    end
    
    %task and run from filename
    switch curr_file(2)
        case {'rest1' 'REST1'}
            cfg.task = 'rest'; cfg.run = 1; cfg.TaskName='rest';
            cfg.TaskDescription = 'Beginning of session resting recordings with eyes open, central fixation cross, rest period (min 6 minutes)';
            cfg.Instructions = 'Participants were instructed to relax and remain as still as possible, while keeping their eyes focussed on the central fixation cross';
            cfg.CogAtlasID = 'http://www.cognitiveatlas.org/task/id/trm_4c8a834779883/';
            cfg.CogPOID = 'http://wiki.cogpo.org/index.php?title=Rest';
            data2bids(cfg)
    
        case {'rest2' 'REST2'}
            cfg.task = 'restbreak'; cfg.run = 1; cfg.TaskName='restbreak';
            cfg.TaskDescription = 'After first run of watermaze task, resting recordings with eyes open, central fixation cross, rest period (min 6 minutes)';
            cfg.Instructions = 'Participants were instructed to relax and remain as still as possible, while keeping their eyes focussed on the central fixation cross';
            cfg.CogAtlasID = 'http://www.cognitiveatlas.org/task/id/trm_4c8a834779883/';
            cfg.CogPOID = 'http://wiki.cogpo.org/index.php?title=Rest';
            data2bids(cfg)
       
        case {'watermaze1' 'WATERMAZE1'}
            cfg.task = 'watermaze'; cfg.run = 1; cfg.TaskName = 'watermaze';
            cfg.TaskDescription = 'Virtual Morris Watermaze. First run involves 30 trials, most with platform visible. Probe trials intermixed, in which platform is hidden for 30 seconds and only emerges a this point if participant has not located it.';
            cfg.Instructions = 'Try and navigate to the platform as quickly and directly as possible. Some trials the platform will be visible, others it will not, but it is important to seek it out, as the platform may just be hidden.';
            cfg.CogAtlasID = 'http://www.cognitiveatlas.org/task/id/trm_4f241173868a3/';
            %cfg.CogPOID = 'http://wiki.cogpo.org/index.php';
            data2bids(cfg)
       
        case {'watermaze2' 'WATERMAZE2'}
            cfg.task = 'watermaze'; cfg.run = 2; cfg.TaskName = 'watermaze';
            cfg.TaskDescription = 'Virtual Morris Watermaze. Second run involves 4 trials, 2 with platform visible but no external cues, 2 with learned environment but no platform to assess long term retention. In blank control trials, participants asked to just explore the environment, with no platform.';
            cfg.Instructions = 'Try and navigate to the platform as quickly and directly as possible. In trials with no cues on the walls, please explore the environment (keep moving about). In trials with familiar environment, please try and navigate to the platform.';
            cfg.CogAtlasID = 'http://www.cognitiveatlas.org/task/id/trm_4f241173868a3/';
            %cfg.CogPOID = 'http://wiki.cogpo.org/index.php';
            data2bids(cfg)
       
        case {'empty' 'EMPTY'}
            cfg.sub = 'emptyroom'; cfg.task = 'noise'; cfg.TaskName = 'noise'; cfg.ses=sess_date;
            %Edit to allow for multiple empty room recordings on one day?
            data2bids(cfg)
    
        otherwise
            disp('PROBLEM: unable to determine task from filename')
            fID=fopen(problem_log,'a+'); fprintf(fID,'%s \n',datafiles(s).name); fclose(fID);
    end
    
    
end






