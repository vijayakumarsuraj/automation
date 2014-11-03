#
# Suraj Vijayakumar
# 27 Mar 2014
#

require 'win32/daemon'

# Behaves like a service that can be started / stopped by Windows.
class FrameworkDaemon < Win32::Daemon

  # The main body of the service.
  # This will launch the framework on a new thread and wait around till the service is stopped.
  def service_main
    start_framework
    idle
    stop_framework
  end

  private

  # Idle loop. Waits till the service is stopped.
  def idle
    sleep(5) while running?
  end

  # Starts the framework on a parallel thread.
  def start_framework
    @fw_thread = Thread.new do
      begin
        load(File.join(ROOT, 'main.rb'))
      rescue
        LOG.puts("Exception encountered - #{$!.message}")
        LOG.puts($!.backtrace.join("\n"))
      end
    end
  end

  # Stops the framework thread.
  def stop_framework
    @fw_thread.exit unless @fw_thread.nil?
  end

end

begin
  ROOT = File.expand_path(File.dirname(__FILE__))
  LOG = File.open(File.join(ROOT, 'daemon.log'), 'w')
  # Start the main loop.
  LOG.puts('Main loop starting...')
  FrameworkDaemon.mainloop
rescue
  LOG.puts($!.message)
  LOG.puts($!.backtrace.join("\n"))
ensure
  LOG.puts('Main loop done')
  LOG.close
end
