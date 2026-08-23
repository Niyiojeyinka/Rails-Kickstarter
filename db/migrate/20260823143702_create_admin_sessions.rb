class CreateAdminSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_sessions do |t|
      # The platform admin (ActiveAdmin user) who owns this session
      t.references :platform_admin, null: false, foreign_key: { to_table: :admin_users }
      t.string :token_digest, null: false
      t.string :issuing_env, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_seen_at
      t.string :last_seen_ip
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :admin_sessions, :token_digest, unique: true
  end
end
