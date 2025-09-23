# Choose the lake service (local for dev/test)
LAKE_SERVICE_NAME = :lake_local

# Build a direct handle to the configured Active Storage service
LAKE_STORAGE = ActiveStorage::Service.configure(
  LAKE_SERVICE_NAME,
  Rails.application.config.active_storage.service_configurations.fetch(LAKE_SERVICE_NAME.to_s)
)
