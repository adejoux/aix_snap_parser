
# This class define attributes for a file where sections will be parsed.
#
class ParsedFile << Parser

  # * +name+ - Define parsed file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +patterns+ - Define the expressions to use to detect a section to retrieve.
  attr_reader :patterns

  # create a new object
  # * +file+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to file
  def initialize(file, config)
    @name=file
    @patterns=[]
    config['patterns'].each_key do |pattern|
      @patterns<<Pattern.new(pattern,config['patterns'][pattern])
    end
  end

  # Iterate on each pattern and return a Pattern object to the block
  def each_pattern
    @patterns.each { |pattern| yield(pattern)}
  end

end
