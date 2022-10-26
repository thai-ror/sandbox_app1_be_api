require "cognito_client"

class AuthController < ApplicationController
  before_action :fetch_cognito_session, only: %i[auth store]

  def sign_in
    begin
      response = CognitoClient.new(email: user_signin_params[:email]).authenticate
    rescue StandardError => e
      response = e
    end

    render json: response
  end

  def sign_up
    begin
      response = CognitoClient.new(email: user_signup_params[:email]).create_user
    rescue StandardError => e
      response = e
    end

    render json: response
  end

  def auth
    if @cognito_session.expire_time.nil?
      return render json: { success: false, message: "Invalid user" },
                    status: :bad_request
    end

    if @cognito_session.expire_time <= Time.current
      @cognito_session.reset_expired_token

      return render json: { success: false, message: "Token expired", expire_time: @cognito_session.expire_time },
                    status: :bad_request
    end

    # response = CognitoClient.new(email: user_signin_params[:email]).authenticate

    # ap "response"
    # ap response

    render json: { success: true, expire_time: @cognito_session.expire_time }, status: :ok
  rescue StandardError => e
    render json: { success: false, message: e&.message || e }, status: :internal_server_error
  end

  def store
    @cognito_session.expire_time = Time.current + store_params[:expires_in].to_i.second

    unless @cognito_session.update(store_params.except(:expires_in))
      return render json: { success: false, message: @cognito_session.errors.full_messages.join(",") },
                    status: :bad_request
    end

    render json: { success: true }, status: :ok
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  def sign_out
    if request.headers["Authorization"]
      Cognito.sign_out(request.headers["Authorization"])
      response = { type: "success", message: "now you are disconected" }
    else
      response = { type: "error", message: "empty token" }
    end
    render json: response
  end

  private

  def fetch_cognito_session
    @cognito_session = CognitoSession.find_or_initialize_by(email: params[:email])
  end

  def auth_params
    params.slice(:email).permit!
  end

  def store_params
    params.slice(:access_token, :refresh_token, :id_token, :expires_in).permit!
  end

  def user_signup_params
    params.slice(:email).permit!
  end

  def user_signin_params
    params.slice(:email).permit!
  end
end