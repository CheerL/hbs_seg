function [out1, out2] = insertVectorElements(in1, in2, new1, new2, indexOfPrecedingElement)
% Insert additional elements into vectors in1 and in2 from vectors new1 and
% new2, returning vectors out1 and out2 with length equal to:
%
%    length(in1) + length(new1) == length(in2) + length(new2)
%
% Input indexOfPrecedingElement matches new1 and new2 in size and indicates
% which element of in1 should precede a given value from new1, and likewise for
% in2 and new2. To insert a run of N elements from new1 and new2, repeat the
% same value N times in indexOfPrecedingElement. All inputs and outputs are row
% vectors.
%
% Example
% -------
% indexOfPrecedingElement = [6 10 17 17 17 24];
% in = 101:130;
% new = -(21:26);
% out = map.internal.insertVectorElements(in, in, new, new, indexOfPrecedingElement)

% Copyright 2022 The MathWorks, Inc.

    arguments
        in1 (1,:)
        in2 (1,:)
        new1 (1,:)
        new2 (1,:)
        indexOfPrecedingElement (1,:) {mustBeNumeric}
    end

    [indexOfPrecedingElement, I] = sort(indexOfPrecedingElement);
    new1 = new1(I);
    new2 = new2(I);
    out1 = zeros(1, length(in1) + length(new1));
    out2 = out1;
    ei = 0;
    eo = 0;
    runlen = diff([0 indexOfPrecedingElement]);
    for k = 1:length(indexOfPrecedingElement)
        si = ei + 1;
        ei = ei + runlen(k);
        so = eo + 1;
        eo = eo + runlen(k);
        out1(so:eo) = in1(si:ei);
        out2(so:eo) = in2(si:ei); 
        eo = eo + 1;
        j = indexOfPrecedingElement(k) + k;
        out1(j) = new1(k);
        out2(j) = new2(k);
    end
    si = ei + 1;
    so = eo + 1;
    out1(so:end) = in1(si:end);
    out2(so:end) = in2(si:end); 
end
