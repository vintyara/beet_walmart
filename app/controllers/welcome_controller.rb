class WelcomeController < ApplicationController
  def index
  end

  def get_product
    if request.xhr?
      @reviews = []

      # Try to open page with product
      uri   = URI("http://www.walmart.com/ip/#{params[:product_id]}")
      http  = Net::HTTP.new(uri.host, uri.port)
      response = http.request(Net::HTTP::Get.new(uri.request_uri))

      # If success
      if response.code.to_i.eql? 200

        doc = Hpricot(response.body)

        # Try to get review pages count
        doc_pagination    = doc.search("//div[@class='review-pagination js-review-pagination hide-content display-inline-block-m']")
        last_review_page  = doc_pagination.search("//li").last.inner_text

        # Load all reviews
        1.upto(last_review_page.to_i) do |review_page_number|


          # It`s not a get reviews link :(
          #api_url = "http://www.walmart.com/reviews/api/questions/#{params[:product_id]}?sort=totalAnswerCount&pageNumber=#{review_page_number}"

          api_url = "http://www.walmart.com/reviews/api/product/#{params[:product_id]}?limit=5&page=#{review_page_number}&sort=helpful&filters=&showProduct=false"
          puts "Fetching #{api_url}"

          # Parse reviews HTML
          api_response = Net::HTTP.get(URI.parse(api_url))
          ajax_doc = Hpricot(api_response)
          @reviews.push ajax_doc.search("//p").select{ |r| r.attributes['class'].include?('js-customer-review-text\\')}.map{ |r| r.html }

          #result = JSON.parse(api_response)
          #@reviews.push result['questionDetails'].map{ |review_info| review_info['questionSummary'] }
        end
        @reviews.flatten!

        # Select only necessary reviews
        @reviews = @reviews.select { |ele| ele =~ /#{Regexp.escape(params[:review_text])}/ } unless params[:review_text].blank?
      else
        @errors = "Wrong product ID {response code #{response.code}}"
      end
    end

    render 'get_product.js.coffee'
  end
end
