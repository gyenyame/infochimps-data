require 'imw/chunk_store/cached_uri'
require 'imw/chunk_store/scrape'
class TwitterScrapeFile
  include ScrapeFile
  attr_accessor :screen_name, :twitter_id, :context, :page, :count

  #
  # Create from a screen_name, context and page number
  #
  def initialize screen_name, twitter_id, context, page, count=nil, since=nil
    self.screen_name  = screen_name
    self.twitter_id   = "%010d"%twitter_id.to_i
    self.context      = context
    self.page         = page
    self.count        = count
    # self.since        = since
    # self.cached_uri = CachedUri.new(rip_uri, timestamp)
  end

  #
  # The URL for a given resource
  #
  def rip_uri
    uri = "http://twitter.com/#{resource_path}/#{screen_name}.json?page=#{page}"
    uri += "&count=#{count}" if count
    # uri += "&since=#{since}" if since
    uri
  end

  # Context <=> resource mapping
  RESOURCE_PATH_FROM_CONTEXT = {
    :followers  => 'statuses/followers',
    :friends    => 'statuses/friends',
    :user       => 'users/show',
    :favorites  => 'favorites',
    :timeline   => 'statuses/user_timeline',
  }
  # Get url resource for context
  def resource_path
    RESOURCE_PATH_FROM_CONTEXT[context.to_sym]
  end
  # Get context from url resource
  def self.context_for_resource(resource)
    RESOURCE_PATH_FROM_CONTEXT.invert[resource]
  end

  #
  # CachedUri supplies the file path scheme
  #
  def file_path
    # cached_uri.file_path
    filepath = [
      "_com/_tw/com.twitter/#{file_timestamp_dir_part}/#{resource_path}/",
      "#{screen_name}.json%3Fpage%3D#{page}",
      ("%26count%3D#{count}" if count),
      "+u#{twitter_id}+d#{file_timestamp_part}.json"
      ].compact.join("")
  end

  # Encode the fragment part of the file path
  #
  # Note that +
  def file_timestamp_part
    timestamp ? timestamp.strftime("%Y%m%d%H%M%S") : ""
  end
  def file_timestamp_dir_part
    timestamp ? timestamp.strftime("_%Y%m%d/_%H") : ""
  end

  def timestamp
    @timestamp ||= Time.now
  end


  # Regular expression to grok resource from uri
  DOMAIN_RESOURCE_RE = %r{http://twitter.com/([\w/]+)/(\w+)\.json\?page=(\d+)}
  #
  # create a scrape file for the given uri
  #
  def self.new_from_uri uri_str, timestamp=nil
    # Pull info from URL
    m = DOMAIN_RESOURCE_RE.match(uri_str)
    unless m then warn "Can't grok uri #{uri_str}"; return nil; end
    resource, screen_name, page = m.captures
    # figure out context from path
    context = context_for_resource(resource)
    # create instance
    self.new screen_name, context, page, timestamp
  end
  #
  # Create the
  #
  def self.new_from_file filename
    uri_str, timestamp = CachedUri.url_from_file_path filename
    self.new_from_uri(uri_str, timestamp)
  end

  # #
  # # create a scrape_file for an existing file
  # #
  # def self.new_from_old_ripd_file filename
  #   m = RIPD_FILE_RE.match(filename)
  #   unless m then warn "Can't grok filename #{filename}"; return nil; end
  #   timestamp = File.mtime(filename) if File.exists?(filename)
  #   resource, screen_name, page = m.captures
  #   context = TwitterScrapeFile::RESOURCE_PATH_FROM_CONTEXT.invert[resource]
  #   scrape_file = self.new screen_name, context, page, timestamp
  #   scrape_file
  # end

end
