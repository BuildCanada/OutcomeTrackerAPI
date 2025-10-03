namespace :db do
  desc "Fetch latest database dump from GitHub artifacts and restore it"
  task :fetch_and_restore => :environment do
    require 'net/http'
    require 'json'
    require 'fileutils'
    require 'open3'

    # GitHub API configuration
    github_token = ENV['GITHUB_TOKEN'] || ENV['GITHUB_PAT']
    repo = ENV['GITHUB_REPOSITORY'] || 'BuildCanada/OutcomeTrackerAPI'
    
    if github_token.nil? || github_token.empty?
      puts "Error: GITHUB_TOKEN or GITHUB_PAT environment variable is required"
      exit 1
    end

    puts "Fetching latest database dump artifact..."

    # Get list of artifacts
    uri = URI("https://api.github.com/repos/#{repo}/actions/artifacts")
    uri.query = URI.encode_www_form(per_page: 100)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.github+json'
    request['Authorization'] = "Bearer #{github_token}"
    request['X-GitHub-Api-Version'] = '2022-11-28'
    
    response = http.request(request)
    
    if response.code != '200'
      puts "Error fetching artifacts: #{response.code} #{response.body}"
      exit 1
    end

    artifacts = JSON.parse(response.body)['artifacts']
    
    # Find the latest database dump artifact
    dump_artifacts = artifacts.select { |a| a['name'].start_with?('database-dump-') }
    
    if dump_artifacts.empty?
      puts "No database dump artifacts found"
      exit 1
    end

    latest_artifact = dump_artifacts.max_by { |a| DateTime.parse(a['created_at']) }
    
    puts "Found artifact: #{latest_artifact['name']} (created: #{latest_artifact['created_at']})"

    # Download the artifact
    download_uri = URI("https://api.github.com/repos/#{repo}/actions/artifacts/#{latest_artifact['id']}/zip")
    
    request = Net::HTTP::Get.new(download_uri)
    request['Accept'] = 'application/vnd.github+json'
    request['Authorization'] = "Bearer #{github_token}"
    request['X-GitHub-Api-Version'] = '2022-11-28'
    
    response = http.request(request)
    
    if response.code != '200'
      puts "Error downloading artifact: #{response.code} #{response.body}"
      exit 1
    end

    # Save the artifact
    temp_dir = Rails.root.join('tmp', 'database_restore')
    FileUtils.mkdir_p(temp_dir)
    
    zip_file = temp_dir.join('artifact.zip')
    File.open(zip_file, 'wb') do |file|
      file.write(response.body)
    end

    puts "Downloaded artifact to #{zip_file}"

    # Extract the zip file
    system("unzip -o #{zip_file} -d #{temp_dir}") or raise "Failed to extract artifact"
    
    # Find the dump file
    dump_file = Dir.glob(temp_dir.join('*.dump')).first
    
    if dump_file.nil?
      puts "No dump file found in artifact"
      exit 1
    end

    puts "Found dump file: #{dump_file}"
    
    # Restore the database
    Rake::Task['db:restore'].invoke(dump_file)
    
    # Cleanup
    FileUtils.rm_rf(temp_dir)
    
    puts "Database restore complete!"
  end

  desc "Restore database from a dump file"
  task :restore, [:dump_file] => :environment do |t, args|
    dump_file = args[:dump_file]
    
    if dump_file.nil? || !File.exist?(dump_file)
      puts "Error: Dump file not found: #{dump_file}"
      exit 1
    end

    # Confirm before proceeding
    unless ENV['SKIP_CONFIRMATION'] == 'true'
      puts "\nWARNING: This will restore the database from #{dump_file}"
      puts "This will DROP and recreate all tables except 'users', 'schema_migrations', and 'ar_internal_metadata'"
      puts "Are you sure? Type 'yes' to continue:"
      
      confirmation = STDIN.gets.chomp
      unless confirmation.downcase == 'yes'
        puts "Aborted"
        exit 0
      end
    end

    # Get database configuration
    db_config = Rails.configuration.database_configuration[Rails.env]
    
    # Build pg_restore command
    pg_restore_cmd = ['pg_restore']
    
    # Connection parameters
    pg_restore_cmd << "--host=#{db_config['host']}" if db_config['host']
    pg_restore_cmd << "--port=#{db_config['port']}" if db_config['port']
    pg_restore_cmd << "--username=#{db_config['username']}" if db_config['username']
    pg_restore_cmd << "--dbname=#{db_config['database']}"
    
    # Restore options
    pg_restore_cmd << '--clean'        # Clean (drop) database objects before recreating
    pg_restore_cmd << '--if-exists'    # Use IF EXISTS when dropping objects
    pg_restore_cmd << '--no-owner'     # Don't set ownership
    pg_restore_cmd << '--no-privileges' # Don't restore access privileges
    pg_restore_cmd << '--verbose'       # Verbose output
    
    # The dump already excludes users, schema_migrations, and ar_internal_metadata
    # so we don't need to exclude them again
    
    pg_restore_cmd << dump_file
    
    # Set PGPASSWORD environment variable if password is provided
    env = {}
    env['PGPASSWORD'] = db_config['password'] if db_config['password']
    
    puts "Restoring database from #{dump_file}..."
    
    # Execute pg_restore
    stdout, stderr, status = Open3.capture3(env, *pg_restore_cmd.map(&:to_s))
    
    if status.success?
      puts "Database restored successfully!"
    else
      puts "Error restoring database:"
      puts stderr
      exit 1
    end
    
    # Run any pending migrations that might have been added since the dump
    puts "Running pending migrations..."
    Rake::Task['db:migrate'].invoke
  end

  desc "List available database dump artifacts"
  task :list_dumps => :environment do
    require 'net/http'
    require 'json'

    # GitHub API configuration
    github_token = ENV['GITHUB_TOKEN'] || ENV['GITHUB_PAT']
    repo = ENV['GITHUB_REPOSITORY'] || 'BuildCanada/OutcomeTrackerAPI'
    
    if github_token.nil? || github_token.empty?
      puts "Error: GITHUB_TOKEN or GITHUB_PAT environment variable is required"
      exit 1
    end

    # Get list of artifacts
    uri = URI("https://api.github.com/repos/#{repo}/actions/artifacts")
    uri.query = URI.encode_www_form(per_page: 100)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.github+json'
    request['Authorization'] = "Bearer #{github_token}"
    request['X-GitHub-Api-Version'] = '2022-11-28'
    
    response = http.request(request)
    
    if response.code != '200'
      puts "Error fetching artifacts: #{response.code} #{response.body}"
      exit 1
    end

    artifacts = JSON.parse(response.body)['artifacts']
    
    # Find database dump artifacts
    dump_artifacts = artifacts.select { |a| a['name'].start_with?('database-dump-') }
    
    if dump_artifacts.empty?
      puts "No database dump artifacts found"
      exit 0
    end

    puts "\nAvailable database dumps:"
    puts "-" * 80
    
    dump_artifacts.sort_by { |a| DateTime.parse(a['created_at']) }.reverse.each do |artifact|
      created_at = DateTime.parse(artifact['created_at'])
      size_mb = artifact['size_in_bytes'].to_f / (1024 * 1024)
      expires_at = DateTime.parse(artifact['expires_at'])
      
      puts "Name:       #{artifact['name']}"
      puts "Created:    #{created_at.strftime('%Y-%m-%d %H:%M:%S UTC')}"
      puts "Size:       #{size_mb.round(2)} MB"
      puts "Expires:    #{expires_at.strftime('%Y-%m-%d %H:%M:%S UTC')}"
      puts "ID:         #{artifact['id']}"
      puts "-" * 80
    end
  end
end