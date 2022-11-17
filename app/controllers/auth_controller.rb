require "cognito_client"

class AuthController < ApplicationController
  before_action :fetch_user, only: %i[store]
  before_action :fetch_cognito_session, only: %i[store auth sign_out]

  def auth
    return render json: { success: true, login: false } if @cognito_session.new_record?

    ActiveRecord::Base.transaction do
      if @cognito_session.expire_time <= Time.current

        return render json: { success: false, login: @cognito_session.login, message: "Token expired" },
                      status: :bad_request
      end

      user_info = CognitoClient.new(token: @cognito_session.access_token).user_info

      render json: {
        success: true,
        login: @cognito_session.login,
        expire_time: @cognito_session.expire_time,
        user_info: user_info
      }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e&.message || e }, status: :internal_server_error
  end

  def store
    ap "--> store_params"
    ap store_params

    ActiveRecord::Base.transaction do
      if @user.new_record?
        @user.email = params[:email]

        @user.save
      end

      @cognito_session.assign_attributes(user_id: @user.id,
                                         expire_time: Time.zone.at(Time.current + store_params[:expire_time].to_i.seconds),
                                         issued_time: Time.current,
                                         access_token: store_params[:access_token].strip,
                                         refresh_token: store_params[:refresh_token].strip,
                                         login: true)

      @cognito_session.save

      user_info = CognitoClient.new(token: @cognito_session.access_token).user_info

      ap "--> @cognito_session"
      ap @cognito_session

      render json: { success: true, user_info: user_info }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  def sign_out
    ActiveRecord::Base.transaction do
      CognitoClient.new(token: user_signout_params[:access_token]).sign_out
      @cognito_session.logout! if @cognito_session&.persisted?

      render json: { success: true }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  private

  def fetch_user
    unless params[:subscriber]
      return render json: { success: false, message: "Missing subscriber" },
                    status: :bad_request
    end

    @user = User.find_or_initialize_by(subscriber: params[:subscriber])
  end

  def fetch_cognito_session
    @cognito_session = CognitoSession.find_or_initialize_by(access_token: store_params[:access_token])

    ap "--> fetch_cognito_session"
    ap params.to_unsafe_h

    ap "cognito_session"
    ap @cognito_session
  end

  def auth_params
    params.slice(:access_token).permit!
  end

  def user_params
    params.slice(:email, :subscriber).permit!
  end

  def store_params
    params.slice(:access_token, :refresh_token, :id_token, :issued_time, :expire_time,
                 :audience).permit!
  end

  def user_signup_params
    params.slice(:email, :password, :phone_number).permit!
  end

  def user_signin_params
    params.slice(:email, :password).permit!
  end

  def user_signout_params
    params.slice(:access_token).permit!
  end
end
