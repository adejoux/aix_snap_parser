# This class define attributes for a pattern from a MatchedFile.
#
class Matchexp
  # * +name+ - Define full file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +label+ - Label used in excel file
  attr_reader :label

  # create a new object
  # * +file+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to pattern
  def initialize(name, config)
    @name=name
    @label=config['label']
  end
end
