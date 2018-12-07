require "webapp/cache_descriptor"

class YearCacheDescriptor < CacheDescriptor
  def filename
    File.join(@cache_dir, @date.strftime("%Y"))
  end

  def temporary_cache_fresh?
    return false unless File.file?(filename)

    if File.mtime(filename).year < Time.now.year
      false
    else
      beginning_of_this_month < File.mtime(filename)
    end
  end

  private

  def viewing_current_period?
    now = Time.now

    @date.year == now.year
  end

  def beginning_of_this_month
    now = Time.now

    Time.new(now.year, now.month, 1)
  end

  def cache_in_period?
    File.mtime(filename).year <= @date.year
  end
end
