class MainController < ApplicationController
  def index
    client = Mysql2::Client.new(:host => "127.0.0.1", :username => "max-credit", :password => 'max-credit', :port => 8002, :encoding => 'utf8')
    results = client.query("SELECT * FROM `max-credit`.fssp_check")

    records = results.map do |row|
      JSON.parse(row['result'])['response']['result'][0]['query']['params']
    end

    restClient = RestClient
    restClient.proxy = 'localost:9050'
    i = 1
    token = Token.find(i)

    records.each do |client|
      begin
      response = restClient.get 'https://api-ip.fssp.gov.ru/api/v1.0/search/physical', {params: {'token' => token.value, 'region' => 0, 'firstname' => client['firstname'], 'lastname' => client['lastname'], 'birthdate' => client['birthdate'] }}
      rescue restClient::ExceptionWithResponse => e
        token = Token.find(i + 1)
      end

      if !response.nil?
        Response.create(result: JSON.parse(response)['response']['task'])
      end
      # sleep(rand(3))
    end

    Response.all.each do |client|
      response = restClient.get 'https://api-ip.fssp.gov.ru/api/v1.0/status', {params: {'token' => "04SlHONVuitv", 'task' => client.result}}
      client.status = JSON.parse(response)['response']['status']
      client.save
      # sleep(rand(5))
    end

    Response.all.each do |client|
      response = restClient.get 'https://api-ip.fssp.gov.ru/api/v1.0/result', {params: {'token' => "04SlHONVuitv", 'task' => client.result}}
      client.full_result = JSON.parse(response)['response']['status']
      client.save
      # sleep(3)
    end

    render json: Response.all
  end
end
