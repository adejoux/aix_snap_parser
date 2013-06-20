

# This class define attributes for a file where all content will be insered in report.
#
class FullFile
  # * +name+ - Define full file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +separator+ - Character used to split the line
  attr_reader :separator
  # * +sep_num+ - limit split to the specified number. 0 by default
  attr_reader :sep_num
  # * +skip_empty+ - Boolean. Define if empty are skipped. False by default
  attr_reader :skip_empty
  # * +skip_line+ - Regular expression used to skip line if matched.
  attr_reader :skip_line
  # * +sheet+ * - excel sheet where to put the extracted lines.
  attr_reader :sheet

  # create a new object
  # * +file+ - parsed file name or regular expression used to retrieve it in snap archive
  # * +config+ - the config section associated to file
  def initialize(file, config)
    @name=file
    @separator=config['separator']
    @skip_line=config['skip_line']
    @skip_empty=config['skip_empty'] || false
    @sep_num=config['sep_num'] || 0
    @sheet=config['sheet']
  end

end
