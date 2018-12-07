require "webapp/cache_descriptor"

class MonthCacheDescriptor < CacheDescriptor
  def filename
    File.join(@cache_dir, @date.strftime("%Y-%m"))
  end

  def temporary_cache_fresh?
    yesterday = Time.now - 86400

    File.exist?(filename) && (File.mtime(filename) > yesterday)
  end

  def cache_in_period?
    file_created_at = File.mtime(filename)

    file_created_at.year == @date.year &&
      file_created_at.month == @date.month
  end

  def viewing_current_period?
    now = Time.now

    now.year == @date.year && now.month == @date.month
  end
end
