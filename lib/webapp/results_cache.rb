class ResultsCache
  def initialize(date, descriptor:)
    @cache_descriptor = descriptor
  end

  def filename
    @cache_descriptor.filename
  end

  def cached
    filename = @cache_descriptor.filename

    if @cache_descriptor.should_delete_cache?
      FileUtils.rm_f(filename)
    end

    cacheable = @cache_descriptor.data_fixed? || @cache_descriptor.temporary_cache_fresh?

    return yield unless cacheable

    if File.exist?(filename)
      read_from_cache(filename)
    else
      data = yield

      File.open(filename, "w") do |file|
        file.write(data)
      end

      return data
    end
  end

  private

  def read_from_cache(filename)
    File.read(filename)
  end
end
