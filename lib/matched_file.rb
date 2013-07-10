
# This class define attributes for a file where sections will be matched.
#
class MatchedFile

  # * +name+ - Define parsed file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +regexps+ - Define the expressions to use to detect a section to retrieve.
  attr_reader :matchexps
  # * +sheet+ * - excel sheet where to put the extracted lines.
  attr_reader :sheet
    # * +exclude+ * - exclude file where to put the extracted lines.
  attr_reader :exclude

  # create a new object
  # * +file+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to file
  def initialize(file, config)
    @name=file
    @matchexps=[]
    @sheet=config['sheet']
    @exclude=config['exclude']
    config['matchs'].each_key do |pattern|
      @matchexps<<Matchexp.new(pattern,config['matchs'][pattern])
    end
  end

  # Iterate on each pattern and return a Pattern object to the block
  def each_matchexp
    @matchexps.each { |matchexp| yield(matchexp)}
  end
end
