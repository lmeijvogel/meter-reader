require 'yaml'
require 'mysql2'
require 'spec_helper'

require "output/database_writer"
require "models/measurement"

describe DatabaseWriter do
  let(:config) { YAML.load(File.read(File.join(ROOT_PATH.join("database.yml"))))["test"] }

  let(:database_connection) { Mysql2::Client.new(host: config["host"],
                                                 database: config["database"],
                                                 username: config["username"],
                                                 password: config["password"])
  }

  let(:database_connection_factory) do
    factory = Object.new

    def factory.with_connection(retries: 0)
      yield database_connection
    end

    factory
  end

  let(:writer) { DatabaseWriter.new(database_connection_factory) }

  describe :save do
    let(:time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23 }
    let(:stroom_piek) { 23.34 }
    let(:levering_dal) { 2.23 }
    let(:levering_piek) { 34 }
    let(:stroom_current) { 500 }
    let(:levering_current) { 230 }
    let(:gas) { 12.23 }
    let(:water) { 33 }

    before do
      @measurement = P1MeterReader::Models::Measurement.new(time_stamp, time_stamp, stroom_dal, stroom_piek, levering_dal, levering_piek, stroom_current, levering_current, gas, water)

      writer.save_interval = 15
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

      it "should have the correct stroom" do
        stroom = stroom_dal + stroom_piek;
        expect(subject["stroom"]).to eql stroom.to_f
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

  describe :should_save? do
    let(:existing_time_stamp) { DateTime.now }
    let(:stroom_dal) { 12.23 }
    let(:stroom_piek) { 23.34 }
    let(:gas) { 12.23 }
    let(:water) { 33 }

    let(:save_interval) { 15 }

    before do
      @measurement = P1MeterReader::Models::Measurement.new(existing_time_stamp, existing_time_stamp, stroom_dal, stroom_piek, gas, water)

      database_connection.query("DELETE FROM measurements")
      writer.save_interval = save_interval

      writer.save(@measurement, database_connection)
      @measurement.time_stamp = new_time_stamp
    end

    context "when another measurement already exists" do
      let(:new_time_stamp) { DateTime.now + (7.5)/(24*60) }

      it "is false" do
        expect(writer.send(:should_save?, @measurement, database_connection)).to be false
      end
    end

    describe "save intervals" do
      describe "previous measurement on time" do
        let(:existing_time_stamp) { DateTime.civil(2014, 11, 20, 20, 15, 0) }

        describe "and it is time for new entry" do
          let(:new_time_stamp) { DateTime.civil(2014, 11, 20, 20, 30, 0) }

          it "is true" do
            expect(writer.send(:should_save?, @measurement, database_connection)).to be true
          end
        end

        describe "but it is not yet time for new entry" do
          let(:new_time_stamp) { DateTime.civil(2014, 11, 20, 20, 29, 0) }

          it "is false" do
            expect(writer.send(:should_save?, @measurement, database_connection)).to be false
          end
        end
      end

      describe "previous measurement missed" do
        let(:existing_time_stamp) { DateTime.civil(2014, 11, 20, 20, 3, 0) }

        describe "but it is not yet time for new entry" do
          let(:new_time_stamp) { DateTime.civil(2014, 11, 20, 20, 24, 0) }

          it "is false" do
            expect(writer.send(:should_save?, @measurement, database_connection)).to be false
          end
        end

        describe "and it is time for new entry" do
          let(:new_time_stamp) { DateTime.civil(2014, 11, 20, 20, 30, 0) }

          it "is true" do
            expect(writer.send(:should_save?, @measurement, database_connection)).to be true
          end
        end
      end

      describe "at day's end" do
        let(:existing_time_stamp) { DateTime.civil(2014, 11, 20, 23, 45, 1) }
        let(:new_time_stamp) { DateTime.civil(2014, 11, 21, 0, 0, 1) }

        it "is true" do
          expect(writer.send(:should_save?, @measurement, database_connection)).to be true
        end
      end
    end

    context "when another measurement close to this one exists (regression)" do
      let(:existing_time_stamp) { DateTime.civil(2014, 11, 20, 20, 3, 0) }
      let(:new_time_stamp)      { DateTime.civil(2014, 11, 20, 20, 15, 0) }

      it "is false" do
        expect(writer.send(:should_save?, @measurement, database_connection)).to be false
      end
    end

    context "when no other measurement exists" do
      let(:new_time_stamp) { now = DateTime.now ; DateTime.new(now.year, now.month, now.day, now.hour + 1, 15, 0) }

      it "is true" do
        expect(writer.send(:should_save?, @measurement, database_connection)).to be true
      end
    end
  end
end
