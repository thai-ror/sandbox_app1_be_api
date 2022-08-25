class CognitoClient
  def initialize(email:, token: nil)
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: ENV["AWS_COGNITO_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY"],
      secret_access_key: ENV["AWS_SECRET_KEY"]
    )

    @email = email
    @token = token
  end

  def create_user
    @client.sign_up(signup_object)
  end

  def authenticate
    @client.admin_initiate_auth(auth_object)
  end

  def sign_out(access_token)
    @client.global_sign_out(access_token: access_token)
  end

  private

  def user_object
    {
      username: @email,
      password: ENV["DEFAULT_PASSWORD"]
    }
  end

  def signup_object
    user_object.merge({ client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
                        user_attributes: [{ name: "email", value: @email }] })
  end

  def auth_object
    {
      user_pool_id: ENV["AWS_COGNITO_POOL_ID"],
      client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
      auth_flow: "ADMIN_NO_SRP_AUTH",
      auth_parameters: {
        USERNAME: @email,
        PASSWORD: ENV["DEFAULT_PASSWORD"]

      }
    }
  end
end
