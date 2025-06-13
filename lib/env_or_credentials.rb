module EnvOrCredentials
  def self.fetch!(env_key, diggable_key)
    cred_path = diggable_key.is_a?(Array) ? diggable_key : [ diggable_key ]
    ENV.fetch(env_key) { Rails.application.credentials.dig!(*cred_path) }
  end
end
