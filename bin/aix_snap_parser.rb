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
snap_dir=""

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: analyse_snap.rb [-f snap_file] [-c config_file] [-h] [-v]"

  opts.on('-f snap', '--file=snap', 'snap file') do |v|
    snap_file = v
  end

  opts.on('-d snap_directory', '--directory=snap', 'snap directory') do |v|
    snap_dir = v
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

unless File.file?(snap_file) or File.directory?(snap_dir)
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

#create sheet for each file in config
spreadsheet.add_sheet('network')


spreadsheet.current_sheet="network"
spreadsheet.set_table
spreadsheet.add_row ['partition',
                     'model',
                     'serial',
                     'adapter',
                     'slot',
                     'description',
                     'mac address',
                     'mtu',
                     'ip',
                     'selected speed',
                     'running speed'
                   ]

adapters=Hash.new{|hash, key| hash[key] = Hash.new}
system={}

snap_list=Dir.entries(snap_dir).select {|entry| entry.match(/snap.pax$/) }
snap_list.each do |snap|
  puts "SNAP FILE: snap"
  snap_file=File.join(snap_dir, snap)
  Gem::Package::TarReader.new(File.open(snap_file)).each do |entry|
    pc.each_matched_file do |file|
      if entry.full_name.match(/#{file.name}/)
        current_adapter=""
        media_adapter=""
        puts "Processing file : #{entry.full_name}"
        next if file.is_excluded? entry.full_name

        entry.read.split("\n").each do |line|
          file.each_matchexp do |matchexp|
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
  end
  spreadsheet.current_sheet='network'
  server=File.basename(snap_file).sub(/_.*/, '')
  adapters.each_key do |adapter|
    spreadsheet.add_row [ server,
                          system["model"],
                          system["serial"],
                          adapter,
                          adapters[adapter]["slot"],
                          adapters[adapter]["description"],
                          adapters[adapter]["mac"],
                          adapters[adapter]['mtu'] || "N/A",
                          adapters[adapter]['ip']  || "N/A",
                          adapters[adapter]['media_selected'],
                          adapters[adapter]['media_running']
                           ]
  end
end

#puts adapters.inspect
#puts system.inspect
spreadsheet.save "report.xlsx"
puts "Output file generated : report.xlsx"
