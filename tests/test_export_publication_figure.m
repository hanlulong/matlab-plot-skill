function tests = test_export_publication_figure
%TEST_EXPORT_PUBLICATION_FIGURE Regression tests for the export helper.
%   Run from the repository root:
%       matlab -batch "assertSuccess(runtests('tests'))"
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
scriptsDir = fullfile(fileparts(mfilename('fullpath')), '..', ...
    'matlab-plot-skill', 'scripts');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(scriptsDir));
end

function setup(testCase)
% Each test writes its exports into a fresh temporary working folder.
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
testCase.TestData.outDir = pwd;
end

function teardown(~)
close all force;
end

function testKeepsCallerSizeWhenNoSizePassed(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 8 7]);
plot(1:3);
export_publication_figure(fig, 'keep.pdf');
fig.Units = 'inches';
testCase.verifyEqual(fig.Position(3:4), [8 7], 'AbsTol', 0.02);
end

function testResizesOnlyPassedDimension(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 8 7]);
plot(1:3);
% The caller chose the height, so passing only the width must not warn.
testCase.verifyWarningFree(@() export_publication_figure(fig, 'width.pdf', ...
    WidthInches=6.5));
fig.Units = 'inches';
testCase.verifyEqual(fig.Position(3:4), [6.5 7], 'AbsTol', 0.02);
end

function testWarnsWhenOneDimensionKeepsDefault(testCase)
% 0.1.0 taught `fig = figure; ... WidthInches=6.5`; the height then stays at
% MATLAB's default, so the helper must warn and name the omitted dimension.
fig = figure;
plot(1:3);
testCase.verifyWarning(@() export_publication_figure(fig, 'w.pdf', ...
    WidthInches=6.5), 'export_publication_figure:defaultSize');
testCase.verifySubstring(default_size_warning(@() export_publication_figure( ...
    figure, 'w2.pdf', WidthInches=3.49)), 'HeightInches was not passed');
testCase.verifySubstring(default_size_warning(@() export_publication_figure( ...
    figure, 'h.pdf', HeightInches=4)), 'WidthInches was not passed');
end

function testWarnsOnDefaultSize(testCase)
fig = figure;
plot(1:3);
testCase.verifyWarning(@() export_publication_figure(fig, 'default.pdf'), ...
    'export_publication_figure:defaultSize');
fig2 = figure;
plot(1:3);
testCase.verifyWarningFree(@() export_publication_figure(fig2, 'sized.pdf', ...
    WidthInches=6.5, HeightInches=4));
end

function testKeepsLayoutSpacingUnlessPassed(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'loose', 'Padding', 'loose');
nexttile(tl); plot(1:3);
nexttile(tl); plot(3:-1:1);
export_publication_figure(fig, 'loose.pdf');
testCase.verifyEqual(char(tl.TileSpacing), 'loose');
testCase.verifyEqual(char(tl.Padding), 'loose');
export_publication_figure(fig, 'compact.pdf', TileSpacing="compact", LayoutPadding="tight");
testCase.verifyEqual(char(tl.TileSpacing), 'compact');
testCase.verifyEqual(char(tl.Padding), 'tight');
end

function testSuperTitleKeptUnlessPassed(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
tl = tiledlayout(fig, 1, 1);
nexttile(tl); plot(1:3);
title(tl, 'Super', 'FontSize', 14, 'FontWeight', 'bold');
xlabel(tl, 'Shared x');
export_publication_figure(fig, 'super.pdf', AxisFontSize=10);
testCase.verifyEqual(tl.Title.FontSize, 14);
testCase.verifyEqual(char(tl.Title.FontWeight), 'bold');
testCase.verifyEqual(tl.XLabel.FontSize, 10);
export_publication_figure(fig, 'super2.pdf', SuperTitleFontSize=12, ...
    SuperTitleFontWeight="Normal");
testCase.verifyEqual(tl.Title.FontSize, 12);
testCase.verifyEqual(char(tl.Title.FontWeight), 'normal');
end

function testTitleWeightIsCaseInsensitive(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
ax = axes(fig);
plot(ax, 1:3);
title(ax, 'Panel');
export_publication_figure(fig, 'bold.pdf', TitleFontWeight="Bold");
testCase.verifyEqual(char(ax.Title.FontWeight), 'bold');
end

function testUnifiesFontsIncludingTextAndConstantLines(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
ax = axes(fig);
plot(ax, 1:10);
text(ax, 2, 5, 'annotation', 'FontName', 'Helvetica');
xl = xline(ax, 5, '--', 'event', 'FontName', 'Helvetica');
export_publication_figure(fig, 'fonts.pdf');
testCase.verifyEqual(char(xl.FontName), 'Arial');
txt = findall(fig, 'Type', 'text', 'String', 'annotation');
testCase.verifyEqual(char(txt.FontName), 'Arial');
fonts = pdf_font_names(fullfile(testCase.TestData.outDir, 'fonts.pdf'));
if ~isempty(fonts)
    testCase.verifyTrue(all(contains(fonts, 'Arial')), strjoin(fonts, ', '));
end
end

function testDarkThemeExportsLight(testCase)
fig = figure('Units', 'inches', 'Position', [1 1 4 3]);
if ~isprop(fig, 'Theme') || exist('theme', 'file') ~= 2
    testCase.assumeFail('Figure themes require R2025a+.');
end
theme(fig, 'dark');
ax = axes(fig);
plot(ax, 1:3);
export_publication_figure(fig, 'dark.pdf', PreviewPath='dark.png');
testCase.verifyEqual(char(fig.Theme.BaseColorStyle), 'light');
img = imread('dark.png');
center = img(round(end/2), round(end/2), :);
testCase.verifyGreaterThan(min(center(:)), 200, 'Plot box should be light.');
end

function msg = default_size_warning(fcn)
% Run fcn with the defaultSize warning promoted to an error and return its
% message ('' if it was not raised).
state = warning('error', 'export_publication_figure:defaultSize');
restore = onCleanup(@() warning(state));
msg = '';
try
    fcn();
catch err
    if strcmp(err.identifier, 'export_publication_figure:defaultSize')
        msg = err.message;
    else
        rethrow(err);
    end
end
end

function fonts = pdf_font_names(pdfPath)
% Return the font names pdffonts lists, or {} when pdffonts is unavailable.
fonts = {};
[status, out] = system(sprintf('pdffonts "%s"', pdfPath));
if status ~= 0
    return;
end
lines = splitlines(strtrim(out));
for k = 3:numel(lines)   % skip the two header lines
    parts = split(strtrim(lines{k}));
    if ~isempty(parts) && strlength(parts{1}) > 0
        fonts{end + 1} = parts{1}; %#ok<AGROW>
    end
end
end
