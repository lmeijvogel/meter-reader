require 'spec_helper'
require 'webapp/results_cache'
require 'webapp/day_cache_descriptor'
require 'tmpdir'
require 'securerandom'

describe ResultsCache do
  let!(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  subject(:results_cache) { ResultsCache.new(date, descriptor: descriptor) }
  let(:cache_filename) { File.join(tmpdir, "#{SecureRandom.hex}.txt") }
  let(:descriptor) { instance_double("DayCacheDescriptor", filename: cache_filename, should_delete_cache?: should_delete_cache ) }
  let(:should_delete_cache) { true }
  let(:one_day) { 60*60*24 }

  context "when the data won't change anymore" do
    let(:date) { Date.today - one_day }

    before do
      allow(descriptor).to receive(:data_fixed?).and_return(true)
      allow(descriptor).to receive(:should_delete_cache?).and_return(false)
    end

    context "and it is cached" do
      before do
        File.open(cache_filename, "w") do |file|
          file.write("cached")
        end
      end

      it "returns the cache" do
        result = results_cache.cached do
          "baah"
        end

        expect(result).to eql "cached"
      end
    end

    context "but the result is not yet cached" do
      it "returns the block" do
        result = results_cache.cached do
          "baah"
        end

        expect(result).to eql "baah"
      end

      it "writes the cache file" do
        results_cache.cached do
          "baah"
        end

        cached_contents = File.read(cache_filename)

        expect(cached_contents).to eq "baah"
      end
    end
  end

  context "when the data is still volatile" do
    let(:cache_filename) { File.join(tmpdir, "cache.txt") }
    let(:date) { Date.today }

    before do
      allow(descriptor).to receive(:data_fixed?).and_return(false)
    end

    context "and should be temporarily cached" do
      before do
        allow(descriptor).to receive(:temporary_cache_fresh?).and_return(true)
      end

      it "returns the block" do
        result = results_cache.cached do
          "baah"
        end

        expect(result).to eql "baah"
      end

      it "writes the cache file" do
        results_cache.cached do
          "baah"
        end

        cached_contents = File.read(cache_filename)

        expect(cached_contents).to eq "baah"
      end
    end

    context "but should not be temporarily cached" do
      before do
        allow(descriptor).to receive(:temporary_cache_fresh?).and_return(false)
      end

      it "returns the block" do
        result = results_cache.cached do
          "baah"
        end

        expect(result).to eql "baah"
      end

      it "does not write the cache file" do
        results_cache.cached do
          "baah"
        end

        expect(File.exist?(cache_filename)).to be false
      end
    end
  end

  context "integration" do
    context "when caching day data" do
      let(:one_day) { 86400 }

      let(:day_descriptor) { DayCacheDescriptor.new(date, tmpdir) }
      subject(:results_cache) { ResultsCache.new(date, descriptor: day_descriptor) }

      context "when the requested entry is yesterday or earlier" do
        let(:date) { Time.now - 2*one_day }

        context "if it is cached" do
          let(:cached_contents) { "cached yo" }

          before do
            File.open(results_cache.filename, "w") do |file|
              file.write(cached_contents)
            end
          end

          it "returns the cached contents" do
            actual = results_cache.cached do end

            expect(actual).to eql cached_contents
          end
        end

        context "if it is not cached" do
          let(:uncached_contents) { "not cached yo" }

          it "calls the block and returns the value" do
            actual = results_cache.cached do
              uncached_contents
            end

            expect(actual).to eq uncached_contents
          end

          it "saves the contents in the cache" do
            results_cache.cached do
              uncached_contents
            end

            expect(File.read(results_cache.filename)).to eq uncached_contents
          end
        end
      end

      context "when the requested entry is today" do
        let(:date) { Time.now }

        let(:uncached_contents) { "not cached yo" }

        it "calls the block and returns the value" do
          actual = results_cache.cached do
            uncached_contents
          end

          expect(actual).to eq uncached_contents
        end

        it "does not save the contents to the cache" do
          results_cache.cached do
            uncached_contents
          end

          expect(File.exist?(results_cache.filename)).to eq false
        end
      end
    end
  end
end
