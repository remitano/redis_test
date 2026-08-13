require 'spec_helper'

RSpec.describe RedisTest do
  describe '#start' do
    after do
      RedisTest.stop if RedisTest.started?
    end

    it 'starts and stops Redis' do
      expect(RedisTest.started?).to be_falsey

      RedisTest.start

      expect(RedisTest.started?).to be_truthy
      RedisTest.stop
      expect(RedisTest.started?).to be_falsey
    end

    it 'logs to a file by default' do
      RedisTest.start

      expect(redis_config('logfile')).to eq(RedisTest.logfile)
    end

    it 'logs to stdout when requested' do
      RedisTest.start(log_to_stdout: true)

      expect(redis_config('logfile')).to eq('')
    end

    it 'uses persistence-disabled and high-connection defaults' do
      RedisTest.start(log_to_stdout: true)

      expect(redis_config('save')).to eq('')
      expect(redis_config('appendonly')).to eq('no')
      expect(redis_config('maxclients')).to eq('10000')
      expect(redis_config('loglevel')).to eq('warning')
    end

    it 'accepts Redis option overrides with symbol or string keys' do
      RedisTest.start(
        log_to_stdout: true,
        redis_options: { timeout: 42, 'maxclients' => 321 }
      )

      expect(redis_config('timeout')).to eq('42')
      expect(redis_config('maxclients')).to eq('321')
    end

    def redis_config(name)
      socket = TCPSocket.open('localhost', RedisTest.port)
      command = ['CONFIG', 'GET', name]
      socket.write("*#{command.length}\r\n")
      command.each { |part| socket.write("$#{part.bytesize}\r\n#{part}\r\n") }

      socket.gets
      read_bulk_string(socket)
      read_bulk_string(socket)
    ensure
      socket&.close
    end

    def read_bulk_string(socket)
      length = socket.gets[1..-1].to_i
      value = socket.read(length)
      socket.read(2)
      value
    end
  end
end
