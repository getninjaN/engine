class ThemeAsset

  include Locomotive::Mongoid::Document

  ## fields ##
  field :local_path
  field :content_type
  field :width, :type => Integer
  field :height, :type => Integer
  field :size, :type => Integer
  field :folder, :default => nil
  field :hidden, :type => Boolean, :default => false
  mount_uploader :source, ThemeAssetUploader

  ## associations ##
  referenced_in :site

  ## indexes ##
  index :site_id
  index [[:site_id, Mongo::ASCENDING], [:local_path, Mongo::ASCENDING]]

  ## callbacks ##
  before_validation :store_plain_text
  before_validation :sanitize_folder
  before_validation :build_local_path

  ## validations ##
  validates_presence_of :site, :source
  validates_presence_of :plain_text_name, :if => Proc.new { |a| a.performing_plain_text? }
  validates_uniqueness_of :local_path, :scope => :site_id
  validates_integrity_of :source
  validate :content_type_can_not_changed

  ## named scopes ##
  scope :visible, lambda { |all| all ? {} : { :where => { :hidden => false } } }

  ## accessors ##
  attr_accessor :plain_text_name, :plain_text, :performing_plain_text

  ## methods ##

  %w{movie image stylesheet javascript font}.each do |type|
    define_method("#{type}?") do
      self.content_type == type
    end
  end

  def stylesheet_or_javascript?
    self.stylesheet? || self.javascript?
  end

  def plain_text_name
    if not @plain_text_name_changed
      @plain_text_name ||= self.safe_source_filename
    end
    @plain_text_name.gsub(/(\.[a-z0-9A-Z]+)$/, '') rescue nil
  end

  def plain_text_name=(name)
    @plain_text_name_changed = true
    @plain_text_name = name
  end

  def plain_text
    @plain_text ||= self.source.read
  end

  def performing_plain_text?
    Boolean.set(self.performing_plain_text) || false
  end

  def store_plain_text
    data = self.performing_plain_text? ? self.plain_text : self.source.read

    return if !self.stylesheet_or_javascript? || self.plain_text_name.blank? || data.blank?

    sanitized_source = self.escape_shortcut_urls(data)

    self.source = CarrierWave::SanitizedFile.new({
      :tempfile => StringIO.new(sanitized_source),
      :filename => "#{self.plain_text_name}.#{self.stylesheet? ? 'css' : 'js'}"
    })
  end

  def to_liquid
    { :url => self.source.url }.merge(self.attributes)
  end

  protected

  def safe_source_filename
    self.source_filename || self.source.send(:original_filename) rescue nil
  end

  def sanitize_folder
    self.folder = self.content_type.pluralize if self.folder.blank?

    # no accents, no spaces, no leading and ending trails
    self.folder = ActiveSupport::Inflector.transliterate(self.folder).gsub(/(\s)+/, '_').gsub(/^\//, '').gsub(/\/$/, '').downcase

    # folder should begin by a root folder
    if (self.folder =~ /^(stylesheets|javascripts|images|media|fonts)/).nil?
      self.folder = File.join(self.content_type.pluralize, self.folder)
    end
  end

  def build_local_path
    self.local_path = File.join(self.folder, self.safe_source_filename)
  end

  def escape_shortcut_urls(text)
    return if text.blank?

    text.gsub(/[("'](\/(stylesheets|javascripts|images|media)\/((.+)\/)*([a-z_\-0-9]+)\.[a-z]{2,3})[)"']/) do |path|

      sanitized_path = path.gsub(/[("')]/, '').gsub(/^\//, '')

      if asset = self.site.theme_assets.where(:local_path => sanitized_path).first
        "#{path.first}#{asset.source.url}#{path.last}"
      else
        path
      end
    end
  end

  def content_type_can_not_changed
    self.errors.add(:source, :extname_changed) if !self.new_record? && self.content_type_changed?
  end

end
