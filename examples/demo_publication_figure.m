outputDir = fullfile(fileparts(mfilename('fullpath')), 'output');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

rng(42);
x = linspace(0, 1, 11);

y1 = 0.8 + 0.35 * sin(2 * pi * x) + 0.15 * x;
y2 = 0.5 + 0.25 * cos(2 * pi * x + 0.4) + 0.25 * x .^ 1.4;
y3 = 0.3 + 0.4 * x + 0.08 * randn(size(x));
y4 = 0.2 + 0.55 * x .^ 1.2 - 0.03 * cos(4 * pi * x);

fig = figure('Color', 'white', 'Units', 'inches', 'Position', [1 1 8.4 6.5]);
outer = tiledlayout(fig, 2, 2, 'TileSpacing', 'loose', 'Padding', 'compact');

colorInflation = [0.000, 0.447, 0.741];
colorOutput = [0.850, 0.325, 0.098];

title(outer, 'Professional MATLAB Figure Layout Demo', ...
    'FontWeight', 'bold', 'FontSize', 13);

ax1 = nexttile(outer, [1 2]);
hold(ax1, 'on');
grid(ax1, 'on');
plot(ax1, x, y1, '-o', 'Color', colorInflation, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Inflation response');
plot(ax1, x, y2, '--s', 'Color', colorOutput, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Output response');
ylabel(ax1, 'Response');
title(ax1, 'Panel A: Two Cleanly Distinguished Series');
xlim(ax1, [0, 1]);

leftAx = nexttile(outer);
hold(leftAx, 'on');
grid(leftAx, 'on');
plot(leftAx, x, y3, '-^', 'Color', colorInflation, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Policy coefficient A');
plot(leftAx, x, y4, ':d', 'Color', colorOutput, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Policy coefficient B');
title(leftAx, 'Readable Titles');
xlabel(leftAx, 'Parameter value');
ylabel(leftAx, 'Coefficient');
xlim(leftAx, [0, 1]);

rightAx = nexttile(outer);
hold(rightAx, 'on');
grid(rightAx, 'on');
plot(rightAx, x, y1 - y2 + 0.55, '-o', 'Color', colorInflation, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Layout quality');
plot(rightAx, x, y4, '--d', 'Color', colorOutput, ...
    'MarkerFaceColor', 'white', 'DisplayName', 'Readability quality');
title(rightAx, 'Balanced White Space');
ylabel(rightAx, 'Score');
xlabel(rightAx, 'Parameter value');
xlim(rightAx, [0, 1]);

legend(ax1, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 2, 'Box', 'off');

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'matlab-plot-skill', 'scripts'));

export_publication_figure(fig, fullfile(outputDir, 'demo_publication_figure.pdf'), ...
    WidthInches=8.4, HeightInches=6.5, LayoutPadding="compact", TileSpacing="compact", ...
    PreviewPath=fullfile(outputDir, 'demo_publication_figure.png'));

close(fig);
