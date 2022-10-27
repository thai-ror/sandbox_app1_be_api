class CognitoSession < ApplicationRecord
  # belongs_to :user

  def reset_expired_token
    self.id_token = nil
    self.access_token = nil

    save!
  end

  def logout!
    self.login = false

    save!
  end

  def login!
    self.login = true

    save!
  end
end
