outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

rng(42);
x = linspace(0, 1, 11);

% Two concepts, one color each, in every panel.
inflationBaseline = 0.8 + 0.35 * sin(2 * pi * x) + 0.15 * x;
outputBaseline = 0.5 + 0.25 * cos(2 * pi * x + 0.4) + 0.25 * x .^ 1.4;
inflationAlternative = 0.3 + 0.4 * x + 0.08 * randn(size(x));
outputAlternative = 0.2 + 0.55 * x .^ 1.2 - 0.03 * cos(4 * pi * x);

colorInflation = [0.000, 0.447, 0.741];
colorOutput = [0.850, 0.325, 0.098];

% Final printed size: full text width (6.5 in) of a 1-in-margin letter page.
widthInches = 6.5;
heightInches = 5.0;

fig = figure('Color', 'white', 'Units', 'inches', ...
    'Position', [1 1 widthInches heightInches]);
outer = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

title(outer, 'Professional MATLAB Figure Layout Demo', ...
    'FontWeight', 'bold', 'FontSize', 12);
xlabel(outer, 'Parameter value');

ax1 = nexttile(outer, [1 2]);
plot_pair(ax1, x, inflationBaseline, outputBaseline, colorInflation, colorOutput);
ylabel(ax1, 'Response');
title(ax1, '{\bfA}  Baseline');

ax2 = nexttile(outer);
plot_pair(ax2, x, inflationAlternative, outputAlternative, colorInflation, colorOutput);
ylabel(ax2, 'Response');
title(ax2, '{\bfB}  Alternative specification');

ax3 = nexttile(outer);
plot_pair(ax3, x, inflationBaseline - inflationAlternative, ...
    outputBaseline - outputAlternative, colorInflation, colorOutput);
yline(ax3, 0, ':', 'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
ylabel(ax3, 'Difference');
title(ax3, '{\bfC}  Baseline minus alternative');

linkaxes([ax1, ax2], 'y');

% One shared legend docked above all tiles (the shared x label sits below);
% colors mean the same in every panel.
lgd = legend(ax1, 'Orientation', 'horizontal');
lgd.Layout.Tile = 'north';

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'matlab-plot-skill', 'scripts'));

export_publication_figure(fig, fullfile(outputDir, 'demo_publication_figure.pdf'), ...
    WidthInches=widthInches, HeightInches=heightInches, ...
    PreviewPath=fullfile(outputDir, 'demo_publication_figure.png'));

close(fig);

function plot_pair(ax, x, inflation, output, colorInflation, colorOutput)
% Inflation is always blue circles and output always orange squares.
hold(ax, 'on');
grid(ax, 'on');
plot(ax, x, inflation, '-o', 'Color', colorInflation, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Inflation');
plot(ax, x, output, '--s', 'Color', colorOutput, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Output');
xlim(ax, [0, 1]);
xticks(ax, 0:0.25:1);
end
