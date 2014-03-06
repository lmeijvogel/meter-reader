require "spec_helper"
require 'mysql2'

require ROOT_PATH.join "models/usage.rb"
require ROOT_PATH.join "lib/output/database_writer.rb"
require ROOT_PATH.join "lib/database_reader.rb"
require ROOT_PATH.join "lib/float_extensions.rb"

describe DatabaseReader do
  let(:time_stamp_1) { DateTime.now }
  let(:stroom_dal_1) { 12.23 }
  let(:stroom_piek_1) { 23.34 }
  let(:gas_1) { 12.23 }

  let(:time_stamp_2) { DateTime.now }
  let(:stroom_dal_2) { 13.23 }
  let(:stroom_piek_2) { 25.34 }
  let(:gas_2) { 12.23 }

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
    database_connection.query("INSERT INTO measurements(
                              time_stamp, stroom_dal, stroom_piek, gas)
                              VALUES ('#{time_stamp_1.new_offset(0)}', '#{stroom_dal_1}', '#{stroom_piek_1}', '#{gas_1}'),
                                     ('#{time_stamp_2.new_offset(0)}', '#{stroom_dal_2}', '#{stroom_piek_2}', '#{gas_2}')")

    reader.send(:granularity=, :hour)
    @usage = reader.read().first
  end

  it "sets the correct stroom_dal" do
    @usage.stroom_dal.should == stroom_dal_2 - stroom_dal_1
  end

  it "sets the correct stroom_piek" do
    @usage.stroom_piek.should == stroom_piek_2 - stroom_piek_1
  end

  it "sets the correct gas" do
    @usage.gas.should == gas_2 - gas_1
  end

  it "sets the correct time_stamp" do
    @usage.time_stamp.to_s.should == time_stamp_1.to_s
  end
end
