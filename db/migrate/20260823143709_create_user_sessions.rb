class CreateUserSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      # JWT ID — the JWT references this; deleting/revoking the row kills the token
      t.string :jti, null: false
      t.string :issuing_env, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_seen_at
      t.string :last_seen_ip
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :user_sessions, :jti, unique: true
  end
end
