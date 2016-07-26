require 'net/http'
require 'uri'
require 'json'
require 'dotenv'

def get_json(url)
  res = Net::HTTP.get(URI.parse(url))
  JSON.parse(res)
end

def valid?(json)
  json['ok']
end

def has_more?(json)
  json['has_more']
end

def count_muscles(json, std_of_the_day, channel_id)
  if valid?(json)
    json['messages'].each do |message|
      if Time.at(message['ts'].to_i) > std_of_the_day
		MUSCLES.each do |muscle|
		  $muscle_count += message['text'].to_s.scan(muscle).size

		  if message['reactions']
			message['reactions'].each do |reaction|
			  $muscle_count += reaction['users'].count if reaction['name'].include?(muscle)
			end
		  end
		end
      else
        break
      end
    end

    if has_more?(json)
      latest = json['messages'].last['ts']
      url = "https://slack.com/api/channels.history?token=#{ENV['TOKEN']}&channel=#{channel_id}&latest=#{latest}"
      json = get_json(url)
      count_muscles(json, std_of_the_day, channel_id) if has_more?(json)
    end
  end

  $muscle_count
end

Dotenv.load

MUSCLES = %w(muscle kinniku)
$muscle_count = 0
channels = []

# 時間、比較用
time = Time.now
year = time.year
month = time.month
day = time.day
std_of_the_day = Time.new(year, month, day, 21) - (24 * 60 * 60)

url = "https://slack.com/api/channels.list?token=#{ENV['TOKEN']}"
json_ch = get_json(url)

# 全チャンネル取得
if valid?(json_ch)
  json_ch['channels'].each do |ch|
    channels << [id: ch['id'], name: ch['name']]
  end
end

# メッセージとreactions取得
channels.each do |channel|
  url = "https://slack.com/api/channels.history?token=#{ENV['TOKEN']}&channel=#{channel[0][:id]}"
  json = get_json(url)

  count_muscles(json, std_of_the_day, channel[0][:id])
end

message = "今日の筋肉は #{$muscle_count} でした。\n筋肉つけていこうな :muscle:"
url = "https://slack.com/api/chat.postMessage?token=#{ENV['TOKEN']}&channel=C157LN04W&text=#{message}&username=muscle_trainer&icon_emoji=:muscle:"

uri = URI.encode(url)
Net::HTTP.get(URI.parse(uri))
