class SessionsController < ApplicationController
  before_filter :check_permissions, :only => [:create]

  def new
    if Rails.env.development?
      redirect_to '/auth/developer'
    else
      redirect_to '/auth/github'
    end
  end

  def create
    unless user = User.find_by_uid(auth_hash['uid'])
      user = User.create_from_hash(auth_hash)
    end

    if user.errors.any?
      flash[:error] = user.errors.full_messages.join(", ")
    else
      self.current_user = user
    end

    redirect_back_or_default root_path
  end

  def destroy
    self.current_user = nil

    redirect_to root_path
  end

  def failure
    flash[:error] = "There was a problem logging in. Please try again"

    self.current_user = nil # Try destroying the current_user

    redirect_to root_path
  end

  private

  def auth_hash
    hash = request.env['omniauth.auth']
    hash['uid'] = hash['uid'].to_s

    hash
  end

  def check_permissions
    nick = auth_hash['info']['nickname']
    user = UniversityWeb::User.find_by_github(nick)

    alert = \
      if user.nil?
        logger.warn "[session] #{nick} doesn't exist"
        "Your github account is not registered on University-web"
      elsif !user.alumnus && !user.staff && !user.visiting_teacher
         logger.warn "[session] #{nick} access denied"
        "Sorry, but currently only Alumni and Staff have access to this site"
      end

    unless alert.blank?
      redirect_to root_path, :alert => alert
    end
  end

end
