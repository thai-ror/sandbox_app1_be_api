class CreateCognitoSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :cognito_sessions do |t|
      t.string :email, null: false, unique: true
      t.datetime :expire_time
      t.text :id_token
      t.text :access_token
      t.text :refresh_token

      t.timestamps
    end
  end
end
