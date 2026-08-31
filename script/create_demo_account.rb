# frozen_string_literal: true

# Run with:
#   bin/rails runner script/create_demo_account.rb

# The dates are relative to Date.current so a newly created demo account always
# opens on an active budget with a useful daily spending gauge.

email_address = "demo@spendout.local"

if User.exists?(email_address: email_address)
  puts "Demo account already exists: #{email_address}"
  exit
end

today = Date.current
created_at_for = ->(days_ago) { (today - days_ago.days).in_time_zone.change(hour: 12) }

User.transaction do
  user = User.create!(email_address: email_address)
  budget = user.budgets.create!(
    base_currency_code: "USD",
    period_from: today - 11.days,
    period_to: today + 18.days
  )

  civic_bank = budget.sources.create!(
    name: "Civic Bank",
    amount: 3_200,
    currency_code: "USD",
    rate: 1,
    design: :mastercat
  )
  street_cash = budget.sources.create!(
    name: "Street cash",
    amount: 280,
    currency_code: "USD",
    rate: 1,
    design: :unipaw
  )

  exchange = civic_bank.outgoing_exchanges.new(
    budget: budget,
    receiver_source_name: "Europe wallet",
    receiver_currency_code: "EUR",
    sender_amount: 600,
    rate: BigDecimal("0.85")
  )
  exchange.save_with_receiver_source || raise(exchange.errors.full_messages.to_sentence)
  exchange.update_column(:created_at, created_at_for.call(6))
  europe_wallet = exchange.receiver_source
  europe_wallet.update!(design: :meowisa)

  allocations = {
    rent: budget.allocations.create!(name: "Rent", amount: 1_200, currency_code: "USD", rate: 1, icon: "home", colour: "violet"),
    groceries: budget.allocations.create!(name: "Groceries", amount: 450, currency_code: "USD", rate: 1, icon: "shopping-cart", colour: "green"),
    utilities: budget.allocations.create!(name: "Utilities", amount: 180, currency_code: "USD", rate: 1, icon: "bulb", colour: "yellow"),
    transport: budget.allocations.create!(name: "Transport", amount: 160, currency_code: "USD", rate: 1, icon: "bus", colour: "cyan"),
    europe_trip: budget.allocations.create!(name: "Europe trip", amount: 300, currency_code: "EUR", rate: BigDecimal("0.85"), icon: "plane", colour: "blue"),
    subscriptions: budget.allocations.create!(name: "Subscriptions", amount: 50, currency_code: "USD", rate: 1, icon: "repeat", colour: "pink"),
    home_repair: budget.allocations.create!(name: "Home repair", amount: 300, currency_code: "USD", rate: 1, icon: "tools", colour: "orange"),
    emergency: budget.allocations.create!(name: "Emergency cushion", amount: 250, currency_code: "USD", rate: 1, icon: "shield-check", colour: "teal"),
    eating_out: budget.allocations.create!(name: "Eating out", amount: 0, planned: false, currency_code: "USD", rate: 1, icon: "burger", colour: "coral"),
    coffee: budget.allocations.create!(name: "Coffee", amount: 0, planned: false, currency_code: "USD", rate: 1, icon: "coffee", colour: "orange"),
    entertainment: budget.allocations.create!(name: "Entertainment", amount: 0, planned: false, currency_code: "USD", rate: 1, icon: "movie", colour: "indigo"),
    shopping: budget.allocations.create!(name: "Shopping", amount: 0, planned: false, currency_code: "USD", rate: 1, icon: "shirt", colour: "pink"),
    pets: budget.allocations.create!(name: "Pets", amount: 0, planned: false, currency_code: "USD", rate: 1, icon: "paw", colour: "orange")
  }

  add_expense = lambda do |days_ago:, amount:, source:, allocation: nil, note: nil, currency: nil, conversion_rate: nil|
    expense = budget.expenses.new(
      amount: amount,
      source: source,
      allocation: allocation,
      note: note,
      currency_code: currency || source.currency_code,
      conversion_rate: conversion_rate || 1,
      occurred_on: today - days_ago.days
    )
    expense.save_with_source_capacity || raise(expense.errors.full_messages.to_sentence)
    expense.update_column(:created_at, created_at_for.call(days_ago))
    expense
  end

  add_expense.call(days_ago: 10, amount: 1_200, source: civic_bank, allocation: allocations[:rent], note: "Unit 8B — elevator still distrusts me")
  add_expense.call(days_ago: 9, amount: BigDecimal("126.40"), source: civic_bank, allocation: allocations[:groceries], note: "Real vegetables this time")
  add_expense.call(days_ago: 8, amount: 42, source: street_cash, allocation: allocations[:transport], note: "Human-operated line")
  add_expense.call(days_ago: 8, amount: BigDecimal("5.80"), source: street_cash, allocation: allocations[:coffee], note: "Extra shot, no firmware")
  add_expense.call(days_ago: 7, amount: BigDecimal("74.25"), source: civic_bank, allocation: allocations[:utilities], note: "Neon is apparently not free")
  add_expense.call(days_ago: 6, amount: BigDecimal("48.60"), source: civic_bank, allocation: allocations[:eating_out], note: "Noodles under the hologram ads")
  add_expense.call(days_ago: 5, amount: 120, source: civic_bank, allocation: allocations[:home_repair], note: "Kitchen tap won the first round")
  allocations[:home_repair].update_column(:finished_at, created_at_for.call(5).end_of_day)
  add_expense.call(days_ago: 4, amount: BigDecimal("158.75"), source: civic_bank, allocation: allocations[:groceries], note: "Pantry restock")
  add_expense.call(days_ago: 3, amount: 50, source: civic_bank, allocation: allocations[:subscriptions], note: "Four services, nothing to watch")
  add_expense.call(days_ago: 3, amount: 31, source: civic_bank, allocation: allocations[:entertainment], note: "Ancient technology: a cinema screen")
  add_expense.call(days_ago: 2, amount: BigDecimal("24.90"), source: civic_bank, note: "Pharmacist was definitely human")
  add_expense.call(days_ago: 2, amount: BigDecimal("12.50"), source: street_cash, allocation: allocations[:groceries])
  add_expense.call(days_ago: 1, amount: 58, source: civic_bank, allocation: allocations[:shopping], note: "Jacket has only one charging port")

  night_market_cash = budget.sources.create!(
    name: "Night market cash",
    amount: 100,
    currency_code: "USD",
    rate: 1,
    design: :americat_express
  )
  questionable_food = budget.allocations.create!(
    name: "Questionable street food",
    amount: 0,
    planned: false,
    currency_code: "USD",
    rate: 1,
    icon: "burger",
    colour: "violet"
  )
  add_expense.call(days_ago: 1, amount: 18, source: night_market_cash, allocation: questionable_food, note: "Vendor accepted cash and plausible deniability")
  night_market_cash.update_column(:deleted_at, created_at_for.call(1).end_of_day)
  questionable_food.update_column(:deleted_at, created_at_for.call(1).end_of_day)

  add_expense.call(days_ago: 0, amount: BigDecimal("171.20"), source: civic_bank, allocation: allocations[:groceries], note: "Emergency snack reserves replenished")
  add_expense.call(days_ago: 0, amount: BigDecimal("8.40"), source: street_cash, allocation: allocations[:coffee], note: "Worked here until the drone noticed")
  add_expense.call(days_ago: 0, amount: 46, source: street_cash, allocation: allocations[:transport], note: "Airport train, minimal surveillance")
  add_expense.call(days_ago: 0, amount: 24, source: europe_wallet, allocation: allocations[:europe_trip], note: "Ancient technology: paintings")
  add_expense.call(days_ago: 0, amount: 90, source: europe_wallet, allocation: allocations[:europe_trip], note: "Their concierge has a face")
  add_expense.call(days_ago: 0, amount: 15, source: civic_bank, allocation: allocations[:europe_trip], currency: "EUR", conversion_rate: BigDecimal("0.85"), note: "Offline copy, just in case")
  add_expense.call(days_ago: 0, amount: BigDecimal("14.80"), source: civic_bank, allocation: allocations[:pets], note: "I do not own a cat")

  puts <<~SUMMARY
    Created #{email_address}
    Budget: #{budget.date_period} (#{budget.base_currency_code})
    Sources: #{budget.sources.count} total, #{budget.sources.where(deleted_at: nil).count} active
    Allocations: #{budget.allocations.count} total, #{budget.allocations.planned.count} planned
    Expenses: #{budget.expenses.count}
    Today's safe-to-spend amount: #{budget.todays_remainder.to_s("F")} #{budget.base_currency_code}
  SUMMARY
end
