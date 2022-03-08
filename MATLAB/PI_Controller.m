% 48560 - Control Studio A
% Assessment Task 5 - Assignment 3
% University of Technology Sydney, Australia
% Spring 2020
%
%  Digital Control of a Grid-Connected Inverter
%
%  Run this Matlab script before running Simulink file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear;

%% Simulation Parameters
Tsim=0.1;       % Total simulation time
fpwm=20e3;      % PWM frequency
Tc=1/fpwm;      % Triangular Carrier Period
fs=2*fpwm;      % sampling frequency
Ts=1/fs;        % sampling period


%% System Parameters

Vg=240*sqrt(2);     % Peak grid voltage
fo=50;              % Grid Frequency in Hz

L=15e-3;            % Interface Inductance
R=1e-3;             % Interface Resistance

Vdc=400;            % DC-Voltage

%% Current Reference in Phase with Grid Voltage (No reactive power)
Pref=2000;          % Active Power in Watts.
Iref=2*Pref/Vg;     % Peak Current Reference


%% Open-Loop Pulse Transfer Function
% Obtain here your digital plant Go(z)
s=tf('s');
z=tf('z',Ts);

Goz=-6.6666/(z-1);

%% PI Controller Desing
% Design here a digital PI controller 
% CPIz=(Ka*z+Kb)/(z-1)
% Replace Ka and Kb by your design
Ka=-0.05866;
Kb=0.049031;
CPIz=(Ka*z+Kb)/(z-1);

%% Run Simulink

display('Simulating...')
sim('Inverter.slx')

%% Plotting results
% Modify all plots in order to properly display your results
% Add legends, axis labels, title, etc.
% Change the plotting range to clearly describe what you want/need
display('Ploting!!!')

%% Output Sensitivity 
So_PIz=1/(1+Goz*CPIz);

%% Closed-Loop Transfer Function 
T_PIz=1-So_PIz;
figure(1)
bode(T_PIz)
grid
title('Closed-Loop Transfer Function T_{PI}(z)','fontsize',16);

%duty cycle
figure(2)
plot(time, d,'LineWidth',2)
grid
title('Duty Cycle')
ylabel('Ratio')
xlabel('Time[s]')

% Inverter voltage
figure(3)
plot(time,vi,time, vg, 'LineWidth',2)
title('Inverter Voltage Vs Grid Voltage')
ylabel('Voltage[V]');
xlabel('Time[s]');
legend('Inverter Voltage', 'Grid Voltage');
grid

figure(4)
plot(time,ig_ref,'--k',time,ig,'r','LineWidth',2)
title('Input Reference Vs Grid Current');
ylabel('Current[A]');
xlabel('Time[s]')
legend('Grid Current Reference', 'Actual Grid Current');
grid


display('Done!!!')
