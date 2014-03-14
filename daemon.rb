class Daemon
  def initialize(process_name, pidfile)
    self.pidfile = pidfile
    self.process_name = process_name
  end

  def run
    ensure_pidfile_writable!

    $0 = process_name

    pid = Process.fork do
      begin
        yield
      ensure
        File.unlink pidfile if File.exist? pidfile
      end
    end

    File.open(pidfile, "w") do |file|
      file.puts pid.to_s
    end
  end

  protected

  def ensure_pidfile_writable!
    new_pidfile_possible = !File.exists?(pidfile) && File.writable?(File.dirname(pidfile))
    pidfile_writable = File.writable?(pidfile)
    unless ( new_pidfile_possible || pidfile_writable )
      raise "Cannot write PID file at #{pidfile}"
    end
  end

  attr_accessor :process_name, :pidfile
end
