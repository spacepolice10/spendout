class LensFacade
  Entry = Data.define(:name, :lensable_type, :icon)

  ENTRIES = [
    Entry.new(name: "rollover", lensable_type: "Rollover", icon: "repeat"),
    Entry.new(name: "most_expensive_categories", lensable_type: "MostExpensiveCategories", icon: "chart-bar"),
    Entry.new(name: "upcoming_recurrences", lensable_type: "UpcomingRecurrences", icon: "heartbeat"),
    Entry.new(name: "rate_info", lensable_type: "RateInfo", icon: "currency-dollar")
  ].freeze

  BUILTIN_ICONS = {
    "source_holder" => "wallet",
    "plan_overview" => "category"
  }.freeze

  def initialize(budget)
    @budget = budget
  end

  def ordered
    budget.lenses.positioned
  end

  def active?(name)
    active_lensable_types.include?(entry_for(name).lensable_type)
  end
  alias_method :enabled?, :active?

  def available?(name)
    !active?(name)
  end

  def active_entries
    ENTRIES.select { |entry| active?(entry.name) }
  end

  def available_entries
    ENTRIES.reject { |entry| active?(entry.name) }
  end

  def icon_for(name)
    BUILTIN_ICONS[name.to_s] || entry_for(name).icon
  end

  private
    attr_reader :budget

    def active_lensable_types
      @active_lensable_types ||= budget.lenses.distinct.pluck(:lensable_type).to_set
    end

    def entry_for(name)
      ENTRIES.find { |entry| entry.name == name.to_s } || raise(ArgumentError, "Unknown lens: #{name}")
    end
end
