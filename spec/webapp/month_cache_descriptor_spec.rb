require 'spec_helper'
require 'webapp/month_cache_descriptor'
require 'fileutils'
require 'timecop'

describe MonthCacheDescriptor do
  let!(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe '#filename' do
    it "matches the current month" do
      subject = MonthCacheDescriptor.new(Time.new(2017, 3, 12), "/my_tmp_dir")

      expect(subject.filename).to eql "/my_tmp_dir/2017-03"
    end
  end

  describe '#data_fixed?' do
    let(:today) { Time.new(2017, 5, 20) }

    before do
      Timecop.travel(today)
    end

    after do
      Timecop.return
    end

    context 'when viewing the current month' do
      it 'returns false' do
        subject = MonthCacheDescriptor.new(Time.new(2017, 5, 1), "/my_tmp_dir")

        expect(subject.data_fixed?).to be false
      end
    end

    context 'when viewing a previous month' do
      it 'returns true' do
        subject = MonthCacheDescriptor.new(Time.new(2017, 4, 1), "/my_tmp_dir")

        expect(subject.data_fixed?).to be true
      end
    end
  end

  describe '#temporary_cache_fresh?' do
    let(:today) { Time.new(2017, 5, 20) }

    before do
      Timecop.travel(today)
    end

    after do
      Timecop.return
    end

    context 'when the cache is more than a day old' do
      let(:cache_date) { Time.new(2017, 5, 18) }

      it 'returns false' do
        subject = MonthCacheDescriptor.new(Time.new(2017, 5, 1), tmpdir)

        FileUtils.touch(subject.filename)
        File.utime(cache_date, cache_date, subject.filename)

        expect(subject.temporary_cache_fresh?).to be false
      end
    end

    context 'when the cache is less than a day old' do
      let(:cache_date) { Time.new(2017, 5, 20) }

      it 'returns true' do
        subject = MonthCacheDescriptor.new(Time.new(2017, 5, 1), tmpdir)

        FileUtils.touch(subject.filename)
        File.utime(cache_date, cache_date, subject.filename)

        expect(subject.temporary_cache_fresh?).to be true
      end
    end
  end
end
