class AddPasswordColumnToCognitoClient < ActiveRecord::Migration[6.1]
  def change
    add_column :cognito_sessions, :password, :string
  end
end
