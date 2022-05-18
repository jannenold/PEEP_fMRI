function log_meta_data(P)

% write to event text file
f_id = fopen(P.path.filename_meta,'a+');
fprintf(f_id,'%d\t%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\n', P.protocol.subID,P.project.part, P.protocol.day,P.experiment.cuff_arm,P.experiment.thermode_arm, ...
    P.subject.age, P.subject.gender,P.pharmacological.day2,P.pharmacological.day3);
fclose(f_id);

end