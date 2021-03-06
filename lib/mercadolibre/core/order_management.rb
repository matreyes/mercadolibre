module Mercadolibre
  module Core
    module OrderManagement
      def get_all_orders(filters={})
        filters.merge!({
          seller: get_my_user.id,
          access_token: @access_token,
          limit: 50
        })

        results = []

        kind = filters.delete(:kind)

        if kind.to_s == 'recent'
          orders_urls = ['/orders/search']
        elsif kind.to_s == 'archived'
          orders_urls = ['/orders/search/archived']
        elsif kind.to_s == 'pending'
          orders_urls = ['/orders/search/pending']
        else
          orders_urls = ['/orders/search', '/orders/search/archived', '/orders/search/pending']
        end

        orders_urls.each do |orders_url|
          has_results = true
          filters[:offset] = 0
          pages_remaining = filters[:pages_count] || -1

          while (has_results && (pages_remaining != 0)) do
            partial_results = get_request(orders_url, filters)[:body]['results']

            results += partial_results.map { |r| Mercadolibre::Entity::Order.new(r) }

            has_results = partial_results.any?
            filters[:offset] += 50
            pages_remaining -= 1
          end
        end

        results
      end

      def get_orders(kind, filters={})
        filters.merge!({
          seller: get_my_user.id,
          access_token: @access_token
        })

        if kind.to_s == 'archived'
          url = '/orders/search/archived'
        elsif kind.to_s == 'pending'
          url = '/orders/search/pending'
        else
          url = '/orders/search'
        end

        response = get_request(url, filters)[:body]

        {
          results: response['results'].map { |r| Mercadolibre::Entity::Order.new(r) },
          paging: response['paging']
        }
      end

      def get_order(order_id)
        filters = { access_token: @access_token }
        r = get_request("/orders/#{order_id}", filters)

        Mercadolibre::Entity::Order.new(r[:body])
      end

      def get_order_notes(order_id)
        filters = { access_token: @access_token }
        results = get_request("/orders/#{order_id}/notes", filters)

        results[:body].first['results'].map { |r| Mercadolibre::Entity::OrderNote.new(r) }
      end

      def create_order_note(order_id, text)
        payload = { note: text }.to_json

        headers = { content_type: :json, accept: :json }

        result = post_request("/orders/#{order_id}/notes?access_token=#{@access_token}", payload, headers)

        Mercadolibre::Entity::OrderNote.new(result[:body]['note'])
      end

      def update_order_note(order_id, note_id, text)
        payload = { note: text }.to_json

        headers = { content_type: :json, accept: :json }

        result = put_request("/orders/#{order_id}/notes/#{note_id}?access_token=#{@access_token}", payload, headers)

        Mercadolibre::Entity::OrderNote.new(result[:body]['note'])
      end

      def delete_order_note(order_id, note_id)
        result = delete_request("/orders/#{order_id}/notes/#{note_id}?access_token=#{@access_token}")

        result[:status_code] == 200
      end

      def get_order_feedbacks(order_id)
        filters = { version: '3.0', access_token: @access_token }

        result = get_request("/orders/#{order_id}/feedback", filters)

        Mercadolibre::Entity::OrderFeedback.new(result[:body])
      end

      def get_order_buyer_feedback(order_id)
        filters = { version: '3.0', access_token: @access_token }

        result = get_request("/orders/#{order_id}/feedback/purchase", filters)

        Mercadolibre::Entity::Feedback.new(result[:body])
      end

      def get_order_seller_feedback(order_id)
        filters = { version: '3.0', access_token: @access_token }

        result = get_request("/orders/#{order_id}/feedback/sale", filters)

        Mercadolibre::Entity::Feedback.new(result[:body])
      end

      def create_order_feedback(order_id, feedback_data)
        payload = feedback_data.to_json

        headers = { content_type: :json }

        post_request("/orders/#{order_id}/feedback?version=3.0&access_token=#{@access_token}", payload, headers)[:body]
      end

      def change_order_seller_feedback(order_id, kind, feedback_data)
        payload = feedback_data.to_json

        headers = { content_type: :json }

        put_request("/orders/#{order_id}/feedback/sale?version=3.0&access_token=#{@access_token}", payload, headers)[:body]
      end

      def change_order_buyer_feedback(order_id, kind, feedback_data)
        payload = feedback_data.to_json

        headers = { content_type: :json }

        put_request("/orders/#{order_id}/feedback/purchase?version=3.0&access_token=#{@access_token}", payload, headers)[:body]
      end

      def change_order_feedback(feedback_id, feedback_data)
        payload = feedback_data.to_json

        headers = { content_type: :json }

        put_request("/feedback/#{feedback_id}?version=3.0&access_token=#{@access_token}", payload, headers)[:body]
      end

      def reply_order_feedback(feedback_id, text)
        payload = { reply: text }.to_json

        headers = { content_type: :json }

        post_request("/feedback/{feedback_id}/reply?version=3.0&access_token=#{@access_token}", payload, headers)[:body]
      end

      def get_site_payment_methods(site_id)
        results = get_request("/sites/#{site_id}/payment_methods")

        results[:body].map { |r| Mercadolibre::Entity::PaymentMethod.new(r) }
      end

      def get_site_payment_method_info(site_id, payment_method_id)
        results = get_request("/sites/#{site_id}/payment_methods/#{payment_method_id}")

        Mercadolibre::Entity::PaymentMethod.new(results[:body])
      end

      def get_orders_blacklist(user_id)
        results = get_request("/users/#{user_id}/order_blacklist?access_token=#{@access_token}")
        results[:body].map { |r| r['user']['id'] }
      end

      def add_user_to_orders_blacklist(seller_id, user_id)
        payload = { user_id: user_id }.to_json

        headers = { content_type: :json }

        url = "/users/#{seller_id}/order_blacklist?access_token=#{@access_token}"

        post_request(url, payload, headers)[:status_code] == 200
      end

      def remove_user_from_orders_blacklist(seller_id, user_id)
        url = "/users/#{seller_id}/order_blacklist/#{user_id}?access_token=#{@access_token}"

        delete_request(url)[:status_code] == 200
      end
    end
  end
end
