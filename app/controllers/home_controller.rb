class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ show once tour ]

  def show
  end

  def once
  end

  def tour
    @tour_page = params[:feature].presence || Tour::PAGES.first
    position = Tour::PAGES.index(@tour_page)
    return head :not_found unless position

    @tour_previous = Tour::PAGES[position - 1] if position.positive?
    @tour_next = Tour::PAGES[position + 1]
    @tour_feature = Tour::FEATURES[@tour_page]
    @tour_count = format("%02d / %02d", position, Tour::FEATURES.size) if @tour_feature
  end
end
