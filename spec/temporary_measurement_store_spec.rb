require "spec_helper"
require "temporary_measurement_store"
require "p1_meter_reader/models/usage"

describe TemporaryMeasurementStore do
  class Entry
    def initialize(n)
      @n = n
    end

    def to_s
      "<#{@n}>"
    end

    def to_int
      @n
    end
  end

  let(:store) { TemporaryMeasurementStore.new(number_of_entries: 5) }

  (0..5).each do |n|
    it "should store #{n} entries" do
      entries = Array.new(n) { Entry.new(n) }

      add_entries(entries)

      expect(store.measurements).to eql(entries)
    end
  end

  (5..30).each do |n|
    it "should only store the last #{n} entries" do
      entries = Array.new(n) { |i| Entry.new(i) }

      add_entries(entries)

      expect(store.measurements.map(&:to_int)).to eql [n-5, n-4, n-3, n-2, n-1]
    end
  end

  def add_entries(entries)
    entries.each do |entry|
      store << entry
    end
  end

  def assert_entries(entries)
    entries.each_with_index do |entry, i|
      expect(store.measurements[i]).to equal entry
    end
  end
end
