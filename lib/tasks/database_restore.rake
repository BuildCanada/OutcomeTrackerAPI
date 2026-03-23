BACKUP_DIR = Pathname.new("/Users/brendansamek/dev/BuildCanada/tracker/backups")

def db_config_for_env(target_env)
  if target_env == "development"
    config = Rails.configuration.database_configuration["development"]
    {
      host: config["host"],
      port: config["port"],
      username: config["username"],
      password: config["password"],
      database: config["database"],
    }
  else
    enc_path = Rails.root.join("config/credentials/#{target_env}.yml.enc")
    key_path = Rails.root.join("config/credentials/#{target_env}.key")

    unless File.exist?(enc_path)
      puts "No credentials file found: #{enc_path}"
      puts "Create with: bin/rails credentials:edit --environment #{target_env}"
      exit 1
    end

    creds = Rails.application.encrypted(enc_path, key_path: key_path)
    db = creds.database

    if db.nil?
      puts "No database config found in #{target_env} credentials."
      puts "Expected format:"
      puts "  database:"
      puts "    host: your-host"
      puts "    port: 5432"
      puts "    username: your-user"
      puts "    password: your-pass"
      puts "    database: your-db-name"
      exit 1
    end

    {
      host: db[:host],
      port: db[:port],
      username: db[:username],
      password: db[:password],
      database: db[:database],
    }
  end
end

def find_latest_backup
  files = Dir.glob(BACKUP_DIR.join("*.dump"))

  if files.empty?
    puts "No backup files found in #{BACKUP_DIR}"
    exit 1
  end

  files.max_by { |f| File.mtime(f) }
end

def restore_dump(dump_file, db_config)
  require "open3"

  pg_restore_cmd = ["pg_restore"]
  pg_restore_cmd << "--host=#{db_config[:host]}" if db_config[:host]
  pg_restore_cmd << "--port=#{db_config[:port]}" if db_config[:port]
  pg_restore_cmd << "--username=#{db_config[:username]}" if db_config[:username]
  pg_restore_cmd << "--dbname=#{db_config[:database]}"
  pg_restore_cmd << "--clean"
  pg_restore_cmd << "--if-exists"
  pg_restore_cmd << "--schema=public"
  pg_restore_cmd << "--no-owner"
  pg_restore_cmd << "--no-privileges"
  pg_restore_cmd << "--verbose"
  pg_restore_cmd << dump_file

  env = {}
  env["PGPASSWORD"] = db_config[:password] if db_config[:password]

  _stdout, stderr, status = Open3.capture3(env, *pg_restore_cmd.map(&:to_s))

  unless status.success?
    puts "Error: #{stderr}"
    exit 1
  end
end

