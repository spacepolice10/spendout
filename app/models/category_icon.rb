# frozen_string_literal: true

class CategoryIcon
  DEFAULT_ICON = Iconable::DEFAULT_ICON
  DEFAULT_COLOUR = Colourable::DEFAULT_COLOUR
  MAX_DISTANCE = 1

  KEYWORDS = {
    "burger" => %w[burger burgers dining dinner fastfood food lunch restaurant restaurants takeaway],
    "coffee" => %w[cafe caffeine coffee coffeeshop],
    "shopping-cart" => %w[groceries grocery market shopping supermarket],
    "car" => %w[car fuel gas grab parking petrol taxi transport transportation uber],
    "home" => %w[apartment home housing mortgage rent],
    "bulb" => %w[electric electricity internet phonebill utilities utility water],
    "heartbeat" => %w[clinic dentist doctor health healthcare hospital medical medicine pharmacy],
    "movie" => %w[amazonprime cinema crunchyroll disney disneyplus entertainment gaming hbo hbomax hulu movie movies paramount paramountplus peacock primevideo streaming],
    "school" => %w[books course education school study tuition],
    "shirt" => %w[clothes clothing fashion shoes],
    "barbell" => %w[fitness gym sport sports workout],
    "plane" => %w[flight flights holiday hotel travel trip vacation],
    "gift" => %w[birthday charity donation gift gifts],
    "briefcase" => %w[business office salary work],
    "pig-money" => %w[emergency investment investments saving savings],
    "credit-card" => %w[card credit debt loan],
    "flower" => %w[bouquet bouquets florist flower flowers floral],
    "diamond" => %w[diamond diamonds jewel jewelry jewellery necklace ring rings],
    "paw" => %w[animal animals cat cats dog dogs pet pets veterinarian veterinary vet],
    "sparkles" => %w[barber beauty cosmetics haircut hairdresser makeup manicure salon skincare spa],
    "baby-carriage" => %w[baby babysitter babysitting childcare children daycare family kids nursery],
    "shield-check" => %w[coverage insurance premium premiums protection],
    "receipt-dollar" => %w[duty incometax levy tax taxes taxation],
    "tools" => %w[fix maintenance mechanic renovation repair repairs service servicing],
    "bus" => %w[bus buses metro publictransport subway train tram transit],
    "repeat" => %w[membership memberships recurring subscription subscriptions],
    "glass" => %w[alcohol bar beer cocktail cocktails drinks nightlife pub wine],
    "device-laptop" => %w[computer device electronics gadget gadgets laptop software technology],
    "device-mobile" => %w[cellphone data mobile mobilephone phone phoneplan prepaid sim],
    "spray" => %w[cleaner cleaning household housewares supplies toiletries],
    "brand-youtube" => %w[youtube youtubemusic youtubepremium],
    "brand-spotify" => %w[spotify spotifypremium],
    "brand-netflix" => %w[netflix],
    "headphones" => %w[applemusic deezer pandora soundcloud tidal]
  }.transform_values { |keywords| keywords.map(&:freeze).freeze }.freeze

  COLOURS = {
    "burger" => "orange",
    "coffee" => "coral",
    "shopping-cart" => "green",
    "car" => "yellow",
    "home" => "teal",
    "bulb" => "yellow",
    "heartbeat" => "red",
    "movie" => "violet",
    "school" => "indigo",
    "shirt" => "violet",
    "barbell" => "red",
    "plane" => "cyan",
    "gift" => "pink",
    "briefcase" => "teal",
    "pig-money" => "green",
    "credit-card" => "violet",
    "flower" => "pink",
    "diamond" => "cyan",
    "paw" => "orange",
    "sparkles" => "pink",
    "baby-carriage" => "pink",
    "shield-check" => "teal",
    "receipt-dollar" => "red",
    "tools" => "yellow",
    "bus" => "cyan",
    "repeat" => "indigo",
    "glass" => "violet",
    "device-laptop" => "indigo",
    "device-mobile" => "cyan",
    "spray" => "green",
    "brand-youtube" => "red",
    "brand-spotify" => "lime",
    "brand-netflix" => "red",
    "headphones" => "coral"
  }.freeze

  def self.match(name) = new(name).match
  def self.colour(name) = new(name).colour

  def initialize(name)
    @words = normalize(name).split.freeze
    @joined_name = @words.join
  end

  def match
    @match ||= exact_match || fuzzy_match || DEFAULT_ICON
  end

  def colour
    COLOURS.fetch(match, DEFAULT_COLOUR)
  end

  private
    attr_reader :words, :joined_name

    def candidates
      @candidates ||= (words + [ joined_name ]).uniq
    end

    def exact_match
      joined_match = KEYWORDS.find { |_icon, keywords| keywords.include?(joined_name) }
      return joined_match.first if joined_match

      KEYWORDS.filter_map do |icon, keywords|
        matched_keyword = keywords.select { |keyword| words.include?(keyword) }.max_by(&:length)
        [ matched_keyword.length, icon ] if matched_keyword
      end.max_by(&:first)&.last
    end

    def fuzzy_match
      KEYWORDS.each do |icon, keywords|
        return icon if keywords.any? { |keyword| fuzzy_keyword_match?(keyword) }
      end
      nil
    end

    def fuzzy_keyword_match?(keyword)
      candidates.any? do |candidate|
        candidate.length >= 4 && keyword.length >= 4 &&
          (candidate.length - keyword.length).abs <= MAX_DISTANCE &&
          levenshtein_distance(candidate, keyword) <= MAX_DISTANCE
      end
    end

    def normalize(value)
      value.to_s.unicode_normalize(:nfkd).downcase.gsub(/[^a-z0-9]+/, " ").strip
    end

    def levenshtein_distance(left, right)
      previous = (0..right.length).to_a

      left.each_char.with_index(1) do |left_character, row|
        current = [ row ]
        right.each_char.with_index(1) do |right_character, column|
          current[column] = [
            current[column - 1] + 1,
            previous[column] + 1,
            previous[column - 1] + (left_character == right_character ? 0 : 1)
          ].min
        end
        previous = current
      end

      previous.last
    end
end
