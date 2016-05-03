require 'net/http'
require 'uri'
require 'json'
require 'dotenv'
require 'pry'

MUSCLE = "muscle"
muscle_count = 0
channels = []

def get_json(url)
  res = Net::HTTP.get(URI.parse(url))
  JSON.parse(res)
end

def valid?(json)
  json['ok']
end

Dotenv.load

url = "https://slack.com/api/channels.list?token=#{ENV['TOKEN']}"
json_ch = get_json(url)

# 全チャンネル取得
if valid?(json_ch)
  json_ch['channels'].each do |ch|
    channels << [id: ch['id'], name: ch['name']]
  end
end

# 今日がはじまったときの時間、比較用
time = Time.now
year = time.year
month = time.month
day = time.day
beginning_of_the_day = Time.new(year, month, day)

# メッセージとreactions取得
channels.each do |channel|
  url = "https://slack.com/api/channels.history?token=#{ENV['TOKEN']}&channel=#{channel[0][:id]}&inclusive=1"
  json = get_json(url)

  if valid?(json)
    json['messages'].each do |message|
      if Time.at(message['ts'].to_i) > beginning_of_the_day
        muscle_count += message['text'].scan(MUSCLE).size

        if message['reactions']
          message['reactions'].each do |reaction|
            muscle_count += reaction['users'].count if reaction['name'] == MUSCLE
          end
        end
      else
        break
      end
    end
  end
end

puts muscle_count
