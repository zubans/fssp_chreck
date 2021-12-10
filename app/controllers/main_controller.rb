# frozen_string_literal: true

# work with fssp api
class MainController < ApplicationController
  require 'net/telnet'
  def index
    client = helpers.init_mysql_client

    records = helpers.get_records_from_db(client.query('SELECT * FROM `max-credit`.fssp_check'))

    rest_client = RestClient
    port = 8118
    rest_client.proxy = "localhost:#{port}"
    i = 1
    token = Token.find(i).value
    request_count = 0
    records.each do |client|
      begin
        response = rest_client.get 'https://api-ip.fssp.gov.ru/api/v1.0/search/physical', {
          params: {
            'token' => token,
            'region' => 0,
            'firstname' => client['firstname'],
            'lastname' => client['lastname'],
            'birthdate' => client['birthdate']
          }
        }
      rescue rest_client::ExceptionWithResponse
        exception_in_response = change_token(i)
        token = exception_in_response[:token]
        i = exception_in_response[:iterator]
        rest_client.proxy = "localhost:#{exception_in_response[:port]}"
        # sleep(10)
        next
      end

      Response.create(result: JSON.parse(response)['response']['task'], token: token)

      if request_count == 30
        exception_in_response = change_token(i)
        token = exception_in_response[:token]
        i = exception_in_response[:iterator]
        # rest_client.proxy = exception_in_response[:port]
        request_count = 0
      end
      request_count += 1
      # sleep(rand(5))
    end

    #todo get out to function
    Response.all.each do |client|
      response = restClient.get 'https://api-ip.fssp.gov.ru/api/v1.0/status', 
{ params: { 'token' => '04SlHONVuitv', 'task' => client.result } }
      client.status = JSON.parse(response)['response']['status']
      client.save
      sleep(rand(5))
    end

    Response.all.each do |client|
      response = restClient.get 'https://api-ip.fssp.gov.ru/api/v1.0/result', 
{ params: { 'token' => '04SlHONVuitv', 'task' => client.result } }
      client.full_result = JSON.parse(response)['response']['status']
      client.save
      # sleep(12)
    end

    render json: Response.all
  end

  def change_token(iterator)
    helpers.renew_ip

    iterator += 1
    iterator = 1 unless iterator <= Token.count

    { token: Token.find(iterator).value, iterator: iterator,
      port: %w[8118 7118 6118 5118 4118 3118 2118 1118 11118 21118][iterator] }
  end

  def renew_ip
    helpers.renew_ip
  end
end
