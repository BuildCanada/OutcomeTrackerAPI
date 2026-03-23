namespace :db do
  desc "Backup the database to a timestamped custom-format dump file"
  task backup: :environment do
    require "fileutils"
    require "open3"

    db_config = Rails.configuration.database_configuration[Rails.env]
    database = db_config["database"]
    timestamp = Time.now.strftime("%Y-%m-%d_%H%M%S")
    backup_dir = Pathname.new("/Users/brendansamek/dev/BuildCanada/tracker/backups")
    FileUtils.mkdir_p(backup_dir)

    filename = "#{database}_backup_#{timestamp}.dump"
    filepath = backup_dir.join(filename)

    cmd_parts = ["pg_dump"]
    cmd_parts << "--host=#{db_config['host']}" if db_config["host"]
    cmd_parts << "--port=#{db_config['port']}" if db_config["port"]
    cmd_parts << "--username=#{db_config['username']}" if db_config["username"]
    cmd_parts << "--format=custom"
    cmd_parts << "--no-owner"
    cmd_parts << "--no-privileges"
    cmd_parts << "-f" << filepath.to_s
    cmd_parts << database

    env = {}
    env["PGPASSWORD"] = db_config["password"] if db_config["password"]

    puts "Backing up #{database} to #{filepath}..."

    _stdout, stderr, status = Open3.capture3(env, *cmd_parts.map(&:to_s))

    if status.success? && File.exist?(filepath) && File.size(filepath) > 0
      size_mb = File.size(filepath).to_f / (1024 * 1024)
      puts "Backup complete: #{filepath} (#{size_mb.round(2)} MB)"
    else
      puts "Error: Backup failed"
      puts stderr if stderr.present?
      File.delete(filepath) if File.exist?(filepath)
      exit 1
    end
  end
end
