#!/usr/bin/env ruby

require "pathname"
require "optparse"

require_relative "./lib/util"
require_relative "./lib/gles3_driver"

class App
	attr_reader :script_dir
	attr_reader :repo_dir

    attr_reader :gl_h

    attr_reader :data

	def main
		@script_dir = Pathname(__FILE__).expand_path.parent
		@repo_dir = script_dir.parent

        @data = nil

		optp = OptionParser.new
		optp.on("--gl_h path") {|x| @gl_h = Pathname(x) }
		optp.parse!(ARGV)

        gles3_driver = Gles3Driver.new
        gles3_driver.run(gl_h, 
            repo_dir + "src/pge/gl", 
            repo_dir + "js/src/pge/gl")
	end
end

app = App.new
app.main
