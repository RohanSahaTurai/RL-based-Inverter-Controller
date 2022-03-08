%% Simulation Parameters
Tf=0.02;        % Total simulation time %0.05
fpwm=20e3;       % PWM frequency
Tc=1/fpwm;      % Triangular Carrier Period
fs=2*fpwm;      % sampling frequency %2*fpwm
Ts=1/fs;        % sampling period
Tstep = Ts/500;

mdl = 'DQN_inverter_sim2';

%% System Parameters
Vg=240*sqrt(2);     % Peak grid voltage
fo=50;              % Grid Frequency in Hz

L=15e-3;            % Interface Inductance
R=1e-3;             % Interface Resistance

Vdc=400;            % DC-Voltage

%% Current Reference in Phase with Grid Voltage (No reactive power)
Pref=2000;          % Active Power in Watts.
Iref=2*Pref/Vg;     % Peak Current Reference


%% Environment
obsInfo = rlNumericSpec([2 1]);
obsInfo.Name = 'observations';
obsInfo.Description = 'ig_ref, ig, vg, vi';
numObservations = obsInfo.Dimension(1);

actInfo = rlFiniteSetSpec([0,1,2]);
actiInfo.Name = 'actions';
numActions = actInfo.Dimension(1);

% environment interface object
env = rlSimulinkEnv(mdl, [mdl '/RL Agent'], ...
    obsInfo, actInfo);

% reset variables at the start of episodes
env.ResetFcn = @(in)resetVars(in, mdl, Vg);

%% DNN for DQN Agent
dnn = [
    featureInputLayer(obsInfo.Dimension(1),'Normalization','none','Name','state')
    fullyConnectedLayer(32,'Name','CriticStateFC1')
    reluLayer('Name','CriticRelu1')
    fullyConnectedLayer(32, 'Name','CriticStateFC2')
    reluLayer('Name','CriticCommonRelu2')
    fullyConnectedLayer(length(actInfo.Elements),'Name','output')];

%% Critic
criticOpts = rlRepresentationOptions('LearnRate',1e-4,'GradientThreshold',1,'L2RegularizationFactor',1e-4);

critic = rlQValueRepresentation(dnn, obsInfo, actInfo, 'Observation', {'state'}, criticOpts);

%% DQN Agent
agentOpts = rlDQNAgentOptions(...
    'SampleTime', Ts, ...
    'UseDoubleDQN', false, ...    
    'TargetSmoothFactor', 1e-3, ...
    'TargetUpdateFrequency', 100, ...   
    'ExperienceBufferLength', 1e6, ...
    'DiscountFactor', 0.9, ...
    'MiniBatchSize', 256);

agentOpts.EpsilonGreedyExploration.Epsilon = 1.0;
agentOpts.EpsilonGreedyExploration.EpsilonMin = 0.01; 
agentOpts.EpsilonGreedyExploration.EpsilonDecay = 1e-4;

agent = rlDQNAgent(critic,agentOpts);

%% Training
trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 1000, ...
    'MaxStepsPerEpisode', ceil(Tf/Ts), ...
    'Verbose', true, ...
    'Plots','training-progress',...
    'StopTrainingCriteria','AverageReward',...
    'StopTrainingValue',-21);

trainingStats = train(agent,env,trainOpts);


%% Simulate
% simOpts = rlSimulationOptions('MaxSteps', ceil(Tf/Ts));
% experience = sim(env, agent, simOpts);
% plot(experience.Action.act1)

%% function to reset variables at the start of the  episode
function in = resetVars(in, mdl, Vg)
    
    Pref=randi(3000)+2000;  % Active Power in Watts.
%     Pref = 2000;
    Iref=2*Pref/Vg;         % Peak Current Reference
    
    blk = [mdl '/ig_ref/sine'];
    in = setBlockParameter(in, blk, 'Amplitude', num2str(Iref));
end