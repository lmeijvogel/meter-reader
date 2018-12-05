class YearCacheDescriptor
  def initialize(date, cache_dir)
    @cache_dir = cache_dir
    @date = date.to_time
  end

  def filename
    File.join(@cache_dir, @date.strftime("%Y"))
  end

  def data_fixed?
    !viewing_current_year?
  end

  def temporary_cache_fresh?
    beginning_of_month < File.mtime(filename)
  end

  private

  def viewing_current_year?
    now = Time.now

    @date.year == now.year
  end

  def beginning_of_month
    now = Time.now

    Time.new(now.year, now.month, 1)
  end
end
