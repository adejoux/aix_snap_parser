AIX SNAP report
===========

This tool take a uncompressed aix snap file and generate a excel file to have a simple report of system configuration.
It's not a tool planned for problem determination.

Install
-------

The following instructions will help you to install this Rails application on AIX.

1) clone git repository
    # git clone https://github.com/adejoux/aix_snap_report.git

2) install if needed bundler
    # gem install bundler

3) install gems

    # cd aix_snap_report
    # bundle install


Usage
--------

    Usage: analyse_snap.rb [-f snap_file] [-h] [-v]
        -f, --file=snap                  snap file
        -h, --help                       Display this screen
        -v, --version                    Display tool version


Copyright
---------

The code is licensed as GNU AGPLv3. See the LICENSE file for the full license.

Copyright (c) 2013 Alain Dejoux <adejoux@krystalia.net>
