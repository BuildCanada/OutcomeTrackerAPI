module EnvOrCredentials
  def self.fetch(env_key, diggable_key)
    cred_path = diggable_key.is_a?(Array) ? diggable_key : [ diggable_key ]
    env_value = ENV[env_key]
    return env_value if env_value.present?

    return nil if build_phase?

    Rails.application.credentials.dig(*cred_path)
  end

  def self.build_phase?
    argv = Array(ARGV)
    argv.include?("assets:precompile") || argv.include?("bootsnap:precompile")
  end
end
