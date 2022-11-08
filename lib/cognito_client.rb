class CognitoClient
  def initialize(email: nil, password: nil, phone_number: nil, token: nil)
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: ENV["AWS_COGNITO_REGION"],
      access_key_id: ENV["AWS_ACCESS_KEY"],
      secret_access_key: ENV["AWS_SECRET_KEY"]
    )

    @email = email
    @phone_number = phone_number
    @password = password.presence || ENV["DEFAULT_PASSWORD"]
    @token = token
  end

  def create_user
    ap "-> signup_object"
    ap signup_object
    @client.sign_up(signup_object)
  end

  def authenticate
    @client.admin_initiate_auth(auth_object)
  end

  def initiate_auth
    @client.initiate_auth({
                            client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
                            auth_flow: "USER_PASSWORD_AUTH",
                            auth_parameters: auth_object
                          })
  end

  def authenticate2
    @client.authenticate(auth_object).authentication_result
  end

  def user_info
    response = @client.get_user(access_token: @token)

    response.user_attributes.each_with_object({}) { |data, h| h[data.name] = data.value }
  end

  def list_users
    @client.list_users({
                         user_pool_id: ENV["AWS_COGNITO_POOL_ID"]
                       })
  end

  def sign_out
    @client.global_sign_out(access_token: @token)
  end

  private

  def user_object
    {
      username: @email,
      password: @password
    }
  end

  def signup_object
    user_object.merge({ client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
                        user_attributes: [
                          { name: "email", value: @email },
                          { name: "phone_number", value: @phone_number }
                        ] })
  end

  def auth_object
    {
      user_pool_id: ENV["AWS_COGNITO_POOL_ID"],
      client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
      auth_flow: "ADMIN_NO_SRP_AUTH",
      auth_parameters: {
        USERNAME: @email,
        PASSWORD: @password

      }
    }
  end

  def auth_object2
    {
      user_pool_id: ENV["AWS_COGNITO_POOL_ID"],
      client_id: ENV["AWS_COGNITO_APP_CLIENT_ID"],
      auth_flow: "USER_SRP_AUTH",
      auth_parameters: {
        USERNAME: @email
      }
    }
  end
end
