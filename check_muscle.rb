require 'net/http'
require 'uri'
require 'json'
require 'dotenv'
require 'pry'

Dotenv.load

# TODO: CH一覧もまとめて取得
CH_GENERAL = 'C0KNQP0ET'
CH_MUSCLE = 'C157LN04W'
CH_PROFILE = 'C0KP424FL'
CH_RONDOM = 'C0KNR3NJ2'

muscle_count = 0

url = "https://slack.com/api/channels.history?token=#{ENV['TOKEN']}&channel=#{CH_PROFILE}"

res = Net::HTTP.get(URI.parse(url))
json = JSON.parse(res)

if json['ok']
  json['messages'].each do |message|
    muscle_count += 1 if message['text'].include?(':muscle:')

    if message['reactions']
      message['reactions'].each do |reaction|
        muscle_count += reaction['users'].count if reaction['name'] == 'muscle'
      end
    end
  end

  puts muscle_count
end
