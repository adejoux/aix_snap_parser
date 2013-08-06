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
require 'advanced_parser'
require 'spreadsheet'
require 'pattern'
require 'parsed_file'
require 'matchexp'
require 'matched_file'
require 'parser_config'
require 'snap_parser'

version=0.5

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
  puts "Usage: analyse_snap.rb [-f snap_file] [-c config_file] [-h] [-v]"
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
spreadsheet.add_sheet('general')
#create sheet for each file in config
pc.sheets.each do |sheet|
  spreadsheet.add_sheet(sheet)
end




adapters=Hash.new{|hash, key| hash[key] = Hash.new}
disks=Hash.new{|hash, key| hash[key] = Hash.new}
system={}

Gem::Package::TarReader.new(File.open(snap_file)).each do |entry|

  pc.each_full_file do |file|
    if entry.full_name.match(/#{file.name}/)
      puts "Processing file : #{entry.full_name}"
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
      puts "Processing file : #{entry.full_name}"
      next if file.is_excluded? entry.full_name

      spreadsheet.current_sheet=file.sheet
      spreadsheet.add_summary File.basename(entry.full_name)
      spreadsheet.set_table

      entry.read.split("\n").each do |line|
        file.each_matchexp do |matchexp|
          matchres=line.match(matchexp.name)
          unless matchres.nil?
            if file.header?
              spreadsheet.add_table_header matchexp.label
            end

            spreadsheet.add_table_body matchres[1]
            if matchexp.new_row?
              spreadsheet.add_body_row
              file.no_header!
            end
          end
        end
      end
      entry.rewind
    end
  end

  pc.each_parsed_file do |file|
    if entry.full_name.match(/#{file.name}/)
      puts "Processing file : #{entry.full_name}"
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
            spreadsheet.add_summary (pattern.label || pattern.name), line.sub(/^.....    /, '')
            pattern_matched=true
            break
          end
        end

        next if pattern_matched

        if sp.header
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

  pc.each_advanced_parser_section("network") do |parser|
    if entry.full_name.match(/#{parser.name}/)
      current_adapter=""
      media_adapter=""
      puts "Processing parser : #{entry.full_name}"
      next if parser.is_excluded? entry.full_name

      entry.read.split("\n").each do |line|
        parser.each_matchexp do |matchexp|
          matchres=line.match(matchexp.name)
          unless matchres.nil?
            case matchexp.label
              when "adapter" then current_adapter=matchres[1]
              when "slot" then adapters[current_adapter]["slot"]=matchres[1]
              when 'description' then adapters[current_adapter]["description"]=matchres[1]
              when 'mac' then adapters[current_adapter]["mac"]=matchres[1]
              when 'serial' then system["serial"]=matchres[1]
              when 'model' then system["model"]=matchres[1]
              when 'media_adapter' then media_adapter=matchres[1]
              when 'media_selected' then adapters[media_adapter]['media_selected']=matchres[1]
              when 'media_running' then adapters[media_adapter]['media_running']=matchres[1]
              when 'interface'
                adapter=matchres[1].sub(/en/, 'ent')
                adapters[adapter]['mtu']=matchres[2]
                adapters[adapter]['ip']=matchres[3]
            end
          end
        end
      entry.rewind
      end
    end
  end

    pc.each_advanced_parser_section("disk") do |parser|
    if entry.full_name.match(/#{parser.name}/)
      current_adapter=""
      current_disk=""
      current_cuat_disk=""
      cuat_flag=false
      puts "Processing parser : #{entry.full_name}"
      next if parser.is_excluded? entry.full_name

      entry.read.split("\n").each do |line|
        parser.each_matchexp do |matchexp|
          matchres=line.match(matchexp.name)
          unless matchres.nil?
            case matchexp.label
              when "disk" then current_disk=matchres[1]
              when "cuat_disk" then current_cuat_disk=matchres[1]
              when "unique_flag" then cuat_flag=true
              when "unique_id"
                if cuat_flag
                  disks[current_cuat_disk]["unique_id"]=matchres[1]
                  cuat_flag=false
                  current_cuat_disk=""
                end
              when "pvid" then disks[current_disk]["pvid"]=matchres[1]
              when "unique_id" then disks[current_disk]["unique_id"]=matchres[1]
              when 'lun_id' then disks[current_disk]["lun_id"]=matchres[1]
              when 'description'
                disk=matchres[1]
                disks[disk]['location']=matchres[2]
                disks[disk]['description']=matchres[3]
            end
          end
        end
      entry.rewind
      end
    end
  end
end
spreadsheet.current_sheet="general"

spreadsheet.add_summary "system"

spreadsheet.add_row ['partition',
                     'model',
                     'serial',
                    ], "thead"

server=File.basename(snap_file).sub(/_.*/, '')
spreadsheet.add_row [ server,
                      system["model"],
                      system["serial"],
                    ]

spreadsheet.add_summary "network"

spreadsheet.add_row ['adapter',
                     'slot',
                     'description',
                     'mac address',
                     'mtu',
                     'ip',
                     'selected speed',
                     'running speed'
                   ], "thead"


adapters.each_key do |adapter|
  spreadsheet.add_row [ adapter,
                        adapters[adapter]["slot"],
                        adapters[adapter]["description"],
                        adapters[adapter]["mac"],
                        adapters[adapter]['mtu'] || "N/A",
                        adapters[adapter]['ip']  || "N/A",
                        adapters[adapter]['media_selected'],
                        adapters[adapter]['media_running']
                         ]
end
spreadsheet.add_summary "disk"
spreadsheet.add_row ['disk',
                     'pvid',
                     'lun_id',
                     'unique_id',
                     'location',
                     'description'
                   ], "thead"
disks.each_key do |disk|
  spreadsheet.add_row [ disk,
                        disks[disk]["pvid"] || "N/A",
                        disks[disk]["lun_id"] || "N/A",
                        disks[disk]["unique_id"] || "N/A",
                        disks[disk]['location'] || "N/A",
                        disks[disk]['description']  || "N/A"
                         ]
end
output_file=File.basename(snap_file).sub(/_.*/, '')
spreadsheet.save "#{output_file}.xlsx"
puts "Output file generated : #{output_file}.xlsx"
