class HomeController < ApplicationController
  TOUR_FEATURES = {
    "keyboard-friendly" => {
      colour: "blue", label: "Keyboard friendly", title: "Keep your hands on the keys.",
      lead: "Jump between money, plans, and expenses, then move through focused forms without reaching for the pointer.",
      detail_title: "Shortcuts stay visible", detail: "The interface shows the available keys where they matter, including Enter to advance, Shift + Enter to go back, and section shortcuts in the tab bar.",
      image: "tour-expense-form.png", alt: "Spendout expense form showing its keyboard prompts"
    },
    "currency-suggested" => {
      colour: "yellow", label: "Currency suggested", title: "A useful default, never a silent choice.",
      lead: "Spendout brings a likely currency forward while leaving the final selection in your hands.",
      detail_title: "Context helps; you decide", detail: "The budget base currency remains fixed after creation, and every currency-bearing record makes its selected currency visible before saving.",
      image: "tour-currency-open.png", alt: "Spendout allocation form with the Currency field expanded and USD selected"
    },
    "easy-to-correct" => {
      colour: "green", label: "Easy to correct", title: "Correct the record without rewriting history.",
      lead: "When an expense is wrong, delete it and recreate the corrected record through the same quick form.",
      detail_title: "Fresh facts get fresh snapshots", detail: "Purchase amount, source debit, quote, note, and occurrence date are saved together, so a correction cannot silently mutate an earlier monetary snapshot.",
      image: "tour-expense-form.png", alt: "Spendout form used to recreate a corrected expense"
    },
    "honest-history" => {
      colour: "orange", label: "History stays honest", title: "Clean up today without erasing yesterday.",
      lead: "Removed sources and categories stay attached to the expenses that used them and are clearly marked as deleted.",
      detail_title: "Relationships survive cleanup", detail: "Past expenses remain understandable even after the current budget no longer needs an old wallet, card, plan, or category.",
      image: "tour-sources.png", alt: "Spendout sources screen where current money sources are managed"
    },
    "categorize-spending" => {
      colour: "pink", label: "Categorize spending", title: "Plan what matters. Classify everything else.",
      lead: "Use planned allocations to reserve money or unplanned categories to organize spending from the general remainder.",
      detail_title: "A plan never blocks reality", detail: "Plans may warn when they exceed available funds, but expenses still go through. Finishing a plan releases its unspent reservation while keeping its history.",
      image: "tour-expense-category-open.png", alt: "Spendout expense form with Category expanded and a new Groceries category entered"
    },
    "styled-categories" => {
      colour: "blue", label: "Categories style themselves", title: "Name it. Spendout gives it a look.",
      lead: "A category name produces a fitting icon and colour suggestion, ready to accept or replace.",
      detail_title: "Automatic, not restrictive", detail: "The suggestion speeds up routine setup while the full icon and colour controls remain available whenever you want something different.",
      image: "tour-category-style-open.png", alt: "Spendout category form with the Colour palette expanded"
    },
    "confirm-rates" => {
      colour: "yellow", label: "Confirm every rate", title: "Reference rates suggest. You confirm.",
      lead: "Enter a direct quote yourself or review a dated external suggestion before any currency-bearing record is saved.",
      detail_title: "Quotes read in one direction", detail: "Spendout consistently expresses the quote as selected-currency units per one base-currency unit and never silently updates historical values.",
      image: "tour-rate-confirm-open.png", alt: "Spendout conversion-rate dialog open with a confirmed EUR per USD quote"
    },
    "source-exchanges" => {
      colour: "green", label: "Exchange between sources", title: "Move money without losing either side.",
      lead: "Debit one source and create its receiving source together, whether the currencies differ or happen to match.",
      detail_title: "One atomic exchange", detail: "Both amounts and the sender-relative quote are preserved as a connected event, so the movement remains clear in source history.",
      image: "tour-exchange-amount-open.png", alt: "Spendout exchange form with the sender amount field expanded"
    },
    "expense-notes" => {
      colour: "orange", label: "Add useful context", title: "Leave yourself the detail that matters.",
      lead: "Attach an optional short note and occurrence date when an amount and category do not tell the whole story.",
      detail_title: "Present when useful, quiet otherwise", detail: "Notes are capped at 200 characters and remain part of the expense snapshot without making every quick entry feel heavy.",
      image: "tour-expense-note-open.png", alt: "Spendout expense form with the Note field expanded and populated"
    }
  }.freeze

  TOUR_PAGES = [ "welcome", *TOUR_FEATURES.keys, "finish" ].freeze

  allow_unauthenticated_access only: %i[ show tour ]

  def show
  end

  def tour
    @tour_page = params[:feature].presence || TOUR_PAGES.first
    position = TOUR_PAGES.index(@tour_page)
    @tour_previous = TOUR_PAGES[position - 1] if position.positive?
    @tour_next = TOUR_PAGES[position + 1]
    @tour_feature = TOUR_FEATURES[@tour_page]
    @tour_count = format("%02d / %02d", position, TOUR_FEATURES.size) if @tour_feature
  end
end
