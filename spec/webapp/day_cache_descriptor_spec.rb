require 'spec_helper'
require 'webapp/day_cache_descriptor'
require 'fileutils'

describe DayCacheDescriptor do
  let!(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe '#filename' do
    it "matches the current day" do
      subject = DayCacheDescriptor.new(Time.new(2017, 3, 12), "/my_tmp_dir")

      expect(subject.filename).to eql "/my_tmp_dir/2017-03-12"
    end
  end

  describe '#data_fixed?' do
    it "is false if the date is today" do
      subject = DayCacheDescriptor.new(Time.now, tmpdir)

      expect(subject.data_fixed?).to be false
    end

    it "is true if the date is yesterday" do
      yesterday = Time.now - 86400
      subject = DayCacheDescriptor.new(yesterday, tmpdir)

      expect(subject.data_fixed?).to be true
    end
  end

  describe '#temporary_cache_fresh?' do
    it 'is false' do
      subject = DayCacheDescriptor.new(Time.now, tmpdir)

      expect(subject.temporary_cache_fresh?).to be false
    end
  end
end