namespace :db do
  desc "Restore database to a target environment. Usage: rake db:restore[production] or DUMP_FILE=/path rake db:restore[staging]"
  task :restore, [:env] => :environment do |_t, args|
    target_env = args[:env] || Rails.env
    dump_file = ENV["DUMP_FILE"] || find_latest_backup

    unless File.exist?(dump_file)
      puts "Dump file not found: #{dump_file}"
      exit 1
    end

    db_config = db_config_for_env(target_env)

    puts ""
    puts "Source:      #{dump_file}"
    puts "Target DB:   #{db_config[:database]}"
    puts "Target Host: #{db_config[:host] || 'localhost'}"
    puts "Target User: #{db_config[:username] || '(default)'}"
    puts "Environment: #{target_env}"
    puts ""

    unless ENV["SKIP_CONFIRMATION"] == "true"
      puts "Are you sure? Type 'yes' to continue:"
      confirmation = $stdin.gets.chomp
      unless confirmation.downcase == "yes"
        puts "Aborted"
        exit 0
      end
    end

    puts "Restoring..."
    restore_dump(dump_file, db_config)
    puts "Restore complete!"
  end

  desc "Fetch latest database dump from GitHub artifacts and restore it"
  task fetch_and_restore: :environment do
    require "fileutils"
    require "json"
    require "net/http"
    require "open3"

    repo = ENV["GITHUB_REPOSITORY"] || "BuildCanada/OutcomeTrackerAPI"

    puts "Fetching latest database dump artifact..."

    uri = URI("https://api.github.com/repos/#{repo}/actions/artifacts")
    uri.query = URI.encode_www_form(per_page: 100)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = http.request(request)

    if response.code != "200"
      puts "Error fetching artifacts: #{response.code} #{response.body}"
      exit 1
    end

    artifacts = JSON.parse(response.body)["artifacts"]
    dump_artifacts = artifacts.select { |a| a["name"].start_with?("database-dump-") }

    if dump_artifacts.empty?
      puts "No database dump artifacts found"
      exit 1
    end

    latest_artifact = dump_artifacts.max_by { |a| DateTime.parse(a["created_at"]) }
    puts "Found artifact: #{latest_artifact['name']} (created: #{latest_artifact['created_at']})"

    unless system("which gh > /dev/null 2>&1")
      puts "Error: GitHub CLI (gh) is not installed."
      puts "Please install it from: https://cli.github.com/"
      exit 1
    end

    temp_dir = Rails.root.join("tmp", "database_restore")
    FileUtils.mkdir_p(temp_dir)

    puts "Downloading artifact using GitHub CLI..."
    download_cmd = "gh api repos/#{repo}/actions/artifacts/#{latest_artifact['id']}/zip > #{temp_dir}/artifact.zip"

    unless system(download_cmd)
      puts "Error downloading artifact"
      puts "Make sure you're authenticated with: gh auth login"
      exit 1
    end

    zip_file = temp_dir.join("artifact.zip")
    puts "Downloaded artifact to #{zip_file}"

    system("unzip -o #{zip_file} -d #{temp_dir}") or raise "Failed to extract artifact"

    dump_file = Dir.glob(temp_dir.join("*.dump")).first

    if dump_file.nil?
      puts "No dump file found in artifact"
      exit 1
    end

    puts "Found dump file: #{dump_file}"

    ENV["DUMP_FILE"] = dump_file
    Rake::Task["db:restore"].invoke

    FileUtils.rm_rf(temp_dir)
    puts "Database restore complete!"
  end

  desc "List available database dump artifacts"
  task list_dumps: :environment do
    require "json"
    require "net/http"

    repo = ENV["GITHUB_REPOSITORY"] || "BuildCanada/OutcomeTrackerAPI"

    uri = URI("https://api.github.com/repos/#{repo}/actions/artifacts")
    uri.query = URI.encode_www_form(per_page: 100)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["X-GitHub-Api-Version"] = "2022-11-28"

    response = http.request(request)

    if response.code != "200"
      puts "Error fetching artifacts: #{response.code} #{response.body}"
      exit 1
    end

    artifacts = JSON.parse(response.body)["artifacts"]
    dump_artifacts = artifacts.select { |a| a["name"].start_with?("database-dump-") }

    if dump_artifacts.empty?
      puts "No database dump artifacts found"
      exit 0
    end

    puts "\nAvailable database dumps:"
    puts "-" * 80

    dump_artifacts.sort_by { |a| DateTime.parse(a["created_at"]) }.reverse.each do |artifact|
      created_at = DateTime.parse(artifact["created_at"])
      size_mb = artifact["size_in_bytes"].to_f / (1024 * 1024)
      expires_at = DateTime.parse(artifact["expires_at"])

      puts "Name:       #{artifact['name']}"
      puts "Created:    #{created_at.strftime('%Y-%m-%d %H:%M:%S UTC')}"
      puts "Size:       #{size_mb.round(2)} MB"
      puts "Expires:    #{expires_at.strftime('%Y-%m-%d %H:%M:%S UTC')}"
      puts "ID:         #{artifact['id']}"
      puts "-" * 80
    end
  end
end
