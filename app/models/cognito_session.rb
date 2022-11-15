class CognitoSession < ApplicationRecord
  belongs_to :user

  def logout!
    self.login = false

    save!
  end

  def login!
    self.login = true

    save!
  end
end
