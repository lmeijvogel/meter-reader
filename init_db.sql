DROP TABLE measurements;

CREATE TABLE measurements (
  id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  time_stamp DATETIME,
  stroom_dal FLOAT,
  stroom_piek FLOAT,
  stroom_current FLOAT,
  gas FLOAT,

  diff_stroom_dal FLOAT,
  diff_stroom_piek FLOAT,
  diff_gas FLOAT
);
