# frozen_string_literal: true

# Run with:
#   bin/rails runner script/create_demo_account.rb

# The dates are relative to Date.current so a newly created test account always
# opens on an active budget with useful data across the product.
#
# Override the fake login address with:
#   FAKE_EMAIL=someone@example.test bin/rails runner script/create_demo_account.rb

email_address = ENV.fetch("FAKE_EMAIL", "test@spendout.local")

if User.exists?(email_address: email_address)
  AuthCode.where(email_address: email_address).delete_all
  auth_code = AuthCode.create!(email_address: email_address)
  puts "Test account already exists: #{email_address}"
  puts "Fresh one-time code: #{auth_code.code} (expires in #{AuthCode::EXPIRATION_TIME.in_minutes.to_i} minutes)"
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

  category_attributes = {
    rent: [ "Rent", "home", "violet" ], groceries: [ "Groceries", "shopping-cart", "green" ],
    utilities: [ "Utilities", "bulb", "yellow" ], transport: [ "Transport", "bus", "cyan" ],
    europe_trip: [ "Europe trip", "plane", "blue" ], subscriptions: [ "Subscriptions", "repeat", "pink" ],
    home_repair: [ "Home repair", "tools", "orange" ], emergency: [ "Emergency cushion", "shield-check", "teal" ],
    eating_out: [ "Eating out", "burger", "coral" ], coffee: [ "Coffee", "coffee", "orange" ],
    entertainment: [ "Entertainment", "movie", "indigo" ], shopping: [ "Shopping", "shirt", "pink" ],
    pets: [ "Pets", "paw", "orange" ]
  }
  categories = category_attributes.transform_values do |name, icon, colour|
    budget.categories.create!(name:, icon:, colour:)
  end
  allocation_attributes = {
    rent: [ 1_200, "USD", 1 ], groceries: [ 450, "USD", 1 ], utilities: [ 180, "USD", 1 ],
    transport: [ 160, "USD", 1 ], europe_trip: [ 300, "EUR", BigDecimal("0.85") ],
    subscriptions: [ 50, "USD", 1 ], home_repair: [ 300, "USD", 1 ], emergency: [ 250, "USD", 1 ]
  }
  allocations = allocation_attributes.to_h do |key, (amount, currency_code, rate)|
    [ key, budget.allocations.create!(category: categories.fetch(key), amount:, currency_code:, rate:) ]
  end

  add_expense = lambda do |days_ago:, amount:, source:, category:, note: nil, currency: nil, conversion_rate: nil|
    expense = budget.expenses.new(
      amount: amount,
      source: source,
      category: category,
      note: note,
      currency_code: currency || source.currency_code,
      conversion_rate: conversion_rate || 1,
      occurred_on: today - days_ago.days
    )
    expense.save_with_source_capacity || raise(expense.errors.full_messages.to_sentence)
    expense.update_column(:created_at, created_at_for.call(days_ago))
    expense
  end

  add_expense.call(days_ago: 10, amount: 1_200, source: civic_bank, category: categories[:rent], note: "Unit 8B — elevator still distrusts me")
  add_expense.call(days_ago: 9, amount: BigDecimal("126.40"), source: civic_bank, category: categories[:groceries], note: "Real vegetables this time")
  add_expense.call(days_ago: 8, amount: 42, source: street_cash, category: categories[:transport], note: "Human-operated line")
  add_expense.call(days_ago: 8, amount: BigDecimal("5.80"), source: street_cash, category: categories[:coffee], note: "Extra shot, no firmware")
  add_expense.call(days_ago: 7, amount: BigDecimal("74.25"), source: civic_bank, category: categories[:utilities], note: "Neon is apparently not free")
  add_expense.call(days_ago: 6, amount: BigDecimal("48.60"), source: civic_bank, category: categories[:eating_out], note: "Noodles under the hologram ads")
  add_expense.call(days_ago: 5, amount: 120, source: civic_bank, category: categories[:home_repair], note: "Kitchen tap won the first round")
  allocations[:home_repair].update_column(:finished_at, created_at_for.call(5).end_of_day)
  add_expense.call(days_ago: 4, amount: BigDecimal("158.75"), source: civic_bank, category: categories[:groceries], note: "Pantry restock")
  add_expense.call(days_ago: 3, amount: 50, source: civic_bank, category: categories[:subscriptions], note: "Four services, nothing to watch")
  add_expense.call(days_ago: 3, amount: 31, source: civic_bank, category: categories[:entertainment], note: "Ancient technology: a cinema screen")
  add_expense.call(days_ago: 2, amount: BigDecimal("24.90"), source: civic_bank, category: categories[:emergency], note: "Pharmacist was definitely human")
  add_expense.call(days_ago: 2, amount: BigDecimal("12.50"), source: street_cash, category: categories[:groceries])
  add_expense.call(days_ago: 1, amount: 58, source: civic_bank, category: categories[:shopping], note: "Jacket has only one charging port")

  night_market_cash = budget.sources.create!(
    name: "Night market cash",
    amount: 100,
    currency_code: "USD",
    rate: 1,
    design: :americat_express
  )
  questionable_food = budget.categories.create!(
    name: "Questionable street food",
    icon: "burger",
    colour: "violet"
  )
  add_expense.call(days_ago: 1, amount: 18, source: night_market_cash, category: questionable_food, note: "Vendor accepted cash and plausible deniability")
  night_market_cash.update_column(:deleted_at, created_at_for.call(1).end_of_day)
  questionable_food.update_column(:deleted_at, created_at_for.call(1).end_of_day)

  add_expense.call(days_ago: 0, amount: BigDecimal("171.20"), source: civic_bank, category: categories[:groceries], note: "Emergency snack reserves replenished")
  add_expense.call(days_ago: 0, amount: BigDecimal("8.40"), source: street_cash, category: categories[:coffee], note: "Worked here until the drone noticed")
  add_expense.call(days_ago: 0, amount: 46, source: street_cash, category: categories[:transport], note: "Airport train, minimal surveillance")
  add_expense.call(days_ago: 0, amount: 24, source: europe_wallet, category: categories[:europe_trip], note: "Ancient technology: paintings")
  add_expense.call(days_ago: 0, amount: 90, source: europe_wallet, category: categories[:europe_trip], note: "Their concierge has a face")
  add_expense.call(days_ago: 0, amount: 15, source: civic_bank, category: categories[:europe_trip], currency: "EUR", conversion_rate: BigDecimal("0.85"), note: "Offline copy, just in case")
  add_expense.call(days_ago: 0, amount: BigDecimal("14.80"), source: civic_bank, category: categories[:pets], note: "I do not own a cat")

  income = budget.incomes.create!(source: civic_bank, source_name: civic_bank.name, amount: 900,
    currency_code: "USD", conversion_rate: 1, occurred_on: today - 7.days, note: "Freelance payment")
  income.update_column(:created_at, created_at_for.call(7))
  budget.recurrences.create!(category: categories[:subscriptions], name: "Streaming bundle", amount: 50,
    currency_code: "USD", occurs_on: today + 4.days, occurrence_period_in_days: 30, note: "Monthly renewal")

  [ UpcomingRecurrences.new, MostExpensiveCategories.new(starts_on: budget.period_from) ].each.with_index(2) do |lensable, position|
    budget.lenses.create!(lensable:, position:)
  end

  auth_code = AuthCode.create!(email_address:)

  puts <<~SUMMARY
    Created #{email_address}
    One-time code: #{auth_code.code} (expires in #{AuthCode::EXPIRATION_TIME.in_minutes.to_i} minutes)
    Budget: #{budget.date_period} (#{budget.base_currency_code})
    Sources: #{budget.sources.count} total, #{budget.sources.where(deleted_at: nil).count} active
    Categories: #{budget.categories.count} total, #{budget.categories.active.count} active
    Allocations: #{budget.allocations.count} total, #{budget.allocations.active.count} active
    Expenses: #{budget.expenses.count}
    Today's safe-to-spend amount: #{budget.todays_remainder.to_s("F")} #{budget.base_currency_code}
  SUMMARY
end
