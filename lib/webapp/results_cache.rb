class ResultsCache
  def initialize(date, descriptor:)
    @cache_descriptor = descriptor
  end

  def filename
    @cache_descriptor.filename
  end

  def cached
    filename = @cache_descriptor.filename

    cacheable = @cache_descriptor.data_fixed? || @cache_descriptor.temporary_cache_fresh?

    if cacheable
      if File.exist?(filename)
        return File.read(filename)
      else
        data = yield

        File.open(filename, "w") do |file|
          file.write(data)
        end

        return data
      end
    else
      FileUtils.rm_f(filename)

      yield
    end
  end
end
