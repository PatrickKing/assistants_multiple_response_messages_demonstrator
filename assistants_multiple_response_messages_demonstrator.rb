require 'httparty'
require 'awesome_print'

# This script demonstrates an issue with the OpenAI Assistants API. The second run started in this script results in dozens of messages being appended to the thread, where we might have expected just one.

# The above two gems are prerequisites, run:
# gem install httparty awesome_print

# You must also fill in your OpenAI API key, and the ID for an assistant. Any assistant should do.


API_KEY = "**** YOUR KEY HERE"
ASSISTANT_ID = "**** YOUR ASSISTANT ID HERE"



common_headers = {
      "OpenAI-Beta" => "assistants=v1",
     "Content-Type" => "application/json",
    "Authorization" => "Bearer #{API_KEY}"
}



# Make a thread

response = HTTParty.post("https://api.openai.com/v1/threads", headers: common_headers)
thread = JSON.parse(response.body)


# Populate the thread with one user message, and one assistant message after the first run completes.

response = HTTParty.post("https://api.openai.com/v1/threads/#{thread['id']}/messages", headers: common_headers, body: {
    role: 'user',
    content: "Is it legal to ride your bike on the sidewalk?",
  }.to_json
)
message = JSON.parse(response.body)

response = HTTParty.post("https://api.openai.com/v1/threads/#{thread['id']}/runs", headers: common_headers, body: {assistant_id: ASSISTANT_ID}.to_json)
run = JSON.parse(response.body)

while true
  puts "First run, polling ... "

  response = HTTParty.get("https://api.openai.com/v1/threads/#{thread['id']}/runs/#{run['id']}", headers: common_headers)
  polled_run = JSON.parse(response.body)

  break if polled_run['status'] == 'completed'
  sleep 1
end

response =  HTTParty.get("https://api.openai.com/v1/threads/#{thread['id']}/messages", headers: common_headers)
messages = JSON.parse(response.body)
ap messages


# For the second run, we set up override instructions which direct the assistant to output JSON, and we don't append any additional messages.

body = {
  assistant_id: ASSISTANT_ID,
  instructions: "Your task is to choose one of three outcomes based on the based on the recent interactions between the User and the chatbot. You may choose: a) \"happy\", b) \"sad\", or c) \"neutral\" depending on the sentiment of the conversation. Your task is NOT to answer the User's question or respond to the user's input.

    Your output should consist of valid JSON. Your output must be one of:

      {\"sentiment\": \"happy\"}
      {\"sentiment\": \"sad\"}
      {\"sentiment\": \"neutral\"}

    Your output must consist ONLY of one of these three JSON outputs."
}

response = HTTParty.post("https://api.openai.com/v1/threads/#{thread['id']}/runs", headers: common_headers, body: body.to_json)
run = JSON.parse(response.body)

while true
  puts "Second run, polling ... "

  response = HTTParty.get("https://api.openai.com/v1/threads/#{thread['id']}/runs/#{run['id']}", headers: common_headers)
  polled_run = JSON.parse(response.body)

  break if polled_run['status'] == 'completed'
  sleep 1
end


# The messages response will contain the maximum of 20 messages normally returned for one messages retrieval. There may be even more messages in the thread now.

response =  HTTParty.get("https://api.openai.com/v1/threads/#{thread['id']}/messages", headers: common_headers)
messages = JSON.parse(response.body)
ap messages
