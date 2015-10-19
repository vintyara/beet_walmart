class WelcomeController < ApplicationController
  def index
  end

  def get_product
    if request.xhr?
      @result = parse_reviews
      render 'get_product.js.coffee'
    end
  end

  def parse_reviews
    reviews = []

    # Try to open page with product
    uri   = URI("http://www.walmart.com/ip/#{params[:product_id]}")
    http  = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))

    return { error: "Wrong product ID {response code #{response.code}}" } unless response.code.to_i.eql? 200

    doc = Hpricot(response.body)

    # Try to get review pages count
    doc_pagination    = doc.search("//div[@class='review-pagination js-review-pagination hide-content display-inline-block-m']")
    last_review_page  = doc_pagination.search("//li").last

    # No pagination links found, try to get reviews from product landing page
    unless last_review_page
      result = doc.search("//p[@class='js-customer-review-text']")
      return { error: "No reviews found" } if result.blank?

      reviews = result.map{ |r| r.inner_text }
      # TODO: double code, need to be refactored
      reviews = reviews.select { |ele| ele =~ /#{Regexp.escape(params[:review_text])}/ } unless params[:review_text].blank?
      return { reviews: reviews }
    end

    last_review_page  = last_review_page.inner_text.to_i

    # Load all reviews
    1.upto(last_review_page) do |review_page_number|
      api_url = "http://www.walmart.com/reviews/api/product/#{params[:product_id]}?limit=5&page=#{review_page_number}&sort=helpful&filters=&showProduct=false"
      Rails.logger.info "Fetching #{api_url}"

      # Parse reviews HTML
      api_response = Net::HTTP.get(URI.parse(api_url))
      ajax_doc = Hpricot(api_response)
      reviews.push ajax_doc.search("//p").select{ |r| r.attributes['class'].include?('js-customer-review-text\\')}.map{ |r| r.html }
    end
    reviews.flatten!

    # Select only necessary reviews
    reviews = reviews.select { |ele| ele =~ /#{Regexp.escape(params[:review_text])}/ } unless params[:review_text].blank?

    return { reviews: reviews }
  end
end
