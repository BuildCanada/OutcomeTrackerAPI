# GoodJob configuration
Rails.application.configure do
  # Configure GoodJob settings
  
  # For async mode, how often to poll for new jobs, does not apply to external mode
  config.good_job.poll_interval = 30
  config.good_job.shutdown_timeout = 25

  # Enable cron jobs
  config.good_job.enable_cron = true
  config.good_job.cron_graceful_restart_period = 1.minute

  config.good_job.cron = {
    feed_refresh: { # each recurring job must have a unique key
      cron: "every 3 hours", # cron-style scheduling format by fugit gem
      class: "FeedRefresherJob", # name of the job class as a String; must reference an Active Job job class
      description: "Refreshed feeds and creates new entries", # optional description that appears in Dashboard,
      enabled_by_default: -> { Rails.env.production? } # Only enable in production, otherwise can be enabled manually through Dashboard
    }
  }

  # Preserve job records for debugging
  config.good_job.preserve_job_records = true
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 14.days

  # Dashboard authentication (customize as needed)
  config.good_job.dashboard_default_locale = :en

  # Queue configuration
  config.good_job.queues = "*"


  # Smaller batch size for better performance
  config.good_job.cleanup_interval_jobs = 1000
  config.good_job.cleanup_interval_seconds = 600
end
