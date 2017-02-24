#!/usr/bin/env ruby

require 'httparty'
require 'active_support/core_ext/hash'
require 'optparse'
DEBUG = false

module ProcoreTestData
  class Downloader
    attr_reader :repository, :circle_token
    def initialize(repository: , circle_token: )
      @repository = repository
      @circle_token = circle_token
    end

    def tests
      @tests ||= run_tests
    end

    private

    def latest_artifacts
      return @latest_artifacts unless @latest_artifacts.nil?
      response = HTTParty.get "https://circleci.com/api/v1/project/#{repository}/latest/artifacts?branch=master&circle-token=#{circle_token}"
      @latest_artifacts = JSON.parse(response).select {|art| art['path'].include?("junit.xml") }
    end

    def run_tests
      latest_artifacts.each_with_object([]) do |artifact, memo|
        url = artifact["url"] + "?circle-token=#{circle_token}"
        puts "Getting #{url}" if DEBUG
        art = HTTParty.get(url).body
        test_arr = Hash.from_xml(art).fetch("testsuite").fetch("testcase")
        test_arr.each do |hash|
          hash["time"] = hash["time"].to_f
          memo << hash
        end
      end

    end
  end

  class Report
    def initialize(tests: , resolution: )
      @resolution = resolution
      @tests = tests
    end

    def to_gnuplot
      buckets.each_with_index.with_object("") do |(b, i), ret|
        ret << "#{i.to_f * resolution} #{b}\n"
      end
    end

    def to_s
      @to_s ||= tests.sort_by {|a,b| a['time']}.
        reverse.
        select {|t| t['skipped'].nil? }.
        map {|t| "File: #{t['file']}\n\tName: #{t['name']}\n\tTime: #{t['time']}"}
    end

    private

    def buckets
      @buckets ||= tests.each_with_object([]) do |test, ret|
        bucket_index = (test["time"] / resolution).to_i
        ret[bucket_index] ||= 0
        ret[bucket_index] += 1
      end.map(&:to_i)
    end
    attr_reader :resolution, :tests
  end
end

class TestSuiteCli
  attr_reader :options
  def initialize
    @options = {}
  end

  def run
    parse_options
    sanitize_options
    execute
  end

  private

  def method
    @method ||= if options[:use_gnuplot]
               :to_gnuplot
             else
               :to_s
             end
  end

  def execute
    downloader = ProcoreTestData::Downloader.new(repository: options[:repository],
                                                 circle_token: options[:circle_token])
    tests = downloader.tests
    output = ProcoreTestData::Report.new(tests: tests, resolution: options[:resolution]).send(method)
    puts output
  end

  def opt_parser
    @opt_parser ||= OptionParser.new do |opts|
      opts.program_name = File.basename(__FILE__)
      opts.banner = "#{opts.program_name} [options] -r <repository>"
      opts.on("-r STR", "--repository STR", "Github repository, e.g. \"procore/procore\"") do |str|
        options[:repository] = str
      end
      opts.on("--resolution FLOAT", "Resolution for graph ouput (default 1.0)") do |str|
        options[:resolution] = str.to_f
      end
      opts.on("-g", "Gnuplot output graphing # of tests against time to execute") do |bool|
        options[:use_gnuplot] = bool
      end
      opts.on_tail("-h", "--help", "Display this screen") { puts opts ; exit }
    end
  end

  def parse_options
    begin
      opt_parser.parse!
      raise OptionParser::MissingArgument.new("repository is required") if options[:repository].nil?
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      STDERR.puts e.message
      puts opt_parser
      exit(1)
    end
  end

  def sanitize_options
    options[:use_gnuplot] = false if options[:use_gnuplot].nil?
    options[:resolution] = 1.0 if options[:resolution].nil?
    options[:circle_token] = ENV["CIRCLE_TOKEN"]
    raise ArgumentError.new("Must provide CIRCLE_TOKEN environmental variable") if options[:circle_token].nil?
  end
end

TestSuiteCli.new.run
