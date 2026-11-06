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

function testStylesBothYyaxisLabels(testCase)
% get(ax, 'YLabel') returns only the active side on yyaxis axes; both sides
% must get AxisFontSize. A datetime x-axis checks mixed ruler classes.
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
ax = axes(fig);
t = datetime(2020, 1, 1) + calmonths(0:9);
yyaxis(ax, 'left'); plot(ax, t, 1:10); ylabel(ax, 'Rate', 'FontSize', 20);
yyaxis(ax, 'right'); plot(ax, t, 10:-1:1); ylabel(ax, 'Level', 'FontSize', 20);
xlabel(ax, 'Month', 'FontSize', 20);
export_publication_figure(fig, 'yy.pdf', AxisFontSize=9);
labelSizes = arrayfun(@(ruler) ruler.Label.FontSize, ax.YAxis);
testCase.verifyEqual(labelSizes(:)', [9 9]);
testCase.verifyEqual(ax.XAxis.Label.FontSize, 9);
end

function testBareStringPathExportsWithoutWarning(testCase)
% A string path with no folder ("s.pdf") must not call mkdir("") (which
% warns on every export).
fig = figure('Units', 'inches', 'Position', [1 1 4 3]);
plot(1:3);
testCase.verifyWarningFree(@() export_publication_figure(fig, "s.pdf", ...
    PreviewPath="s.png"));
testCase.verifyTrue(isfile('s.pdf') && isfile('s.png'));
end

function testExportedPageMatchesFigureSize(testCase)
% On R2025a+ the PDF page and the PNG preview must be the requested size,
% not the tight crop, including when the same figure is re-exported at a
% new size (paper, then slides).
testCase.assumeFalse(isMATLABReleaseOlderThan("R2025a"), ...
    'exportgraphics Width/Height need R2025a+.');
fig = figure('Units', 'inches', 'Position', [1 1 8 7]);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl); plot(1:10); title('A'); xlabel('x'); ylabel('y');
nexttile(tl); plot(10:-1:1); title('B');
export_publication_figure(fig, 'paper.pdf', WidthInches=6.5, HeightInches=4, ...
    PreviewPath='paper.png', PreviewResolution=200);
testCase.verifyEqual(pdf_page_size('paper.pdf'), [468 288], 'AbsTol', 1);
info = imfinfo('paper.png');
testCase.verifyEqual([info.Width info.Height], [1300 800], 'AbsTol', 2);
export_publication_figure(fig, 'slides.pdf', WidthInches=4.5, HeightInches=3);
testCase.verifyEqual(pdf_page_size('slides.pdf'), [324 216], 'AbsTol', 1);
% No size passed: the caller's own figure size is exported exactly.
fig2 = figure('Units', 'inches', 'Position', [1 1 3.49 2.6]);
plot(1:3);
export_publication_figure(fig2, 'column.pdf');
testCase.verifyEqual(pdf_page_size('column.pdf'), [3.49 2.6] * 72, 'AbsTol', 1);
end

function testOlderReleasesExportWithoutSizeOptions(testCase)
% Before R2025a exportgraphics rejects Width/Height, so the helper must not
% pass them. Shadow isMATLABReleaseOlderThan to take that branch here.
shadowDir = fullfile(testCase.TestData.outDir, 'shadow');
mkdir(shadowDir);
fid = fopen(fullfile(shadowDir, 'isMATLABReleaseOlderThan.m'), 'w');
fprintf(fid, 'function tf = isMATLABReleaseOlderThan(varargin)\ntf = true;\nend\n');
fclose(fid);
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(shadowDir));
fig = figure('Units', 'inches', 'Position', [1 1 6.5 4]);
plot(1:3); xlabel('x'); ylabel('y');
export_publication_figure(fig, 'old.pdf', WidthInches=6.5, HeightInches=4);
pageSize = pdf_page_size('old.pdf');
% Cropped to the content: smaller than the figure, but not wildly so.
testCase.verifyLessThan(pageSize, [468 288]);
testCase.verifyGreaterThan(pageSize, [0.8 0.8] .* [468 288]);
end

function pageSize = pdf_page_size(pdfPath)
% Return [width height] in points from the PDF's first /MediaBox.
fid = fopen(pdfPath, 'r');
bytes = fread(fid, Inf, '*char')';
fclose(fid);
tokens = regexp(bytes, '/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)', ...
    'tokens', 'once');
box = str2double(tokens);
pageSize = box(3:4) - box(1:2);
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
