require 'yaml'
require 'mysql2'
require 'spec_helper'

require ROOT_PATH.join("lib/float_extensions.rb")
require ROOT_PATH.join("lib/output/database_writer.rb")
require ROOT_PATH.join("models/measurement.rb")

describe DatabaseWriter do
  describe :save do
    let(:time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23.kWh }
    let(:stroom_piek) { 23.34.kWh }
    let(:stroom_current) { 0.23 }
    let(:diff_stroom_dal) { 14.23.kWh }
    let(:diff_stroom_piek) { 15.23.kWh }
    let(:gas) { 12.23 }

    let(:config) { YAML.load(File.read(File.join(ROOT_PATH.join("database.yml"))))["test"] }
    let(:database_connection) { Mysql2::Client.new(host: config["host"],
                                                   database: config["database"],
                                                   username: config["username"],
                                                   password: config["password"])
    }

    let(:writer) { DatabaseWriter.new(database_connection) }

    before do
      @measurement = Measurement.new
      @measurement.time_stamp = time_stamp
      @measurement.stroom_dal = stroom_dal
      @measurement.stroom_piek = stroom_piek
      @measurement.stroom_current = stroom_current
      @measurement.diff_stroom_dal = diff_stroom_dal
      @measurement.diff_stroom_piek = diff_stroom_piek
      @measurement.gas = gas

      database_connection.query("DELETE FROM measurements")
    end

    it "adds a row to the SQL backend" do
      expect {
        writer.save(@measurement)
      }.to change { database_connection.query("SELECT * FROM measurements").count }.by(1)
    end

    describe "the result" do
      subject { database_connection.query("SELECT * FROM measurements").first }

      before do
        writer.save(@measurement)
      end

      it "should have the correct stroom_dal" do
        subject["stroom_dal"].should == stroom_dal.to_f
      end

      it "should have the correct stroom_piek" do
        subject["stroom_piek"].should == stroom_piek.to_f
      end

      it "should have the correct diff_stroom_dal" do
        subject["diff_stroom_dal"].should == diff_stroom_dal.to_f
      end

      it "should have the correct diff_stroom_piek" do
        subject["diff_stroom_piek"].should == diff_stroom_piek.to_f
      end

      it "should have the correct stroom_current" do
        subject["stroom_current"].should == stroom_current
      end

      it "should have the correct gas" do
        subject["gas"].should == gas
      end

      it "should have the correct timestamp" do
        subject["time_stamp"].to_datetime.to_s.should == time_stamp.to_s
      end
    end
  end

  describe :exists? do
    let(:existing_time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23.kWh }
    let(:stroom_piek) { 23.34.kWh }
    let(:stroom_current) { 0.23 }
    let(:diff_stroom_dal) { 14.23.kWh }
    let(:diff_stroom_piek) { 15.23.kWh }
    let(:gas) { 12.23 }

    let(:config) { YAML.load(File.read(File.join(ROOT_PATH.join("database.yml"))))["test"] }
    let(:database_connection) { Mysql2::Client.new(host: config["host"],
                                                   database: config["database"],
                                                   username: config["username"],
                                                   password: config["password"])
    }

    let(:writer) { DatabaseWriter.new(database_connection) }

    before do
      @measurement = Measurement.new
      @measurement.time_stamp = existing_time_stamp
      @measurement.stroom_dal = stroom_dal
      @measurement.stroom_piek = stroom_piek
      @measurement.stroom_current = stroom_current
      @measurement.diff_stroom_dal = diff_stroom_dal
      @measurement.diff_stroom_piek = diff_stroom_piek
      @measurement.gas = gas

      database_connection.query("DELETE FROM measurements")

      writer.save(@measurement)
      @measurement.time_stamp = new_time_stamp
    end

    context "when another measurement already exists" do
      let(:new_time_stamp) { DateTime.now + 15.0/(24*60) }

      it "is true" do
        expect(writer.send(:exists?, @measurement)).to be_true
      end
    end

    context "when no other measurement exists" do
      let(:new_time_stamp) { DateTime.now + 31.0/(24*60) }

      it "is false" do
        expect(writer.send(:exists?, @measurement)).to be_false
      end
    end
  end
end
