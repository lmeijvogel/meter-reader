DROP TABLE IF EXISTS measurements;

CREATE TABLE measurements (
  id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  time_stamp DATETIME,
  time_stamp_utc DATETIME,
  stroom_dal FLOAT,
  stroom_piek FLOAT,
  stroom_current FLOAT,
  gas FLOAT,
  water FLOAT,

  diff_stroom_dal FLOAT,
  diff_stroom_piek FLOAT,
  diff_gas FLOAT
);

CREATE INDEX measurement_time_index ON measurements(time_stamp);
