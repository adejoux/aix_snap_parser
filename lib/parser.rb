class Parser
  # * +name+ - Define parsed file name or regular expression used to retrieve it in snap archive
  attr_reader :name
  # * +sheet+ * - excel sheet where to put the extracted lines.
  attr_reader :sheet
  # * +exclude+ * - exclude file where to put the extracted lines.
  attr_reader :exclude
end
