class Parser
  # * +name+ - Define parsed file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +sheet+ * - excel sheet where to put the extracted lines.
  attr_reader :sheet
  # * +label+ * - label to use
  attr_reader :label
  # * +exclude+ * - exclude file where to put the extracted lines.
  attr_reader :exclude

  # create a new object
  # * +name+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to file
  def initialize(name, config)
    @name=name
    @config=config
    @label=config['label']
  end

  def is_excluded?(filename)
    if @config["excluded_files"].nil?
      return false
    end

    @config["excluded_files"].each do |file|
      if filename.match(/#{file}/)
        return true
      end
    end
    return false
  end
end
