require 'net/http'
require 'uri'
require 'json'
require 'dotenv'
require 'pry'

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

muscle_count = 0
channels = []

# json_ch.valid? って書きたい
if valid?(json_ch)
  json_ch['channels'].each do |ch|
    channels << [id: ch['id'], name: ch['name']]
  end
end

channels.each do |channel|
  url = "https://slack.com/api/channels.history?token=#{ENV['TOKEN']}&channel=#{channel[0][:id]}"
  json = get_json(url)

  if valid?(json)
    json['messages'].each do |message|
      muscle_count += 1 if message['text'].include?(':muscle:')

      if message['reactions']
        message['reactions'].each do |reaction|
          muscle_count += reaction['users'].count if reaction['name'] == 'muscle'
        end
      end
    end
  end
end

puts muscle_count
