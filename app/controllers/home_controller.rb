class HomeController < ApplicationController
  def index
    @room = Room.new
  end

  def test
  end
end
