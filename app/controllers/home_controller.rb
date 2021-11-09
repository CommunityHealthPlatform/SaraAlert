# frozen_string_literal: true

# HomeController: redirects based on role
class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to dashboard_url
  end
end
