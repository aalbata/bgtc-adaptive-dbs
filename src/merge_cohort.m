function merge_cohort(resDir, partDir)
%MERGE_COHORT Join cohort result parts into the files of the full run.
%   MERGE_COHORT(RESDIR, PARTDIR) concatenates, in subject order, the part
%   files written by EXP_COHORT(RESDIR, SUBJECTS, PARTDIR) and writes
%   cohort_subjects.csv, cohort_stationary.csv and cohort_change.csv to
%   RESDIR. The lines are copied as text, so the merged files are identical
%   to those of a single run over all subjects. An error is raised unless the
%   parts together hold subjects 1 to 200 exactly once.

bases = {'cohort_subjects', 'cohort_stationary', 'cohort_change'};
for b = 1:numel(bases)
    parts = dir(fullfile(partDir, [bases{b} '_*.csv']));
    names = sort({parts.name});
    out = {}; hdr = '';
    for k = 1:numel(names)
        txt = fileread(fullfile(partDir, names{k}));
        lines = regexp(txt, '\n', 'split');
        lines = lines(~cellfun(@isempty, lines));
        if isempty(hdr), hdr = lines{1};
        elseif ~strcmp(hdr, lines{1}), error('Header mismatch in %s', names{k}); end
        out = [out, lines(2:end)]; %#ok<AGROW>
    end
    if b == 1
        ids = cellfun(@(l) str2double(strtok(l, ',')), out);
        if ~isequal(sort(ids), 1:200) || numel(unique(ids)) ~= 200
            error('The parts do not hold subjects 1 to 200 exactly once.');
        end
    end
    fid = fopen(fullfile(resDir, [bases{b} '.csv']), 'w');
    fprintf(fid, '%s\n', hdr);
    fprintf(fid, '%s\n', out{:});
    fclose(fid);
end
end
