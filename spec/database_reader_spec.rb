require "spec_helper"
require 'mysql2'

require "p1_meter_reader/models/usage"
require "output/database_writer"
require "database_reader"

class Measurement < Struct.new(:time_stamp, :stroom_dal, :stroom_piek, :gas)
  def columns_str
    members.join(", ")
  end

  def values_str
    values
      .map { |m| "'#{m}'" }
      .join(", ")
  end
end

describe DatabaseReader do
  let(:measurement_1) { Measurement.new( DateTime.now, 12.23, 23.34, 12.23 ) }
  let(:measurement_2) { Measurement.new( DateTime.now, 13.23, 25.34, 12.23 ) }

  let(:config) { YAML.load(File.read(File.join(ROOT_PATH.join("database.yml"))))["test"] }
  let(:database_connection) { Mysql2::Client.new(host: config["host"],
                                                 database: config["database"],
                                                 username: config["username"],
                                                 password: config["password"])
  }

  let(:writer) { DatabaseWriter.new(database_connection) }
  let(:reader) { DatabaseReader.new(database_connection) }

  before do
    database_connection.query("DELETE FROM measurements")
    [measurement_1, measurement_2].each do |measurement|
      database_connection.query("INSERT INTO measurements(#{measurement.columns_str})
                                VALUES (#{measurement.values_str})")
    end

    reader.send(:granularity=, :hour)
    @usage = reader.read().first
  end

  it "sets the correct stroom_totaal" do
    stroom_totaal = measurement_1.stroom_dal + measurement_1.stroom_piek


    @usage.stroom_totaal.should be_within(0.01).of(stroom_totaal)
  end

  it "sets the correct gas" do
    @usage.gas.should be_within(0.01).of(measurement_1.gas)
  end

  it "sets the correct time_stamp" do
    @usage.time_stamp.to_s.should == measurement_1.time_stamp.to_s
  end
end
