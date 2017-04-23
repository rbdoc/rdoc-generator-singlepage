require 'rdoc/rdoc'

require_relative 'settings'
require_relative 'doc_loader'
require_relative 'theme_loader'
require_relative 'template_loader'
require_relative 'json_builder'
require_relative 'html_builder'

class RDoc::Options
  attr_accessor :sf_htmlfile
  attr_accessor :sf_jsonfile
  attr_accessor :sf_prefix
  attr_accessor :sf_template
  attr_accessor :sf_themes
  attr_accessor :sf_filter_classes
  attr_accessor :sf_filter_members
end

class RDoc::Generator::SolarFish
  RDoc::RDoc.add_generator(self)

  def self.setup_options(rdoc_options)
    rdoc_options.sf_htmlfile = Settings::DEFAULT_HTMLFILE

    opt = rdoc_options.option_parser
    opt.separator 'SolarFish generator options:'

    opt.separator nil
    opt.on('--sf-htmlfile=FILE', String,
           'Set output HTML file name.',
           "Defaults to '#{Settings::DEFAULT_HTMLFILE}'.") do |value|
      rdoc_options.sf_htmlfile = value
    end

    opt.separator nil
    opt.on('--sf-jsonfile=FILE', String,
           'Set output JSON file name.',
           'Empty by default.') do |value|
      rdoc_options.sf_jsonfile = value
    end

    opt.separator nil
    opt.on('--sf-template=NAME', String,
           "Set template. Defaults to '#{Settings::DEFAULT_TEMPLATE}'.",
           "If name contains slash, it's a path, and",
           "otherwise it's a name of installed template.",
           'Installed templates:',
           *(TemplateLoader.templates_list
             .map { |s| " - #{s}" })) do |value|
      rdoc_options.sf_template = TemplateLoader.template_path(value)
    end

    opt.separator nil
    opt.on('--sf-theme=NAME', String,
           "Set theme. Defaults to '#{Settings::DEFAULT_THEME}'. Specify",
           'multiple times to merge several themes. Every',
           'next theme overwrites options set by previous',
           "themes. If name contains slash, it's a path,",
           "and otherwise it's a name of installed theme.",
           'Installed themes:',
           *(ThemeLoader.themes_list
              .map { |s| " - #{s}" })) do |value|
      rdoc_options.sf_themes ||= []
      rdoc_options.sf_themes << ThemeLoader.theme_path(value)
    end

    opt.separator nil
    opt.on('--sf-prefix=PREFIX', String,
           'Set URL prefix for links to stylesheets and',
           'scripts in generated HTML. Empty by default.') do |value|
      rdoc_options.sf_prefix = value
    end

    opt.separator nil
    opt.on('--sf-filter-classes=REGEX', String,
           'Include only classes and modules that',
           'match regex.') do |value|
      rdoc_options.sf_filter_classes = Regexpn.new(value)
    end

    opt.separator nil
    opt.on('--sf-filter-members=REGEX', String,
           'Include only members that match regex.') do |value|
      rdoc_options.sf_filter_members = Regexp.new(value)
    end
  end

  def initialize(store, options)
    @store = store
    @options = options
  end

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  def generate
    @options.sf_themes ||= [ThemeLoader.theme_path(Settings::DEFAULT_THEME)]
    @options.sf_template ||= TemplateLoader.template_path(Settings::DEFAULT_TEMPLATE)

    doc_loader = DocLoader.new(@options, @store)
    classes = doc_loader.load

    if @options.sf_jsonfile
      json_builder = JSONBuilder.new(@options)
      json_builder.build(classes)
    end

    if @options.sf_htmlfile
      theme_loader = ThemeLoader.new(@options)
      theme = theme_loader.load

      template_loader = TemplateLoader.new(@options)
      template = template_loader.load

      html_builder = HTMLBuilder.new(@options)
      html_builder.build(classes, theme, template)
    end
  end
end