class Currency < ApplicationRecord
  # ISO 4217 List One, published 2026-01-01 by SIX, with English symbols from Unicode CLDR.
  CATALOG = {
  "AED" => { name: "UAE Dirham", numeric_code: "784", symbol: "AED" }.freeze,
  "AFN" => { name: "Afghani", numeric_code: "971", symbol: "AFN" }.freeze,
  "ALL" => { name: "Lek", numeric_code: "008", symbol: "ALL" }.freeze,
  "AMD" => { name: "Armenian Dram", numeric_code: "051", symbol: "AMD" }.freeze,
  "AOA" => { name: "Kwanza", numeric_code: "973", symbol: "AOA" }.freeze,
  "ARS" => { name: "Argentine Peso", numeric_code: "032", symbol: "ARS" }.freeze,
  "AUD" => { name: "Australian Dollar", numeric_code: "036", symbol: "A$" }.freeze,
  "AWG" => { name: "Aruban Florin", numeric_code: "533", symbol: "AWG" }.freeze,
  "AZN" => { name: "Azerbaijan Manat", numeric_code: "944", symbol: "AZN" }.freeze,
  "BAM" => { name: "Convertible Mark", numeric_code: "977", symbol: "BAM" }.freeze,
  "BBD" => { name: "Barbados Dollar", numeric_code: "052", symbol: "BBD" }.freeze,
  "BDT" => { name: "Taka", numeric_code: "050", symbol: "BDT" }.freeze,
  "BHD" => { name: "Bahraini Dinar", numeric_code: "048", symbol: "BHD" }.freeze,
  "BIF" => { name: "Burundi Franc", numeric_code: "108", symbol: "BIF" }.freeze,
  "BMD" => { name: "Bermudian Dollar", numeric_code: "060", symbol: "BMD" }.freeze,
  "BND" => { name: "Brunei Dollar", numeric_code: "096", symbol: "BND" }.freeze,
  "BOB" => { name: "Boliviano", numeric_code: "068", symbol: "BOB" }.freeze,
  "BOV" => { name: "Mvdol", numeric_code: "984", symbol: "BOV" }.freeze,
  "BRL" => { name: "Brazilian Real", numeric_code: "986", symbol: "R$" }.freeze,
  "BSD" => { name: "Bahamian Dollar", numeric_code: "044", symbol: "BSD" }.freeze,
  "BTN" => { name: "Ngultrum", numeric_code: "064", symbol: "BTN" }.freeze,
  "BWP" => { name: "Pula", numeric_code: "072", symbol: "BWP" }.freeze,
  "BYN" => { name: "Belarusian Ruble", numeric_code: "933", symbol: "BYN" }.freeze,
  "BZD" => { name: "Belize Dollar", numeric_code: "084", symbol: "BZD" }.freeze,
  "CAD" => { name: "Canadian Dollar", numeric_code: "124", symbol: "CA$" }.freeze,
  "CDF" => { name: "Congolese Franc", numeric_code: "976", symbol: "CDF" }.freeze,
  "CHE" => { name: "WIR Euro", numeric_code: "947", symbol: "CHE" }.freeze,
  "CHF" => { name: "Swiss Franc", numeric_code: "756", symbol: "CHF" }.freeze,
  "CHW" => { name: "WIR Franc", numeric_code: "948", symbol: "CHW" }.freeze,
  "CLF" => { name: "Unidad de Fomento", numeric_code: "990", symbol: "CLF" }.freeze,
  "CLP" => { name: "Chilean Peso", numeric_code: "152", symbol: "CLP" }.freeze,
  "CNY" => { name: "Yuan Renminbi", numeric_code: "156", symbol: "CN¥" }.freeze,
  "COP" => { name: "Colombian Peso", numeric_code: "170", symbol: "COP" }.freeze,
  "COU" => { name: "Unidad de Valor Real", numeric_code: "970", symbol: "COU" }.freeze,
  "CRC" => { name: "Costa Rican Colon", numeric_code: "188", symbol: "CRC" }.freeze,
  "CUP" => { name: "Cuban Peso", numeric_code: "192", symbol: "CUP" }.freeze,
  "CVE" => { name: "Cabo Verde Escudo", numeric_code: "132", symbol: "CVE" }.freeze,
  "CZK" => { name: "Czech Koruna", numeric_code: "203", symbol: "CZK" }.freeze,
  "DJF" => { name: "Djibouti Franc", numeric_code: "262", symbol: "DJF" }.freeze,
  "DKK" => { name: "Danish Krone", numeric_code: "208", symbol: "DKK" }.freeze,
  "DOP" => { name: "Dominican Peso", numeric_code: "214", symbol: "DOP" }.freeze,
  "DZD" => { name: "Algerian Dinar", numeric_code: "012", symbol: "DZD" }.freeze,
  "EGP" => { name: "Egyptian Pound", numeric_code: "818", symbol: "EGP" }.freeze,
  "ERN" => { name: "Nakfa", numeric_code: "232", symbol: "ERN" }.freeze,
  "ETB" => { name: "Ethiopian Birr", numeric_code: "230", symbol: "ETB" }.freeze,
  "EUR" => { name: "Euro", numeric_code: "978", symbol: "€" }.freeze,
  "FJD" => { name: "Fiji Dollar", numeric_code: "242", symbol: "FJD" }.freeze,
  "FKP" => { name: "Falkland Islands Pound", numeric_code: "238", symbol: "FKP" }.freeze,
  "GBP" => { name: "Pound Sterling", numeric_code: "826", symbol: "£" }.freeze,
  "GEL" => { name: "Lari", numeric_code: "981", symbol: "GEL" }.freeze,
  "GHS" => { name: "Ghana Cedi", numeric_code: "936", symbol: "GHS" }.freeze,
  "GIP" => { name: "Gibraltar Pound", numeric_code: "292", symbol: "GIP" }.freeze,
  "GMD" => { name: "Dalasi", numeric_code: "270", symbol: "GMD" }.freeze,
  "GNF" => { name: "Guinean Franc", numeric_code: "324", symbol: "GNF" }.freeze,
  "GTQ" => { name: "Quetzal", numeric_code: "320", symbol: "GTQ" }.freeze,
  "GYD" => { name: "Guyana Dollar", numeric_code: "328", symbol: "GYD" }.freeze,
  "HKD" => { name: "Hong Kong Dollar", numeric_code: "344", symbol: "HK$" }.freeze,
  "HNL" => { name: "Lempira", numeric_code: "340", symbol: "HNL" }.freeze,
  "HTG" => { name: "Gourde", numeric_code: "332", symbol: "HTG" }.freeze,
  "HUF" => { name: "Forint", numeric_code: "348", symbol: "HUF" }.freeze,
  "IDR" => { name: "Rupiah", numeric_code: "360", symbol: "IDR" }.freeze,
  "ILS" => { name: "New Israeli Sheqel", numeric_code: "376", symbol: "₪" }.freeze,
  "INR" => { name: "Indian Rupee", numeric_code: "356", symbol: "₹" }.freeze,
  "IQD" => { name: "Iraqi Dinar", numeric_code: "368", symbol: "IQD" }.freeze,
  "IRR" => { name: "Iranian Rial", numeric_code: "364", symbol: "IRR" }.freeze,
  "ISK" => { name: "Iceland Krona", numeric_code: "352", symbol: "ISK" }.freeze,
  "JMD" => { name: "Jamaican Dollar", numeric_code: "388", symbol: "JMD" }.freeze,
  "JOD" => { name: "Jordanian Dinar", numeric_code: "400", symbol: "JOD" }.freeze,
  "JPY" => { name: "Yen", numeric_code: "392", symbol: "¥" }.freeze,
  "KES" => { name: "Kenyan Shilling", numeric_code: "404", symbol: "KES" }.freeze,
  "KGS" => { name: "Som", numeric_code: "417", symbol: "KGS" }.freeze,
  "KHR" => { name: "Riel", numeric_code: "116", symbol: "KHR" }.freeze,
  "KMF" => { name: "Comorian Franc", numeric_code: "174", symbol: "KMF" }.freeze,
  "KPW" => { name: "North Korean Won", numeric_code: "408", symbol: "KPW" }.freeze,
  "KRW" => { name: "Won", numeric_code: "410", symbol: "₩" }.freeze,
  "KWD" => { name: "Kuwaiti Dinar", numeric_code: "414", symbol: "KWD" }.freeze,
  "KYD" => { name: "Cayman Islands Dollar", numeric_code: "136", symbol: "KYD" }.freeze,
  "KZT" => { name: "Tenge", numeric_code: "398", symbol: "KZT" }.freeze,
  "LAK" => { name: "Lao Kip", numeric_code: "418", symbol: "LAK" }.freeze,
  "LBP" => { name: "Lebanese Pound", numeric_code: "422", symbol: "LBP" }.freeze,
  "LKR" => { name: "Sri Lanka Rupee", numeric_code: "144", symbol: "LKR" }.freeze,
  "LRD" => { name: "Liberian Dollar", numeric_code: "430", symbol: "LRD" }.freeze,
  "LSL" => { name: "Loti", numeric_code: "426", symbol: "LSL" }.freeze,
  "LYD" => { name: "Libyan Dinar", numeric_code: "434", symbol: "LYD" }.freeze,
  "MAD" => { name: "Moroccan Dirham", numeric_code: "504", symbol: "MAD" }.freeze,
  "MDL" => { name: "Moldovan Leu", numeric_code: "498", symbol: "MDL" }.freeze,
  "MGA" => { name: "Malagasy Ariary", numeric_code: "969", symbol: "MGA" }.freeze,
  "MKD" => { name: "Denar", numeric_code: "807", symbol: "MKD" }.freeze,
  "MMK" => { name: "Kyat", numeric_code: "104", symbol: "MMK" }.freeze,
  "MNT" => { name: "Tugrik", numeric_code: "496", symbol: "MNT" }.freeze,
  "MOP" => { name: "Pataca", numeric_code: "446", symbol: "MOP" }.freeze,
  "MRU" => { name: "Ouguiya", numeric_code: "929", symbol: "MRU" }.freeze,
  "MUR" => { name: "Mauritius Rupee", numeric_code: "480", symbol: "MUR" }.freeze,
  "MVR" => { name: "Rufiyaa", numeric_code: "462", symbol: "MVR" }.freeze,
  "MWK" => { name: "Malawi Kwacha", numeric_code: "454", symbol: "MWK" }.freeze,
  "MXN" => { name: "Mexican Peso", numeric_code: "484", symbol: "MX$" }.freeze,
  "MXV" => { name: "Mexican Unidad de Inversion (UDI)", numeric_code: "979", symbol: "MXV" }.freeze,
  "MYR" => { name: "Malaysian Ringgit", numeric_code: "458", symbol: "MYR" }.freeze,
  "MZN" => { name: "Mozambique Metical", numeric_code: "943", symbol: "MZN" }.freeze,
  "NAD" => { name: "Namibia Dollar", numeric_code: "516", symbol: "NAD" }.freeze,
  "NGN" => { name: "Naira", numeric_code: "566", symbol: "NGN" }.freeze,
  "NIO" => { name: "Cordoba Oro", numeric_code: "558", symbol: "NIO" }.freeze,
  "NOK" => { name: "Norwegian Krone", numeric_code: "578", symbol: "NOK" }.freeze,
  "NPR" => { name: "Nepalese Rupee", numeric_code: "524", symbol: "NPR" }.freeze,
  "NZD" => { name: "New Zealand Dollar", numeric_code: "554", symbol: "NZ$" }.freeze,
  "OMR" => { name: "Rial Omani", numeric_code: "512", symbol: "OMR" }.freeze,
  "PAB" => { name: "Balboa", numeric_code: "590", symbol: "PAB" }.freeze,
  "PEN" => { name: "Sol", numeric_code: "604", symbol: "PEN" }.freeze,
  "PGK" => { name: "Kina", numeric_code: "598", symbol: "PGK" }.freeze,
  "PHP" => { name: "Philippine Peso", numeric_code: "608", symbol: "₱" }.freeze,
  "PKR" => { name: "Pakistan Rupee", numeric_code: "586", symbol: "PKR" }.freeze,
  "PLN" => { name: "Zloty", numeric_code: "985", symbol: "PLN" }.freeze,
  "PYG" => { name: "Guarani", numeric_code: "600", symbol: "PYG" }.freeze,
  "QAR" => { name: "Qatari Rial", numeric_code: "634", symbol: "QAR" }.freeze,
  "RON" => { name: "Romanian Leu", numeric_code: "946", symbol: "RON" }.freeze,
  "RSD" => { name: "Serbian Dinar", numeric_code: "941", symbol: "RSD" }.freeze,
  "RUB" => { name: "Russian Ruble", numeric_code: "643", symbol: "RUB" }.freeze,
  "RWF" => { name: "Rwanda Franc", numeric_code: "646", symbol: "RWF" }.freeze,
  "SAR" => { name: "Saudi Riyal", numeric_code: "682", symbol: "SAR" }.freeze,
  "SBD" => { name: "Solomon Islands Dollar", numeric_code: "090", symbol: "SBD" }.freeze,
  "SCR" => { name: "Seychelles Rupee", numeric_code: "690", symbol: "SCR" }.freeze,
  "SDG" => { name: "Sudanese Pound", numeric_code: "938", symbol: "SDG" }.freeze,
  "SEK" => { name: "Swedish Krona", numeric_code: "752", symbol: "SEK" }.freeze,
  "SGD" => { name: "Singapore Dollar", numeric_code: "702", symbol: "SGD" }.freeze,
  "SHP" => { name: "Saint Helena Pound", numeric_code: "654", symbol: "SHP" }.freeze,
  "SLE" => { name: "Leone", numeric_code: "925", symbol: "SLE" }.freeze,
  "SOS" => { name: "Somali Shilling", numeric_code: "706", symbol: "SOS" }.freeze,
  "SRD" => { name: "Surinam Dollar", numeric_code: "968", symbol: "SRD" }.freeze,
  "SSP" => { name: "South Sudanese Pound", numeric_code: "728", symbol: "SSP" }.freeze,
  "STN" => { name: "Dobra", numeric_code: "930", symbol: "STN" }.freeze,
  "SVC" => { name: "El Salvador Colon", numeric_code: "222", symbol: "SVC" }.freeze,
  "SYP" => { name: "Syrian Pound", numeric_code: "760", symbol: "SYP" }.freeze,
  "SZL" => { name: "Lilangeni", numeric_code: "748", symbol: "SZL" }.freeze,
  "THB" => { name: "Baht", numeric_code: "764", symbol: "THB" }.freeze,
  "TJS" => { name: "Somoni", numeric_code: "972", symbol: "TJS" }.freeze,
  "TMT" => { name: "Turkmenistan New Manat", numeric_code: "934", symbol: "TMT" }.freeze,
  "TND" => { name: "Tunisian Dinar", numeric_code: "788", symbol: "TND" }.freeze,
  "TOP" => { name: "Pa’anga", numeric_code: "776", symbol: "TOP" }.freeze,
  "TRY" => { name: "Turkish Lira", numeric_code: "949", symbol: "TRY" }.freeze,
  "TTD" => { name: "Trinidad and Tobago Dollar", numeric_code: "780", symbol: "TTD" }.freeze,
  "TWD" => { name: "New Taiwan Dollar", numeric_code: "901", symbol: "NT$" }.freeze,
  "TZS" => { name: "Tanzanian Shilling", numeric_code: "834", symbol: "TZS" }.freeze,
  "UAH" => { name: "Hryvnia", numeric_code: "980", symbol: "UAH" }.freeze,
  "UGX" => { name: "Uganda Shilling", numeric_code: "800", symbol: "UGX" }.freeze,
  "USD" => { name: "US Dollar", numeric_code: "840", symbol: "$" }.freeze,
  "USN" => { name: "US Dollar (Next day)", numeric_code: "997", symbol: "USN" }.freeze,
  "UYI" => { name: "Uruguay Peso en Unidades Indexadas (UI)", numeric_code: "940", symbol: "UYI" }.freeze,
  "UYU" => { name: "Peso Uruguayo", numeric_code: "858", symbol: "UYU" }.freeze,
  "UYW" => { name: "Unidad Previsional", numeric_code: "927", symbol: "UYW" }.freeze,
  "UZS" => { name: "Uzbekistan Sum", numeric_code: "860", symbol: "UZS" }.freeze,
  "VED" => { name: "Bolívar Soberano", numeric_code: "926", symbol: "VED" }.freeze,
  "VES" => { name: "Bolívar Soberano", numeric_code: "928", symbol: "VES" }.freeze,
  "VND" => { name: "Dong", numeric_code: "704", symbol: "₫" }.freeze,
  "VUV" => { name: "Vatu", numeric_code: "548", symbol: "VUV" }.freeze,
  "WST" => { name: "Tala", numeric_code: "882", symbol: "WST" }.freeze,
  "XAD" => { name: "Arab Accounting Dinar", numeric_code: "396", symbol: "XAD" }.freeze,
  "XAF" => { name: "CFA Franc BEAC", numeric_code: "950", symbol: "FCFA" }.freeze,
  "XAG" => { name: "Silver", numeric_code: "961", symbol: "XAG" }.freeze,
  "XAU" => { name: "Gold", numeric_code: "959", symbol: "XAU" }.freeze,
  "XBA" => { name: "Bond Markets Unit European Composite Unit (EURCO)", numeric_code: "955", symbol: "XBA" }.freeze,
  "XBB" => { name: "Bond Markets Unit European Monetary Unit (E.M.U.-6)", numeric_code: "956", symbol: "XBB" }.freeze,
  "XBC" => { name: "Bond Markets Unit European Unit of Account 9 (E.U.A.-9)", numeric_code: "957", symbol: "XBC" }.freeze,
  "XBD" => { name: "Bond Markets Unit European Unit of Account 17 (E.U.A.-17)", numeric_code: "958", symbol: "XBD" }.freeze,
  "XCD" => { name: "East Caribbean Dollar", numeric_code: "951", symbol: "EC$" }.freeze,
  "XCG" => { name: "Caribbean Guilder", numeric_code: "532", symbol: "XCG" }.freeze,
  "XDR" => { name: "SDR (Special Drawing Right)", numeric_code: "960", symbol: "XDR" }.freeze,
  "XOF" => { name: "CFA Franc BCEAO", numeric_code: "952", symbol: "F CFA" }.freeze,
  "XPD" => { name: "Palladium", numeric_code: "964", symbol: "XPD" }.freeze,
  "XPF" => { name: "CFP Franc", numeric_code: "953", symbol: "CFPF" }.freeze,
  "XPT" => { name: "Platinum", numeric_code: "962", symbol: "XPT" }.freeze,
  "XSU" => { name: "Sucre", numeric_code: "994", symbol: "XSU" }.freeze,
  "XTS" => { name: "Codes specifically reserved for testing purposes", numeric_code: "963", symbol: "XTS" }.freeze,
  "XUA" => { name: "ADB Unit of Account", numeric_code: "965", symbol: "XUA" }.freeze,
  "XXX" => { name: "The codes assigned for transactions where no currency is involved", numeric_code: "999", symbol: "XXX" }.freeze,
  "YER" => { name: "Yemeni Rial", numeric_code: "886", symbol: "YER" }.freeze,
  "ZAR" => { name: "Rand", numeric_code: "710", symbol: "ZAR" }.freeze,
  "ZMW" => { name: "Zambian Kwacha", numeric_code: "967", symbol: "ZMW" }.freeze,
  "ZWG" => { name: "Zimbabwe Gold", numeric_code: "924", symbol: "ZWG" }.freeze
  }.freeze

  belongs_to :budget, inverse_of: :currencies

  validates :name, :numeric_code, :symbol, presence: true
  validates :rate, numericality: { greater_than: 0 }
  validates :alphabetic_code,
    presence: true,
    inclusion: { in: CATALOG.keys },
    uniqueness: { scope: :budget_id }
  validates :numeric_code, format: { with: /\A\d{3}\z/ }
  validate :alphabetic_code_is_immutable, on: :update
  validate :base_currency_rate_is_1
  class << self
    def catalog
      CATALOG
    end

    def options
      CATALOG.map { |code, data| [ "#{data[:name]} (#{code})", code ] }
    end

    def find_in_catalog(code)
      CATALOG[code.to_s.strip.upcase]
    end
  end

  def alphabetic_code=(value)
    code = value.to_s.strip.upcase.presence
    super(code)

    metadata = self.class.find_in_catalog(code)
    self.name = metadata&.fetch(:name, nil)
    self.numeric_code = metadata&.fetch(:numeric_code, nil)
    self.symbol = metadata&.fetch(:symbol, nil)
  end

  def amount_in_base(amount)
    BigDecimal(amount.to_s) * rate
  end

  def base?
    budget&.base_currency == self
  end

  private
    def alphabetic_code_is_immutable
      errors.add(:alphabetic_code, "cannot be changed") if will_save_change_to_alphabetic_code?
    end

    def base_currency_rate_is_1
      errors.add(:rate, "must be 1 for the base currency") if base? && rate != 1
    end
end
