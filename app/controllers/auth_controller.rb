require "cognito_client"

class AuthController < ApplicationController
  before_action :fetch_user, only: %i[store]
  before_action :fetch_cognito_session, only: %i[store auth sign_out]

  def auth
    valid, error_message = params_valid?(auth_attributes)

    return render json: { success: false, message: error_message }, status: :bad_request unless valid
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
    valid, error_message = params_valid?(store_attributes)

    return render json: { success: false, message: error_message }, status: :bad_request unless valid

    ActiveRecord::Base.transaction do
      if @user.new_record?
        @user.email = params[:email].strip

        @user.save
      end

      @cognito_session.assign_attributes(user_id: @user.id,
                                         expire_time: Time.zone.at(Time.current + store_params[:expire_time].to_i.seconds),
                                         issued_time: Time.current,
                                         refresh_token: store_params[:refresh_token].strip,
                                         id_token: store_params[:id_token].strip,
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
    valid, error_message = params_valid?(sign_out_attributes)

    return render json: { success: false, message: error_message }, status: :bad_request unless valid

    ActiveRecord::Base.transaction do
      CognitoClient.new(token: signout_params).sign_out
      @cognito_session.destroy if @cognito_session&.persisted?

      render json: { success: true }, status: :ok
    end
  rescue StandardError => e
    render json: { success: false, message: e.message }, status: :internal_server_error
  end

  private

  def fetch_user
    valid, error_message = params_valid?(user_attributes)

    return render json: { success: false, message: error_message }, status: :bad_request unless valid

    @user = User.find_or_initialize_by(subscriber: user_params[:subscriber])
  end

  def fetch_cognito_session
    @cognito_session = CognitoSession.find_or_initialize_by(access_token: auth_params)

    ap "--> fetch_cognito_session"
    ap params.to_unsafe_h

    ap "cognito_session"
    ap @cognito_session
  end

  def auth_params
    params[:access_token]&.strip
  end

  def user_params
    params.slice(*user_attributes).permit!
  end

  def store_params
    params.slice(*store_attributes).permit!
  end

  def signout_params
    params[:access_token]&.strip
  end

  def user_attributes
    %i[email subscriber]
  end

  def store_attributes
    %i[access_token refresh_token id_token expire_time]
  end

  def auth_attributes
    %i[access_token]
  end

  def sign_out_attributes
    %i[access_token]
  end

  def params_valid?(attributes)
    attributes.each { |attr| return [false, "Missing #{attr} param"] unless params.key?(attr) }

    [true, nil]
  end

  def user_signup_params
    params.slice(:email, :password, :phone_number).permit!
  end

  def user_signin_params
    params.slice(:email, :password).permit!
  end
end
