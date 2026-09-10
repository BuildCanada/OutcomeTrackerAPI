class AddOauthIdentityToAgentRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :agent_runs, :oauth_token_label, :string
    add_column :agent_runs, :oauth_token_fingerprint, :string
  end
end
