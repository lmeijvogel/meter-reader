require 'yaml'
require 'mysql2'
require 'spec_helper'

require "output/database_writer"
require "p1_meter_reader/models/measurement"

describe DatabaseWriter do
  let(:config) { YAML.load(File.read(File.join(ROOT_PATH.join("database.yml"))))["test"] }

  let(:database_connection) { Mysql2::Client.new(host: config["host"],
                                                 database: config["database"],
                                                 username: config["username"],
                                                 password: config["password"])
  }

  let(:database_connection_factory) do
    factory = Object.new

    def factory.with_connection
      yield database_connection
    end

    factory
  end

  let(:writer) { DatabaseWriter.new(database_connection_factory) }

  describe :save do
    let(:time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23 }
    let(:stroom_piek) { 23.34 }
    let(:stroom_current) { 0.23 }
    let(:gas) { 12.23 }
    let(:water) { 33 }

    before do
      @measurement = P1MeterReader::Models::Measurement.new
      @measurement.time_stamp = time_stamp
      @measurement.time_stamp_utc = time_stamp
      @measurement.stroom_dal = stroom_dal
      @measurement.stroom_piek = stroom_piek
      @measurement.stroom_current = stroom_current
      @measurement.gas = gas
      @measurement.water = water

      database_connection.query("DELETE FROM measurements")
    end

    it "adds a row to the SQL backend" do
      expect {
        writer.save(@measurement, database_connection)
      }.to change { database_connection.query("SELECT * FROM measurements").count }.by(1)
    end

    describe "the result" do
      subject { database_connection.query("SELECT * FROM measurements").first }

      before do
        writer.save(@measurement, database_connection)
      end

      it "should have the correct stroom_dal" do
        expect(subject["stroom_dal"]).to eql stroom_dal.to_f
      end

      it "should have the correct stroom_piek" do
        expect(subject["stroom_piek"]).to eql stroom_piek.to_f
      end

      it "should have the correct stroom_current" do
        expect(subject["stroom_current"]).to eql stroom_current
      end

      it "should have the correct gas" do
        expect(subject["gas"]).to eql gas
      end

      it "should have the correct water" do
        expect(subject["water"]).to eql water
      end

      it "should have the correct timestamp" do
        expect(subject["time_stamp"].to_datetime.to_s).to eql time_stamp.to_s
      end
    end
  end

  describe :exists? do
    let(:existing_time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23 }
    let(:stroom_piek) { 23.34 }
    let(:stroom_current) { 0.23 }
    let(:gas) { 12.23 }
    let(:water) { 33 }

    let(:save_interval) { 30 }

    before do
      @measurement = P1MeterReader::Models::Measurement.new
      @measurement.time_stamp = existing_time_stamp
      @measurement.time_stamp_utc = existing_time_stamp
      @measurement.stroom_dal = stroom_dal
      @measurement.stroom_piek = stroom_piek
      @measurement.stroom_current = stroom_current
      @measurement.gas = gas
      @measurement.water = water

      database_connection.query("DELETE FROM measurements")
      writer.save_interval = save_interval

      writer.save(@measurement, database_connection)
      @measurement.time_stamp = new_time_stamp
    end

    context "when another measurement already exists" do
      let(:new_time_stamp) { DateTime.now + (save_interval / 2.0)/(24*60) }

      it "is true" do
        expect(writer.send(:exists?, @measurement, database_connection)).to be true
      end
    end

    context "when another measurement close to this one exists (regression)" do
      let(:existing_time_stamp) { DateTime.civil(2014, 11, 20, 20, 0, 40) }
      let(:new_time_stamp)      { DateTime.civil(2014, 11, 20, 20, 0, 50) }

      it "is true" do
        expect(writer.send(:exists?, @measurement, database_connection)).to be true
      end
    end

    context "when no other measurement exists" do
      let(:new_time_stamp) { DateTime.now + (save_interval + 1.0)/(24*60) }

      it "is false" do
        expect(writer.send(:exists?, @measurement, database_connection)).to be false
      end
    end
  end
end
