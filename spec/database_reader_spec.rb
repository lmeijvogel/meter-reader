require "spec_helper"
require 'mysql2'
require 'yaml'

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

    measurements.each do |measurement|
      database_connection.query("INSERT INTO measurements(#{measurement.columns_str})
                                VALUES (#{measurement.values_str})")
    end
  end

  describe "a single value" do
    let(:measurement_1) { Measurement.new( DateTime.now, 12.23, 23.34, 12.23 ) }
    let(:measurement_2) { Measurement.new( DateTime.now, 13.23, 25.34, 12.23 ) }

    let(:measurements) { [measurement_1, measurement_2 ] }

    before do
      now = DateTime.now

      time_offset = Time.now.dst? ? "+2" : "+1"
      reader.day = DateTime.civil(now.year, now.month, now.day, 0, 0, 0, time_offset)

      @usage = reader.read().first
    end

    it "sets the correct stroom_totaal" do
      stroom_totaal = measurement_1.stroom_dal + measurement_1.stroom_piek

      expect(@usage.stroom_totaal).to be_within(0.01).of(stroom_totaal)
    end

    it "sets the correct gas" do
      expect(@usage.gas).to be_within(0.01).of(measurement_1.gas)
    end

    it "sets the correct time_stamp" do
      expect(@usage.time_stamp.to_s).to eql measurement_1.time_stamp.to_s
    end
  end

  describe "multiple data" do
    let(:measurement_day) {
      now = DateTime.now
      DateTime.civil(now.year, now.month, now.day)
    }

    let(:base_date) {
      time_offset = Time.now.dst? ? "+2" : "+1"
      DateTime.civil(measurement_day.year, measurement_day.month, measurement_day.day, 0, 0, 0, time_offset)
    }

    let(:minute) { 1.0 / (24*60) }

    let(:measurements) { [
      Measurement.new( base_date, 11.23, 22.34, 11.23 ),
      Measurement.new( base_date + 10*minute, 12.23, 23.34, 12.23 ),
      Measurement.new( base_date + 30*minute, 14.23, 25.34, 14.23 ),
      Measurement.new( base_date + 50*minute, 16.23, 27.34, 16.23 ),
      Measurement.new( base_date + 60*minute, 15.23, 26.34, 15.23 ),
      Measurement.new( base_date + 70*minute, 16.23, 27.34, 16.23 )
    ] }

    before do
      now = DateTime.now
      reader.day = DateTime.new(now.year, now.month, now.day)
      result = reader.read

      @first, @second, @last = result
    end

    it "returns the first measurement of the first hour" do
      expect(@first.time_stamp.to_s).to eql base_date.to_s
      expect(@first.gas).to be_within(0.01).of(11.23)
    end

    it "returns the first measurement of the second hour" do
      expect(@second.time_stamp.to_s).to eql (base_date + 60*minute).to_s
      expect(@second.gas).to be_within(0.01).of(15.23)
    end

    context "when the measurement is for today" do
      it "adds a 'virtual' measurement of the current hour" do
        now = DateTime.now
        time_offset = Time.now.dst? ? "+2" : "+1"

        expected = DateTime.new(now.year, now.month, now.day, now.hour + 1, 0, 0, time_offset)

        expect(@last.time_stamp.to_s).to eql expected.to_s
        expect(@last.gas).to be_within(0.01).of(16.23)
      end
    end

    context "when the measurement is for a previous day" do
      let(:measurement_day) {
        now = DateTime.now - 1
        DateTime.civil(now.year, now.month, now.day)
      }

      it "does not add a 'virtual' measurement" do
        expect(@lasti).to be_nil
      end
    end

    it "also returns the latest measurement" do
      now = DateTime.now
      time_offset = Time.now.dst? ? "+2" : "+1"
      expected = DateTime.new(now.year, now.month, now.day, now.hour + 1, 0, 0, time_offset)

      expect(@last.time_stamp.to_s).to eql expected.to_s
      expect(@last.gas).to be_within(0.01).of(16.23)
    end
  end
end
