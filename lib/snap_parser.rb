
# class dedicated to parse ParsedFile and extract section contents from snap.
class SnapParser
  # * +header+ - Define if we are in a content section or a header section.
  attr_accessor :header
  # * +previous_line+ - Contains the previous parsed line.
  attr_accessor :previous_line
  # * +pattern+ -  Contains the Pattern object used for parsing
  attr_reader :pattern

  # construction method
  def initialize
    @header=false
  end

  # This set pattern attribute to a Pattern Object
  # and set parser for processing content.
  def pattern=(name)
    @pattern=name
    @previous_line=""
    @header=true
  end
end
