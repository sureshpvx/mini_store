require 'net/http'
require 'json'

class AiClient
  WEBSITE_CONTEXT = <<~CONTEXT
    You are the AI shopping assistant for HYPE — a premium streetwear e-commerce store.

    CRITICAL RULES — NEVER BREAK THESE:
    1. NEVER invent product names, prices, or descriptions. Only use real data from the system.
    2. NEVER make up cart contents or order details. Always use real database queries.
    3. If you don't have real product data, say "Let me search for you" — do NOT make up products.
    4. NEVER use dollar signs ($) — all prices are in Indian Rupees (₹).
    5. NEVER hallucinate product lists. If the system doesn't provide products, admit it.

    About HYPE:
    - Premium streetwear brand with minimalist aesthetics
    - Products: Men, Women, and Accessories categories
    - 30+ items in the collection
    - New Arrivals drop regularly (SS/26 Collection currently active)
    - All products are premium quality

    Store Policies:
    - Shipping & Delivery available
    - Returns & Exchanges accepted
    - Size Guide available on the website
    - Contact page for support
    - FAQ page for common questions

    IMPORTANT — You have REAL abilities through the backend system:
    - You CAN add products to the customer's cart
    - You CAN search for products and show results
    - You CAN show cart contents
    - You CAN remove items from cart
    - You CAN show product details
    - You CAN show order status, payment status, and tracking details
    - You CAN show shipping address and delivery info

    When a customer asks you to perform an action (like adding to cart), 
    CONFIRM that you will do it. Do NOT say "I can't" or "I don't have the ability".
    The backend handles the actual action before your response is shown.

    If you can't find a specific product, suggest alternatives or ask the customer
    to be more specific about what they're looking for.

    Keep responses brief (2-3 sentences max) since they may be spoken aloud.
    If you don't know something specific, direct users to the Contact page or FAQ.
  CONTEXT

  class Error < StandardError; end
  class ConnectionError < Error; end

  def initialize(cart: nil, user: nil)
    @provider = determine_provider
    @cart = cart
    @user = user
    @last_product = nil
  end

  def generate(user_prompt)
    # 1. Add to cart (highest priority)
    if add_to_cart_request?(user_prompt)
      result = handle_add_to_cart(user_prompt)
      return result if result
    end

    # 2. Remove from cart
    if remove_from_cart_request?(user_prompt)
      result = handle_remove_from_cart(user_prompt)
      return result if result
    end

    # 3. View cart contents
    if view_cart_request?(user_prompt)
      return handle_view_cart
    end

    # 4. List all products
    if list_products_request?(user_prompt)
      return handle_list_products(user_prompt)
    end

    # 5. Product details
    if product_details_request?(user_prompt)
      result = handle_product_details(user_prompt)
      return result if result
    end

    # 6. Order status / payment / tracking (logged-in users only)
    if order_status_request?(user_prompt)
      return handle_order_status(user_prompt)
    end

    # 7. Product search
    if product_search_request?(user_prompt)
      products = search_products(user_prompt)
      if products.any?
        return format_product_results(products)
      end
    end

    # 8. Fallback to LLM
    case @provider
    when :groq
      call_groq(user_prompt)
    when :ollama
      call_ollama(user_prompt)
    else
      raise Error, "No AI provider configured. Set GROQ_API_KEY or run Ollama locally."
    end
  end

  # Returns metadata about actions performed (for frontend)
  attr_reader :action_performed, :cart_count

  private

  attr_reader :cart, :user

  def build_llm_context
    # Cart state
    cart_context = if cart && cart.cart_items.any?
                     items = cart.cart_items.includes(:product).map { |i| "#{i.product.name} (₹#{i.product.price.to_i}) x#{i.quantity}" }.join(", ")
                     "Cart: #{items} | Total: #{cart.cart_items.sum(:quantity)} items"
                   else
                     "Cart: Empty"
                   end

    # Real products from DB (sample)
    products_context = begin
                         sample = Product.active.limit(5).pluck(:name, :price)
                         if sample.any?
                           "Real products: " + sample.map { |n, p| "#{n} (₹#{p.to_i})" }.join(", ")
                         else
                           "Products: Database unavailable"
                         end
                       rescue => e
                         "Products: Error loading"
                       end

    # Order state
    order_context = if user && user.orders.any?
                      recent = user.orders.order(created_at: :desc).first
                      "Last order: ##{recent.id} — #{recent.status.titleize} — ₹#{recent.total_price.to_i}"
                    else
                      "Orders: None"
                    end

    "#{WEBSITE_CONTEXT}\n\nCURRENT STATE:\n#{cart_context}\n#{products_context}\n#{order_context}\n\nRULE: Use ONLY the real data above. NEVER invent products or prices."
  end

  def determine_provider
    return :groq if ENV['GROQ_API_KEY'].present?
    return :ollama if ollama_running?
    nil
  end

  def ollama_running?
    Net::HTTP.get(URI('http://localhost:11434/api/tags'))
    true
  rescue
    false
  end

  # ─── INTENT DETECTION ───────────────────────────────────────────────

  def add_to_cart_request?(prompt)
    p = prompt.downcase.strip
    patterns = [
      /add .* (to|in) (my )?(cart|bag|basket)/,
      /put .* (in|into) (my )?(cart|bag|basket)/,
      /(buy|purchase|get|grab|order) (the |a |an |this |that |some )?[\w\s]+/,
      /i (want|need|would like|wanna) (the |a |an |this |that |some )?[\w\s]+ (please)?$/,
      /cart (the |this |that )?/,
      /add (it|this|that|the same) (to|in)/,
      /yes.*(add|cart|buy|want)/,
      /add (it|that|this) (please)?$/,
      /^(add|yes),? (please|add|that|it|this)/,
      /^add [\w\s]{3,}$/,                          # "add dark fashion", "add hoodie"
      /^add (the |a )?\w+/,                         # "add the hoodie", "add a tee"
      /add .+ (please|now|quickly|asap)$/,           # "add dark fashion please"
      /^(add|buy|get) (first|second|third|last|this|that|the) (product|item|one)/,  # "add first product"
      /^(add|buy|get|grab|order)\s+(another|more|extra|2|3|4|5|two|three|four|five)/,  # "add two more", "add another"
      /^(another|more|extra)\s+(one|two|three|four|five|please)/,  # "another one", "two more"
    ]
    patterns.any? { |pat| p.match?(pat) }
  end

  def remove_from_cart_request?(prompt)
    p = prompt.downcase.strip
    p.match?(/(remove|delete|take out|drop|clear) .* (from )?(my )?(cart|bag|basket)/) ||
      p.match?(/remove (it|this|that|them|these|those|all|everything) (from )?(my )?(cart|bag)?/) ||
      p.match?(/^(remove|delete|clear) (the |a |my )?[\w\s]+ (from cart|from bag)?$/) ||
      p.match?(/empty (my )?(cart|bag|basket)/) ||
      p.match?(/clear (my )?(cart|bag|basket)/) ||
      p.match?(/(remove|delete|take out|drop)\s+(them|all|everything|these|those)/)
  end

  def view_cart_request?(prompt)
    p = prompt.downcase.strip
    p.match?(/(show|view|open|check|see|what'?s in) (my |the )?(cart|card|bag|basket)/) ||
      p.match?(/^(my )?(cart|card|bag) ?(items|contents|stuff)?$/) ||
      p.match?(/what (do i|i) have in (my )?(cart|card|bag)/) ||
      p.match?(/cart (items|contents|summary|details)/) ||
      p.match?(/(products|items|things) (i |you |i'?ve )?(added|put) (in|to)/) ||
      p.match?(/added.*(cart|card|bag)/) ||
      p.match?(/in (my |the )?card$/)
  end

  def list_products_request?(prompt)
    p = prompt.downcase.strip
    # Don't match if user is asking about their cart contents
    return false if p.match?(/(added|put|my cart|my card|my bag|i have|in cart|in card)/)

    p.match?(/list (all |the |your )?(products|items|collection|catalog)/) ||
      p.match?(/show (me )?(all |the |your )?(products|items|collection|catalog)/) ||
      p.match?(/what (products|items|things) (do you|you) (have|sell|offer)/) ||
      p.match?(/what('?s| is) (in |your )?(stock|collection|catalog)/) ||
      p.match?(/browse (products|items|collection)/) ||
      p.match?(/^(all )?(products|items|catalog|collection)$/)
  end

  def product_details_request?(prompt)
    p = prompt.downcase.strip
    p.match?(/(tell me|more) (about|details|info) (the |a )?/) ||
      p.match?(/details (of|for|about|on) (the |a )?/) ||
      p.match?(/what (is|are) (the )?.+ (like|about|made of)/) ||
      p.match?(/describe (the |a )?/) ||
      p.match?(/how much (is|does|for) (the |a )?/)
  end

  def order_status_request?(prompt)
    p = prompt.downcase.strip
    p.match?(/my order/) ||
      p.match?(/order (status|history|tracking|details|info)/) ||
      p.match?(/track (my )?(order|package|delivery)/) ||
      p.match?(/where('?s| is) my (order|package|delivery)/) ||
      p.match?(/past orders/) ||
      p.match?(/order history/) ||
      p.match?(/payment (status|details|info|paid|unpaid|refund)/) ||
      p.match?(/is my order paid/) ||
      p.match?(/did my payment go through/) ||
      p.match?(/razorpay/) ||
      p.match?(/shipping (address|details|info)/) ||
      p.match?(/when will my order arrive/) ||
      p.match?(/delivery (status|time|date)/)
  end

  def product_search_request?(prompt)
    keywords = %w[find search show looking\ for want need hoodie t-shirt tee shirt
                   pants jeans jacket accessories cap hat bag sunglasses belt
                   sneakers shoes boots shorts sweatshirt crewneck polo]
    p = prompt.downcase
    keywords.any? { |kw| p.include?(kw) }
  end

  # ─── ACTION HANDLERS ────────────────────────────────────────────────

  def handle_add_to_cart(prompt)
    # FIX: Parse quantity first (e.g., "add two more", "add 3", "another one")
    quantity = parse_quantity(prompt)

    product_name = extract_product_name(prompt, :add)

    # FIX: Handle pronoun references with quantity ("add two more of those", "add another one")
    # If product name is empty, too short, or just a pronoun/number → use last product
    if product_name.blank? || product_name.length < 2 ||
       %w[it that this same another more extra one two three four five].include?(product_name) ||
       product_name.match?(/^(\d+|more|another|extra)$/)

      last_product = find_last_mentioned_product
      if last_product
        added = add_product_to_cart(product, quantity: quantity)
        if added
          @action_performed = 'cart_updated'
          @cart_count = cart.reload.cart_items.sum(:quantity)
          total_qty = cart.cart_items.find_by(product: last_product)&.quantity || quantity
          return "✅ Added #{quantity > 1 ? quantity.to_s + ' more' : 'another'} '#{last_product.name}' (₹#{last_product.price.to_i}) to your cart! You now have #{@cart_count} item#{'s' if @cart_count != 1}. [View Cart](/cart)"
        end
      end
      return nil # Let AI handle
    end

    product = Product.active.search(product_name).first

    if product
      added = add_product_to_cart(product, quantity: quantity)
      if added
        @action_performed = 'cart_updated'
        @cart_count = cart.reload.cart_items.sum(:quantity)
        return "✅ Added '#{product.name}' (₹#{product.price.to_i}) #{quantity > 1 ? 'x' + quantity.to_s : ''} to your cart! You now have #{@cart_count} item#{'s' if @cart_count != 1}. [View Cart](/cart)"
      else
        return "I found '#{product.name}' but couldn't add it to cart right now. You can add it manually: [View Product](/products/#{product.slug})"
      end
    else
      # Try fuzzy search with shorter name
      short_name = product_name.split.first(2).join(' ')
      product = Product.active.search(short_name).first if short_name.length >= 3

      if product
        added = add_product_to_cart(product, quantity: quantity)
        if added
          @action_performed = 'cart_updated'
          @cart_count = cart.reload.cart_items.sum(:quantity)
          return "✅ I found '#{product.name}' and added it to your cart! You now have #{@cart_count} item#{'s' if @cart_count != 1}. [View Cart](/cart)"
        end
      end

      return nil # Let AI handle with natural language
    end
  end

  def handle_remove_from_cart(prompt)
    return "Your cart is empty — nothing to remove!" unless cart && cart.cart_items.any?

    p = prompt.downcase.strip

    # 1. Empty/clear entire cart
    if p.match?(/(empty|clear) (my )?(cart|bag|basket|all)/)
      count = cart.cart_items.count
      cart.cart_items.destroy_all
      cart.reload  # FIX: force reload
      @action_performed = 'cart_updated'
      @cart_count = 0
      return "🗑️ Cart cleared! Removed #{count} item#{'s' if count != 1}. Your cart is now empty."
    end

    # 2. Remove all / them / everything / these / those / it (pronoun-based bulk removal)
    # FIX: Check for pronouns BEFORE extracting product name
    pronouns = %w[them it this that these those all everything]
    has_pronoun = pronouns.any? { |pr| p.match?(/(?:^|\s)#{Regexp.escape(pr)}(?:\s|$)/) }

    if has_pronoun || p.match?(/^(remove|delete|take out|drop)\s+(all|everything)/)
      count = cart.cart_items.count
      cart.cart_items.destroy_all
      cart.reload  # FIX: force reload
      @action_performed = 'cart_updated'
      @cart_count = 0
      return "🗑️ Removed #{count} item#{'s' if count != 1} from your cart. Your cart is now empty."
    end

    # 3. Try to find specific product by name
    product_name = extract_product_name(prompt, :remove)

    if product_name.present? && product_name.length >= 2
      cart_item = cart.cart_items.joins(:product).where("LOWER(products.name) LIKE ?", "%#{product_name}%").first

      if cart_item.nil?
        product = Product.active.search(product_name).first
        cart_item = cart.cart_items.find_by(product: product) if product
      end

      if cart_item
        name = cart_item.product.name
        cart_item.destroy
        cart.reload  # FIX: force reload
        @action_performed = 'cart_updated'
        @cart_count = cart.cart_items.sum(:quantity)
        return "🗑️ Removed '#{name}' from your cart. You have #{@cart_count} item#{'s' if @cart_count != 1} left. [View Cart](/cart)"
      end
    end

    # 4. Fallback: show what's in cart and ask which to remove
    items = cart.cart_items.includes(:product)
    list = items.map.with_index(1) { |ci, i| "#{i}. #{ci.product.name}" }.join("\n")
    count = items.sum(:quantity)

    "I see #{count} item#{'s' if count != 1} in your cart:\n\n#{list}\n\nWhich one would you like to remove? Say \"remove [number]\" or \"remove all\"."
  end

  def handle_view_cart
    # FIX: Force reload to get fresh data from DB
    cart.reload unless cart.new_record?

    unless cart && cart.cart_items.any?
      return "Your cart is empty! Browse our [products](/products) to find something you'll love. 🛒"
    end

    items = cart.cart_items.includes(:product)
    # FIX: Calculate total directly from items, not cached method
    total = items.sum { |ci| ci.product.price * ci.quantity }.to_i
    count = items.sum(:quantity)

    response = "🛒 Your cart (#{count} item#{'s' if count != 1}):\n\n"
    items.each_with_index do |ci, i|
      response += "#{i + 1}. #{ci.product.name} — ₹#{ci.product.price.to_i} × #{ci.quantity}\n"
    end
    response += "\n**Total: ₹#{total}**\n"
    response += "\n[Go to Checkout](/checkout) or keep shopping!"
    response
  end

  def handle_list_products(prompt)
    p = prompt.downcase

    # Check for category filters
    products = if p.match?(/(men|man|male|guy|boy)/)
                 Product.active.joins(:category).where("LOWER(categories.name) LIKE ?", "%men%").limit(8)
               elsif p.match?(/(women|woman|female|girl|lady|ladies)/)
                 Product.active.joins(:category).where("LOWER(categories.name) LIKE ?", "%women%").limit(8)
               elsif p.match?(/(accessor|cap|hat|bag|belt|sunglasses)/)
                 Product.active.joins(:category).where("LOWER(categories.name) LIKE ?", "%accessor%").limit(8)
               elsif p.match?(/(new|latest|arrival|recent|fresh)/)
                 Product.active.order(created_at: :desc).limit(8)
               elsif p.match?(/trend|popular|hot|best|top/)
                 Product.active.order(views_count: :desc).limit(8)
               else
                 Product.active.limit(10)
               end

    return "No products found in that category. Check out our [full collection](/products)." if products.empty?

    response = "Here are our products:\n\n"
    products.each_with_index do |product, i|
      response += "#{i + 1}. **#{product.name}** — ₹#{product.price.to_i}\n"
    end
    response += "\n[View all products](/products) | Say \"add [product name] to cart\" to purchase!"
    response
  end

  def handle_product_details(prompt)
    product_name = extract_product_name(prompt, :details)
    return nil if product_name.blank? || product_name.length < 2

    product = Product.active.search(product_name).first
    return nil unless product

    # Store as last mentioned product
    @last_product = product

    stock_status = if product.stock <= 0
                     "❌ Out of stock"
                   elsif product.low_stock?
                     "⚠️ Only #{product.stock} left — hurry!"
                   else
                     "✅ In stock"
                   end

    response = "**#{product.name}** — ₹#{product.price.to_i}\n\n"
    response += "#{product.description.truncate(150)}\n\n"
    response += "#{stock_status}\n"
    response += "Category: #{product.category.name}\n\n"
    response += "Say \"add to cart\" to buy it or [view full details](/products/#{product.slug})"
    response
  end

  def handle_order_status(user_prompt)
    unless user
      return "Please [sign in](/otp-login) to view your orders. I'll be able to show your order history, payment status, and tracking once you're logged in!"
    end

    # FIX: Sync payment status from Razorpay before showing
    sync_payment_status_from_razorpay

    # Check if user is asking about a specific order by number/ID
    order_id = extract_order_id(user_prompt)

    if order_id
      order = user.orders.find_by(id: order_id)
      return "I couldn't find order ##{order_id}. Check your [order history](/orders) for all your orders." unless order
      return format_single_order(order)
    end

    # Show recent orders summary
    orders = user.orders.order(created_at: :desc).limit(5)

    if orders.empty?
      return "You don't have any orders yet. Browse our [products](/products) and find something amazing! 🛍️"
    end

    # Check if asking about payment specifically
    if user_prompt.downcase.match?(/payment|paid|unpaid|refund|razorpay/)
      return format_payment_summary(orders)
    end

    # Check if asking about shipping/delivery
    if user_prompt.downcase.match?(/shipping|delivery|address|where|arrive|when/)
      return format_shipping_summary(orders)
    end

    # General order status
    response = "📦 Your recent orders:\n\n"
    orders.each_with_index do |order, i|
      status_emoji = case order.status
                     when 'pending' then '🟡'
                     when 'confirmed' then '🟢'
                     when 'shipped' then '🚚'
                     when 'delivered' then '✅'
                     when 'cancelled' then '❌'
                     else '🔵'
                     end

      payment_status = case order.payment_status
                       when 0 then '⏳ Unpaid'
                       when 1 then '✅ Paid'
                       when 2 then '💰 Refunded'
                       else '❓ Unknown'
                       end

      response += "#{i + 1}. Order ##{order.id} — ₹#{order.total_price.to_i} #{status_emoji} #{order.status.titleize} | #{payment_status}\n"
    end
    response += "\nSay \"order details [number]\" for full info, or [view all orders](/orders)"
    response
  end

  # ─── ORDER FORMATTING HELPERS ───────────────────────────────────────

  def format_single_order(order)
    status_emoji = case order.status
                   when 'pending' then '🟡'
                   when 'confirmed' then '🟢'
                   when 'shipped' then '🚚'
                   when 'delivered' then '✅'
                   when 'cancelled' then '❌'
                   else '🔵'
                   end

    payment_status = case order.payment_status
                     when 0 then '⏳ Unpaid — Complete payment to confirm'
                     when 1 then '✅ Paid — Order confirmed'
                     when 2 then '💰 Refunded'
                     else '❓ Unknown'
                     end

    payment_icon = case order.payment_status
                   when 0 then '⚠️'
                   when 1 then '✅'
                   when 2 then '💰'
                   else '❓'
                   end

    response = "**Order ##{order.id}** #{status_emoji}\n\n"
    response += "📊 Status: #{order.status.titleize}\n"
    response += "#{payment_icon} Payment: #{payment_status}\n"
    response += "💵 Total: ₹#{order.total_price.to_i}\n\n"

    # Order items
    response += "🛍️ Items:\n"
    order.order_items.includes(:product).each_with_index do |item, i|
      response += "  #{i + 1}. #{item.product.name} — ₹#{item.price.to_i} × #{item.quantity}\n"
    end

    # Payment details
    response += "\n💳 Payment Details:\n"
    if order.razorpay_order_id.present?
      response += "  Razorpay Order ID: `#{order.razorpay_order_id}`\n"
    end
    if order.razorpay_payment_id.present?
      response += "  Razorpay Payment ID: `#{order.razorpay_payment_id}`\n"
    end
    if order.razorpay_signature.present?
      response += "  Payment Signature: Verified ✅\n"
    end

    # Shipping address
    if order.shipping_full_name.present?
      response += "\n📍 Shipping Address:\n"
      response += "  #{order.shipping_full_name}\n"
      response += "  #{order.shipping_address_line_1}\n"
      response += "  #{order.shipping_address_line_2}\n" if order.shipping_address_line_2.present?
      response += "  #{order.shipping_city}, #{order.shipping_state} — #{order.shipping_postal_code}\n"
      response += "  #{order.shipping_country}\n"
      response += "  📞 #{order.shipping_phone_number}\n" if order.shipping_phone_number.present?
    end

    # Actionable next steps based on status
    response += "\n"
    case order.status
    when 'pending'
      response += "⚠️ Your order is pending. [Complete payment](/orders/#{order.id}/payment) to confirm."
    when 'confirmed'
      response += "✅ Your order is confirmed! We'll ship it soon. You'll get tracking updates via email."
    when 'shipped'
      response += "🚚 Your order is on the way! Check your email for tracking details."
    when 'delivered'
      response += "✅ Delivered! Need help? [Contact support](/contact)."
    when 'cancelled'
      response += "❌ This order was cancelled. Need help? [Contact support](/contact)."
    end

    response
  end

  def format_payment_summary(orders)
    response = "💳 Payment Summary:\n\n"

    orders.each_with_index do |order, i|
      payment_status = case order.payment_status
                       when 0 then '⏳ Unpaid'
                       when 1 then '✅ Paid'
                       when 2 then '💰 Refunded'
                       else '❓ Unknown'
                       end

      response += "#{i + 1}. Order ##{order.id} — ₹#{order.total_price.to_i} — #{payment_status}\n"

      if order.razorpay_order_id.present?
        response += "   Razorpay ID: `#{order.razorpay_order_id}`\n"
      end
    end

    unpaid = orders.select { |o| o.payment_status == 0 }
    if unpaid.any?
      response += "\n⚠️ You have #{unpaid.count} unpaid order#{'s' if unpaid.count != 1}. [Complete payment now](/orders)."
    end

    response
  end

  def format_shipping_summary(orders)
    response = "📍 Shipping & Delivery:\n\n"

    orders.each_with_index do |order, i|
      response += "**Order ##{order.id}** — #{order.status.titleize}\n"

      if order.shipping_full_name.present?
        response += "  To: #{order.shipping_full_name}\n"
        response += "  #{order.shipping_address_line_1}, #{order.shipping_city}\n"
        response += "  #{order.shipping_state} — #{order.shipping_postal_code}\n"
      else
        response += "  📦 Shipping address not set yet. Update in [order details](/orders/#{order.id}).\n"
      end

      case order.status
      when 'pending'
        response += "  ⏳ Awaiting payment confirmation before shipping.\n"
      when 'confirmed'
        response += "  📦 Preparing for shipment. Tracking will be shared soon.\n"
      when 'shipped'
        response += "  🚚 In transit! Check your email for tracking link.\n"
      when 'delivered'
        response += "  ✅ Delivered to your address.\n"
      end
      response += "\n"
    end

    response
  end

  def extract_order_id(prompt)
    # Extract order number from phrases like "order 123", "order #123", "123"
    match = prompt.match(/order\s*#?\s*(\d+)/i) || prompt.match(/\b(\d{3,})\b/)
    match ? match[1].to_i : nil
  end

  # ─── PRODUCT SEARCH ─────────────────────────────────────────────────

  def search_products(query)
    # Clean query for better search
    clean_query = query.downcase
                       .gsub(/(show|find|search|looking for|i want|i need|do you have|any|some|me|the|a|an)\s*/i, '')
                       .strip

    Product.active.search(clean_query).limit(5)
  rescue => e
    Rails.logger.error "Product search error: #{e.message}"
    []
  end

  def format_product_results(products)
    return "I couldn't find any products matching that description. Browse our [full collection](/products)." if products.empty?

    @last_product = products.first # Track last mentioned

    response = "I found these products for you:\n\n"
    products.each_with_index do |product, i|
      price = product.price.to_i
      response += "#{i + 1}. **#{product.name}** — ₹#{price}\n"
    end
    response += "\nSay \"add [product name] to cart\" to purchase, or click [View All Products](/products) for more!"
    response
  end

  # ─── CART OPERATIONS ────────────────────────────────────────────────

  # FIX: Accept quantity parameter, default to 1
  def add_product_to_cart(product, quantity: 1)
    return false unless cart
    return false unless product.in_stock?

    cart_item = cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = (cart_item.quantity || 0) + quantity
    cart_item.save!
    true
  rescue => e
    Rails.logger.error "Add to cart error: #{e.message}"
    false
  end

  # ─── QUANTITY PARSING ───────────────────────────────────────────────
  # FIX: New method to parse quantity from user prompts
  def parse_quantity(prompt)
    p = prompt.downcase.strip

    # Direct number words
    number_words = {
      'one' => 1, 'two' => 2, 'three' => 3, 'four' => 4, 'five' => 5,
      'six' => 6, 'seven' => 7, 'eight' => 8, 'nine' => 9, 'ten' => 10,
      'a' => 1, 'an' => 1, 'another' => 1, 'one more' => 1, 'another one' => 1
    }

    # Check for explicit digits first
    digit_match = p.match(/\b(add|buy|get|grab|order)?\s*(\d+)\b/)
    return digit_match[2].to_i if digit_match && digit_match[2].to_i > 0

    # Check for number words
    number_words.each do |word, qty|
      # Match as whole word or in phrases like "add two more"
      if p.match?(/\b#{Regexp.escape(word)}\b/)
        return qty
      end
    end

    # Check for "more" or "another" without explicit number → default to 1
    # but if preceded by a number word, it was already caught above
    if p.match?(/\b(more|another|extra)\b/)
      return 1
    end

    1 # Default
  end

  # ─── NAME EXTRACTION ────────────────────────────────────────────────

  def extract_product_name(prompt, context = :add)
    p = prompt.downcase.strip

    # FIX: If user refers to pronouns for bulk removal, return empty so caller handles contextually
    pronouns = %w[them it this that these those all everything]
    if context == :remove && pronouns.any? { |pr| p.include?(pr) }
      return ""  # Let handle_remove_from_cart deal with pronouns
    end

    # Remove common action phrases based on context
    stop_phrases = case context
                   when :add
                     [
                       'add ', 'put ', 'buy ', 'purchase ', 'get ', 'grab ', 'order ',
                       'to cart', 'in cart', 'to my cart', 'in my cart',
                       'to bag', 'in bag', 'to my bag', 'in my bag',
                       'to basket', 'in basket', 'to my basket', 'in my basket',
                       'into cart', 'into my cart', 'into bag', 'into my bag',
                       'please', 'can you', 'could you', 'would you',
                       'i want', 'i need', 'i would like', 'i wanna',
                       'this particular', 'yes', 'sure', 'okay', 'ok',
                       'the ', 'a ', 'an ', 'some ', 'that ', 'this ',
                       'another ', 'more ', 'extra ', 'of ', 'those ', 'these ',
                     ]
                   when :remove
                     [
                       'remove ', 'delete ', 'take out ', 'drop ',
                       'from cart', 'from my cart', 'from bag', 'from my bag',
                       'from basket', 'from my basket',
                       'please', 'can you', 'could you', 'would you',
                       'the ', 'a ', 'an ', 'that ', 'this ',
                     ]
                   when :details
                     [
                       'tell me about ', 'tell me more about ', 'more about ',
                       'details of ', 'details for ', 'details about ', 'details on ',
                       'info about ', 'info on ', 'information about ',
                       'describe ', 'what is ', 'what are ',
                       'how much is ', 'how much does ', 'how much for ',
                       'the ', 'a ', 'an ', 'this ', 'that ',
                       'please', 'can you', 'could you',
                     ]
                   else
                     []
                   end

    result = p
    stop_phrases.each { |phrase| result = result.gsub(phrase, ' ') }
    result = result.squeeze(' ').strip

    # Remove trailing punctuation
    result = result.gsub(/[?.!,]+$/, '').strip

    # FIX: Remove standalone numbers that remain after stripping phrases
    result = result.gsub(/^\d+\s*/, '').strip
    result = result.gsub(/\s+\d+$/, '').strip

    result.presence
  end

  # ─── CONTEXT TRACKING ───────────────────────────────────────────────

  def find_last_mentioned_product
    return @last_product if @last_product

    # FIX: Look at recent chat logs for this user only, limit to 3
    recent_logs = ChatLog.where(user: user).order(created_at: :desc).limit(3)

    # FIX: Extract product names from responses using a simpler regex
    recent_logs.each do |log|
      next unless log.response

      # Find the first bolded product name in recent response
      if log.response =~ /\*\*([^*]+)\*\*/
        name = $1.strip
        product = Product.active.find_by("LOWER(name) = ?", name.downcase)
        return product if product
      end
    end

    nil
  rescue => e
    Rails.logger.error "Find last product error: #{e.message}"
    nil
  end

  # ─── PAYMENT SYNC ─────────────────────────────────────────────────────
  # FIX: New method to sync payment status from Razorpay before displaying
  def sync_payment_status_from_razorpay
    return unless user

    user.orders.where(payment_status: 0).where.not(razorpay_order_id: nil).find_each do |order|
      begin
        # Check Razorpay API for actual payment status
        razorpay_order = fetch_razorpay_order(order.razorpay_order_id)

        if razorpay_order && razorpay_order['status'] == 'paid'
          order.update!(
            payment_status: 1,
            status: 'confirmed'
          )
          Rails.logger.info "Synced order ##{order.id} payment_status to paid via Razorpay"
        elsif razorpay_order && razorpay_order['status'] == 'attempted' && razorpay_order['amount_paid'].to_i > 0
          # Partial or failed payment attempt
          Rails.logger.warn "Order ##{order.id} has attempted payment but not fully paid"
        end
      rescue => e
        Rails.logger.error "Failed to sync Razorpay status for order ##{order.id}: #{e.message}"
      end
    end
  rescue => e
    Rails.logger.error "Payment sync error: #{e.message}"
  end

  # FIX: Helper to fetch Razorpay order status
  def fetch_razorpay_order(razorpay_order_id)
    return nil if razorpay_order_id.blank?
    return nil if ENV['RAZORPAY_KEY_ID'].blank? || ENV['RAZORPAY_KEY_SECRET'].blank?

    require 'base64'

    uri = URI("https://api.razorpay.com/v1/orders/#{razorpay_order_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri)
    auth = Base64.strict_encode64("#{ENV['RAZORPAY_KEY_ID']}:#{ENV['RAZORPAY_KEY_SECRET']}")
    request['Authorization'] = "Basic #{auth}"

    response = http.request(request)

    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    nil
  rescue => e
    Rails.logger.error "Razorpay fetch error: #{e.message}"
    nil
  end

  # ─── LLM PROVIDERS ─────────────────────────────────────────────────

  def call_groq(user_prompt)
    api_key = ENV['GROQ_API_KEY']
    model = ENV.fetch('GROQ_MODEL', 'llama-3.3-70b-versatile')

    full_context = build_llm_context  # ← USES THE NEW METHOD

    uri = URI('https://api.groq.com/openai/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: model,
      messages: [
        { role: 'system', content: full_context },
        { role: 'user', content: user_prompt }
      ],
      temperature: 0.3,  # ← LOWERED to reduce hallucination
      max_tokens: 500
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Groq returned #{response.code}: #{response.body}"
    end

    body = JSON.parse(response.body)
    content = body.dig('choices', 0, 'message', 'content')
    content || raise(Error, "Empty response from Groq")
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "Groq timeout: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Invalid response from Groq: #{e.message}"
  end

  def call_ollama(user_prompt)
    full_context = build_llm_context  # ← USES THE NEW METHOD

    uri = URI(ENV.fetch('OLLAMA_URL', 'http://localhost:11434/api/generate'))
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 30
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      model: ENV.fetch('OLLAMA_MODEL', 'llama3.2:1b'),
      prompt: "#{full_context}\n\nUser: #{user_prompt}\nAssistant:",
      stream: false
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Ollama returned #{response.code}"
    end

    body = JSON.parse(response.body)
    body['response'] || raise(Error, "No response from Ollama")
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    raise ConnectionError, "Cannot connect to Ollama: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Invalid response from Ollama: #{e.message}"
  end
end