mysql    = require 'mysql'
settings = require './settings.json'

BCPM_COLUMNS = [
  'bcpm_01_kw'
  'bcpm_02_kw'
  'bcpm_03_kw'
  'bcpm_04_kw'
  'bcpm_05_kw'
  'bcpm_06_kw'
  'bcpm_07_kw'
  'bcpm_08_kw'
  'bcpm_09_kw'
  'bcpm_10_kw'
  'bcpm_11_kw'
  'bcpm_12_kw'
  'bcpm_13_kw'
  'bcpm_14_kw'
  'bcpm_15_kw'
  'bcpm_16_kw'
  'bcpm_17_kw'
  'bcpm_18_kw'
  'bcpm_19_kw'
  'bcpm_20_kw'
  'bcpm_21_kw'
  'bcpm_22_kw'
  'bcpm_23_kw'
  'bcpm_24_kw'
  'bcpm_25_kw'
  'bcpm_26_kw'
  'bcpm_27_kw'
  'bcpm_28_kw'
  'bcpm_29_kw'
  'bcpm_30_kw'
  'bcpm_31_kw'
  'bcpm_32_kw'
  'bcpm_33_kw'
  'bcpm_34_kw'
  'bcpm_35_kw'
  'bcpm_36_kw'
  'bcpm_37_kw'
  'bcpm_38_kw'
  'bcpm_39_kw'
  'bcpm_40_kw'
  'bcpm_41_kw'
  'bcpm_42_kw'
  'bcpm_01_kwh'
  'bcpm_02_kwh'
  'bcpm_03_kwh'
  'bcpm_04_kwh'
  'bcpm_05_kwh'
  'bcpm_06_kwh'
  'bcpm_07_kwh'
  'bcpm_08_kwh'
  'bcpm_09_kwh'
  'bcpm_10_kwh'
  'bcpm_11_kwh'
  'bcpm_12_kwh'
  'bcpm_13_kwh'
  'bcpm_14_kwh'
  'bcpm_15_kwh'
  'bcpm_16_kwh'
  'bcpm_17_kwh'
  'bcpm_18_kwh'
  'bcpm_19_kwh'
  'bcpm_20_kwh'
  'bcpm_21_kwh'
  'bcpm_22_kwh'
  'bcpm_23_kwh'
  'bcpm_24_kwh'
  'bcpm_25_kwh'
  'bcpm_26_kwh'
  'bcpm_27_kwh'
  'bcpm_28_kwh'
  'bcpm_29_kwh'
  'bcpm_30_kwh'
  'bcpm_31_kwh'
  'bcpm_32_kwh'
  'bcpm_33_kwh'
  'bcpm_34_kwh'
  'bcpm_35_kwh'
  'bcpm_36_kwh'
  'bcpm_37_kwh'
  'bcpm_38_kwh'
  'bcpm_39_kwh'
  'bcpm_40_kwh'
  'bcpm_41_kwh'
  'bcpm_42_kwh'
  'bcpm_a_i'
  'bcpm_a_kw'
  'bcpm_a_v'
  'bcpm_b_i'
  'bcpm_b_kw'
  'bcpm_b_v'
  'bcpm_cba_kwh'
  'bcpm_frequency'
]

connection = mysql.createConnection settings.database

connection.connect()

module.exports.parse = (data) ->
  columns = {}

  for label in BCPM_COLUMNS
    for entry in data
      if entry.Name is label
        columns[label] = if entry.Status? then entry.Status else 0
        break

    unless columns[label]?
      columns[label] = 0 

  query = "INSERT INTO bcpm ("
  for label,i in BCPM_COLUMNS
    query += "`#{label}`#{if i < BCPM_COLUMNS.length - 1 then ', ' else ''}"

  query += ") VALUES ("

  for label,i in BCPM_COLUMNS
    query += "#{connection.escape columns[label]}#{if i < BCPM_COLUMNS.length - 1 then ', ' else ''}"

  query += ")"

  connection.query query, (err, results) ->
    console.log err if err