require 'spec_helper'
require 'webapp/year_cache_descriptor'
require 'fileutils'
require 'timecop'

describe YearCacheDescriptor do
  let!(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe '#filename' do
    it "matches the current year" do
      subject = YearCacheDescriptor.new(Time.new(2017, 3, 12), "/my_tmp_dir")

      expect(subject.filename).to eql "/my_tmp_dir/2017"
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

    context 'when viewing the current year' do
      it 'returns false' do
        subject = YearCacheDescriptor.new(Time.new(2017, 5, 1), "/my_tmp_dir")

        expect(subject.data_fixed?).to be false
      end
    end

    # Regression:
    #
    # The code used to compare `date < current_month`, but `date` is given
    # as january 1 in the current year. So in practice, it would always be true.
    context 'when the data is a few months ago' do
      it 'returns false' do
        subject = YearCacheDescriptor.new(Time.new(2017, 1, 1), "/my_tmp_dir")

        expect(subject.data_fixed?).to be false
      end
    end

    context 'when viewing a previous year' do
      it 'returns true' do
        subject = YearCacheDescriptor.new(Time.new(2016, 4, 1), "/my_tmp_dir")

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

    context 'when the cache was created a few months ago' do
      it 'returns false' do
        cache_date = Time.new(2017, 2, 18)
        subject = YearCacheDescriptor.new(Time.new(2017, 2, 18), tmpdir)

        FileUtils.touch(subject.filename)
        File.utime(cache_date, cache_date, subject.filename)

        expect(subject.temporary_cache_fresh?).to be false
      end
    end

    context 'when the cache was created in the previous month' do
      it 'returns false' do
        cache_date = Time.new(2017, 4, 18)
        subject = YearCacheDescriptor.new(Time.new(2017, 5, 1), tmpdir)

        FileUtils.touch(subject.filename)
        File.utime(cache_date, cache_date, subject.filename)

        expect(subject.temporary_cache_fresh?).to be false
      end
    end

    # Anything in the current month is fine: it won't be very interesting until
    # the month is finished anyway.
    context 'when the cache was created in the current month' do
      it 'returns true' do
        cache_date = Time.new(2017, 5, 1, 0, 1)

        subject = YearCacheDescriptor.new(Time.new(2017, 5, 1), tmpdir)

        FileUtils.touch(subject.filename)
        File.utime(cache_date, cache_date, subject.filename)

        expect(subject.temporary_cache_fresh?).to be true
      end
    end
  end
end
