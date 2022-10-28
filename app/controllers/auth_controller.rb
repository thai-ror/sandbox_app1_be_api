require "cognito_client"

class AuthController < ApplicationController
  before_action :fetch_cognito_session, only: %i[auth store sign_in sign_up]

  def sign_in
    ActiveRecord::Base.transaction do
      response = CognitoClient.new(email: user_signin_params[:email], password: user_signin_params[:password]).authenticate.authentication_result

      @cognito_session.update(
        login: true,
        expire_time: Time.current + response.expires_in.to_i.second,
        id_token: response.id_token,
        access_token: response.access_token,
        refresh_token: response.refresh_token
      )

      render json: { success: true, data: @cognito_session }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e&.message || e }, status: :internal_server_error
  end

  def sign_up
    ActiveRecord::Base.transaction do
      response = CognitoClient.new(email: user_signup_params[:email]).create_user

      if @cognito_session.new_record?
        @cognito_session.update(
          subscriber: response.user_sub
        )
      end

      render json: { success: true, data: response }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e&.message || e }, status: :internal_server_error
  end

  def auth
    return render json: { success: true, login: false }, status: :ok if @cognito_session.new_record?

    # if @cognito_session.expire_time.nil?
    #   return render json: { success: false, message: "Invalid user" },
    #                 status: :bad_request
    # end
    ActiveRecord::Base.transaction do
      if @cognito_session.expire_time <= Time.current
        # @cognito_session.reset_expired_token
        # CognitoClient.new(token: @cognito_session.access_token).sign_out
        @cognito_session.logout!

        return render json: { success: false, login: @cognito_session.login, message: "Token expired" },
                      status: :bad_request
      end

      user_info = CognitoClient.new(token: @cognito_session.access_token).user_info

      # unless user_info["email_verified"].to_bool
      #   return render json: { success: false, message: "Email is not verified" },
      #                 status: :bad_request
      # end

      render json: {
        success: true,
        login: @cognito_session.login,
        access_token: @cognito_session.access_token,
        expire_time: @cognito_session.expire_time
      }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e&.message || e }, status: :internal_server_error
  end

  def store
    ActiveRecord::Base.transaction do
      @cognito_session.expire_time = Time.current + store_params[:expires_in].to_i.second
      @cognito_session.login = true

      unless @cognito_session.update(store_params.except(:expires_in))
        return render json: { success: false, message: @cognito_session.errors.full_messages.join(",") },
                      status: :bad_request
      end

      user_info = CognitoClient.new(token: store_params[:access_token]).user_info

      render json: { success: true, user_info: user_info }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  def sign_out
    ActiveRecord::Base.transaction do
      CognitoClient.new(token: user_signout_params[:access_token]).sign_out
      @cognito_session.logout!

      render json: { success: true }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  private

  def fetch_cognito_session
    @cognito_session = CognitoSession.find_by(access_token: params[:access_token])
    @cognito_session = CognitoSession.find_or_initialize_by(email: params[:email]) if @cognito_session.nil?
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
    params.slice(:email, :password).permit!
  end

  def user_signout_params
    params.slice(:email, :access_token).permit!
  end
end
