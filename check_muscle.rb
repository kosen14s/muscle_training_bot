require 'net/http'
require 'uri'
require 'json'
require 'dotenv'

def get_json(url)
  res = Net::HTTP.get(URI.parse(url))
  json = JSON.parse(res)
  json if json.valid?
end

class Hash
  def valid?
    self['ok']
  end

  def has_more?
    self['has_more']
  end
end

class Slack
  MUSCLES = /muscle|kinniku/

  def initialize(token)
    @token = token
  end

  def channels
    url = "https://slack.com/api/channels.list?token=#{@token}"
    json = get_json(url)
    json['channels'].map { |channel| channel['id'] }
  end

  def messages(channel_id, since, latest = nil)
    messages = []
    url = "https://slack.com/api/channels.history?token=#{@token}&channel=#{channel_id}"
    url += "&latest=#{latest}" if latest
    json = get_json(url)

    json['messages'].each do |message|
      if message['ts'].to_i > since.to_i
        messages << message
      else
        return messages
      end
    end

    if json.has_more?
      latest = json['messages'].last['ts']
      messages += self.messages(channel_id, since, latest)
    end

    messages
  end

  def count_muscles(channel_id, since)
    muscle = 0
    messages = self.messages(channel_id, since)

    messages.each do |message|
      muscle += message['text'].to_s.scan(MUSCLES).size

      if message['reactions']
        message['reactions'].each do |reaction|
          muscle += reaction['count'] if reaction['name'].scan(MUSCLES).size.positive?
        end
      end
    end

    muscle
  end

  def count_all_muscles(since)
    muscles = 0
    self.channels.each do |channel|
      muscles += self.count_muscles(channel, since)
    end

    muscles
  end

  def post(channel_id, message, username, icon_emoji)
    url = "https://slack.com/api/chat.postMessage?token=#{@token}&channel=#{channel_id}&text=#{message}&username=#{username}&icon_emoji=#{icon_emoji}"
    uri = URI.encode(url)
    Net::HTTP.get(URI.parse(uri))
  end
end

Dotenv.load

slack = Slack.new(ENV['TOKEN'])

now = Time.new
since = Time.new(now.year, now.month, now.day, 21) - (24 * 60 * 60)
muscle_count = slack.count_all_muscles(since)

channel_id = "C157LN04W"
message = "今日の筋肉は #{muscle_count} でした。\n筋肉つけていこうな :muscle:"
username = "muscle_trainer"
icon_emoji = ":muscle:"

slack.post(channel_id, message, username, icon_emoji)
