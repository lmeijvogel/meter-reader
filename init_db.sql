DROP TABLE IF EXISTS measurements;

CREATE TABLE measurements (
  id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
  time_stamp DATETIME,
  time_stamp_utc DATETIME,
  stroom FLOAT,
  gas FLOAT,
  water FLOAT,
);

CREATE INDEX measurement_time_index ON measurements(time_stamp);
