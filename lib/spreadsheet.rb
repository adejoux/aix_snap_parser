
# Parse the configuration file
# and provide methods to access FullFile and ParsedFile objects.
class Spreadsheet

  # * +yaml_file+ * - the configuration file with instructions to parse the snap
  def initialize
    @axlsx=Axlsx::Package.new
    @workbook=@axlsx.workbook
    @styles=@workbook.styles
    @custom_styles={}
    @sheets={}
    build_styles
    build_summary
  end

  def style(name)
    @custom_styles[name]
  end

  def set_table
    @table_header=@sheets[sheet].add_row
    @table_body=@sheets[sheet].add_row
  end

  def add_body_row
    @table_body=@sheets[sheet].add_row
  end

  def add_table_header(content)
    @table_header.add_cell content, :style => style("thead")
  end

  def add_table_body(content)
    @table_body.add_cell content, :style => style("standard")
  end

  def save(filename)
    @sheets["summary"].auto_filter ="A2:B#{@sheets["summary"].rows.last.index+1}"
    @axlsx.serialize(filename)
  end

  def add_row(content)
    @sheets[sheet].add_row content
  end

  def current_sheet=(sheet_name)
    @sheet=sheet_name
  end

  def add_sheet(sheet_name)
    @sheets[sheet_name]=@workbook.add_worksheet(:name => sheet_name)
  end

  def sheet
    @sheet
  end

  def add_summary(title)
    row=@sheets[sheet].add_row [title], :style => style("header")
    @sheets[sheet].merge_cells("A#{row.index+1}:E#{row.index+1}")
    summary_row=@sheets["summary"].add_row [sheet, title], :style => [style("standard"), style("hyperlink")]
    @sheets["summary"].add_hyperlink :location => "'#{sheet}'!A#{row.index + 1}", :ref => "B#{summary_row.index + 1}", :target => :sheet
  end

  private

  def build_styles
    @custom_styles["header"] = @styles.add_style(:bg_color => '00', :fg_color => 'FF', :b => true, :alignment => {:horizontal => :center})
    @custom_styles["thead"] = @styles.add_style(:b => true, :alignment => {:horizontal => :center})
    @custom_styles["standard"] = @styles.add_style(:alignment => { :vertical => :top } )
    @custom_styles["hyperlink"] = @styles.add_style( :fg_color => "0000FF" )
  end

  def build_summary
    #build summary worksheet
    @sheets["summary"]=@workbook.add_worksheet(:name => "summary")
    @sheets["summary"].add_row ["summary"], :style => style("header")
    @sheets["summary"].merge_cells("A1:B1")
    @sheets["summary"].add_row ["category", "section"], :style => style("thead")
  end
end
