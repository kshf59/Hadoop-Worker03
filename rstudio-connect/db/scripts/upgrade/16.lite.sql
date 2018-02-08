ALTER TABLE schedule ADD COLUMN start_time DATETIME NULL; 
UPDATE schedule SET start_time = next_run;
