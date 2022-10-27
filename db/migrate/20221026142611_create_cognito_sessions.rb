class CreateCognitoSessions < ActiveRecord::Migration[6.1]
  def change
    create_table :cognito_sessions do |t|
      # t.references :user, index: true, null: false
      t.string :email, null: false, unique: true
      t.string :subscriber, unique: true
      t.datetime :expire_time
      t.text :id_token
      t.text :access_token
      t.text :refresh_token
      t.boolean :login, default: false

      t.timestamps
    end
  end
end
