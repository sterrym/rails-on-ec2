#!/usr/bin/env ruby
#
# Find bloating passengers and kill them gracefully. Run from cron every minute.
#
 
# required for passenger since cron has no environment
ENV['HTTPD'] = 'httpd'
 
MEM_LIMIT = ARGV[0] || 192

module Process
  def self.running?(pid)
    begin
      return Process.getpgid(pid) != -1
    rescue Errno::ESRCH
      return false
    end
  end
end
 
`passenger-memory-stats`.each_line do |line|
  if line =~ /Rails: /
    parts = line.split
    pid, private_dirty_rss = parts[0].to_i, parts[4].to_f
    
    if private_dirty_rss > MEM_LIMIT.to_i
      puts "Found bloater #{pid} with size #{private_dirty_rss.to_s}"
      puts "Killing with SIGUSR1 (graceful)..."
      Process.kill("SIGUSR1", pid)
      puts "Finished kill attempt. Sleeping for 8 seconds..."
      sleep 8
      if Process.running?(pid)
        puts "Process is still running, so killing with extreme predjudice!"
        Process.kill("TERM", pid)
      end
      puts "Done!"
    end
  end
end
