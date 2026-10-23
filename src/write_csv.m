function write_csv(file, header, data)
%WRITE_CSV Write a numeric or mixed table with a fixed number format.
%   WRITE_CSV(FILE, HEADER, DATA) writes the cell array of column names
%   HEADER and the rows of DATA. DATA is a numeric matrix or a cell array
%   whose entries are numbers or character vectors. Numbers are written
%   with 12 significant digits so that repeated runs give identical files.

fid = fopen(file, 'w');
if fid < 0, error('Cannot open %s', file); end
c = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', strjoin(header, ','));
if isnumeric(data), data = num2cell(data); end
for i = 1:size(data, 1)
    row = cell(1, size(data, 2));
    for j = 1:size(data, 2)
        v = data{i, j};
        if ischar(v) || isstring(v)
            row{j} = char(v);
        elseif isnan(v)
            row{j} = 'NaN';
        else
            row{j} = sprintf('%.12g', v);
        end
    end
    fprintf(fid, '%s\n', strjoin(row, ','));
end
end
