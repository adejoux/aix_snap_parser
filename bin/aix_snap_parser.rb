# -*- coding: utf-8 -*-
#author: alain dejoux
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'axlsx'
require 'optparse'
require 'yaml'
require 'rubygems/package'
# tool libs
require 'parser'
require 'full_file'
require 'spreadsheet'
require 'pattern'
require 'parsed_file'
require 'matchexp'
require 'matched_file'
require 'parser_config'
require 'snap_parser'

version=0.4

snap_file=""
config_file=""

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: analyse_snap.rb [-f snap_file] [-c config_file] [-h] [-v]"

  opts.on('-f snap', '--file=snap', 'snap file') do |v|
    snap_file = v
  end

  opts.on('-c config_file', '--config_file=config_file', 'yaml config file') do |v|
    config_file = v
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  opts.on_tail( '-v', '--version', 'Display tool version' ) do
    puts "version : #{version}"
    exit
  end
end
opt_parser.parse!

unless File.file?(snap_file)
  puts "error: file #{snap_file} is not readable"
  exit 1
end

#load configuration file
if config_file.empty?
  pc=ParserConfig.new( File.dirname(__FILE__) + '/../config/snap.yml' )
else
  pc=ParserConfig.new(config_file)
end

#create new spreadsheet
spreadsheet=Spreadsheet.new

#create sheet for each file in config
pc.sheets.each do |sheet|
  spreadsheet.add_sheet(sheet)
end

Gem::Package::TarReader.new(File.open(snap_file)).each do |entry|

  pc.each_full_file do |file|
    if entry.full_name.match(/#{file.name}/)
      spreadsheet.current_sheet=file.sheet
      spreadsheet.add_summary File.basename(entry.full_name)
      entry.read.split("\n").each do |line|
        if file.skip_line and line.match(/#{file.skip_line}/)
          next
        end
        if file.skip_empty and line.chomp.empty?
          next
        end

        if file.separator.nil?
          spreadsheet.add_row [line]
        else
          spreadsheet.add_row line.split(file.separator, file.sep_num)
        end
      end
      entry.rewind
    end
  end

  pc.each_matched_file do |file|
    if entry.full_name.match(/#{file.name}/)
      next if file.is_excluded? entry.full_name

      spreadsheet.current_sheet=file.sheet
      spreadsheet.add_summary File.basename(entry.full_name)
      spreadsheet.set_table

      entry.read.split("\n").each do |line|
        file.each_matchexp do |matchexp|
          matchres=line.match(matchexp.name)
          unless matchres.nil?
            spreadsheet.add_table_header matchexp.label
            spreadsheet.add_table_body matchres[1]
          end
        end
      end
      entry.rewind
    end
  end

  pc.each_parsed_file do |file|
    if entry.full_name.match(/#{file.name}/)
      sp=SnapParser.new
      entry.read.split("\n").each do |line|
        if line.match(/^\.\.\.\.\./) and sp.previous_line.match(/^\.\.\.\.\./)
            sp.header=false
        end

        pattern_matched=false
        file.each_pattern do |pattern|
          if line.match(/^.....    #{pattern.name}/)
            sp.pattern=pattern
            spreadsheet.current_sheet=sp.pattern.sheet
            spreadsheet.add_summary line.sub(/^.....    /, '')
            pattern_matched=true
            break
          end
        end

        next if pattern_matched

        if sp.header
          #puts "here #{line}"
          if line.match(/^\.\.\.\.\./)
            sp.previous_line = line
            next
          end

          unless line.chomp.empty?
            if sp.pattern.skip_line and line.match(/#{sp.pattern.skip_line}/)
              next
            end
            if sp.pattern.separator.nil?
              spreadsheet.add_row [line]
            else
              spreadsheet.add_row line.split(sp.pattern.separator, sp.pattern.sep_num)
            end
          end
        end
        sp.previous_line = line
      end
      entry.rewind
    end
  end
end

output_file=File.basename(snap_file).sub(/_.*/, '')
spreadsheet.save "#{output_file}.xlsx"
