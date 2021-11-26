# frozen_string_literal: true

# helper of main controller
module MainHelper
  # get json with fio from db
  def get_records_from_db(results)
    results.map do |row|
      JSON.parse(row['result'])['response']['result'][0]['query']['params']
    end
  end

  def init_mysql_client
    Mysql2::Client.new(
      host: '127.0.0.1',
      username: 'max-credit',
      password: 'max-credit',
      port: 8002,
      encoding: 'utf8'
    )
  end

  def renew_ip
    localhost = Net::Telnet::new('Host' => 'localhost', 'Port' => '9051', 'Timeout' => 10, 'Prompt' => /250 OK\n/)
    localhost.cmd('AUTHENTICATE ""') { |c| print c; throw 'Cannot authenticate to Tor' if c != "250 OK\n" }
    localhost.cmd('signal NEWNYM') { |c| print c; throw 'Cannot switch Tor to new route' if c != "250 OK\n" }
    localhost.close
  end
end
