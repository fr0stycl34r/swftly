class Swftly
  require 'curb'
  attr_reader :auto_process, :swf, :runtime, :markup, :raw,
              :converter_response_code, :fetcher_response_code

  #init w/ a swf, through false for the second param if you don't wanna
  #immediately trigger post-conversion processing
  def initialize( swf, auto_process = true )
    @swf = swf
    @auto_process = auto_process
  end

  # post the swf to swiffy and parse/process the results
  def swiff
    file = Curl::PostField.file 'swfFile', @swf
    converter = Curl::Easy.http_post("https://www.google.com/doubleclick/studio/swiffy/upload", file) do |curl|
      curl.multipart_form_post = true
      curl.headers["User-Agent"] = "Curl/Ruby"
      curl.follow_location = true
      curl.enable_cookies = true
    end

    @converter_response_code = converter.response_code
    @raw = converter.body_str

    process if @auto_process
  end

  # perform and process the second fetching
  def process
    return failed unless @converter_response_code == 200
    cooked = @raw.split '","'
    path = (cooked[3] + cooked[5]).gsub(/\/i\//,'/o/')

    fetcher = Curl.get(path)

    @fetcher_response_code = fetcher.response_code
    @markup = fetcher.body_str
    @runtime = Runtime.new(@markup)
  end

  protected

  def failed
    raise "File conversion failed with response code #{response_code}."
  end
end

require 'swftly/runtime'