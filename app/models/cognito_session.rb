class CognitoSession < ApplicationRecord
  def reset_expired_token
    self.id_token = nil
    self.access_token = nil

    save!
  end
end
