class YearCacheDescriptor
  def initialize(date, cache_dir)
    @cache_dir = cache_dir
    @date = date
  end

  def filename
    File.join(@cache_dir, @date.strftime("%Y"))
  end

  def data_fixed?
    @date < beginning_of_month
  end

  def temporary_cache_fresh?
    File.mtime(filename) > beginning_of_month
  end

  private
  def beginning_of_month
    now = Time.now

    Time.new(now.year, now.month, 1)
  end
end
