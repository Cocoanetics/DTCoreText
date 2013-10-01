#!/usr/bin/env ruby

require 'etc'
require 'fileutils'
require 'find'
require 'optparse'

excludedFolders = []

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on('-e', '--exclude FOLDER', 'Folder to exclude') do |v|
     excludedFolders << v
  end

end.parse!(ARGV)

workingDir = Dir.getwd
derivedDataDir = "#{Etc.getpwuid.dir}/Library/Developer/Xcode/DerivedData/"

outputDir = workingDir + "/gcov"
#FileUtils.rm_r outputDir
FileUtils.mkdir outputDir 

GCOV_SOURCE_PATTERN = Regexp.new(/Source:(.*)/)

Find.find(derivedDataDir) do |file|
  if file.match(/\.gcda\Z/)
      #get just the folder name
      gcov_dir = File.dirname(file)

      puts "\nINPUT: #{file}"

      #process the file
#      system "gcov", file, "-o", gcov_dir
      
      result = %x( gcov '#{file}' -o '#{gcov_dir}' )
      
      if (!result)
        break
      end
      
      # filter the resulting output
      Dir.glob("*.gcov") do |gcov_file|
        
        firstLine = File.open(gcov_file).readline
        match = GCOV_SOURCE_PATTERN.match(firstLine)
        
        if (match)
          source_path = match[1]

          if (source_path.start_with? workingDir)
            
            # cut off absolute working dir to get relative source path
            relative_path = source_path.slice(workingDir.length+1, source_path.length)
            
            # get the path components
            path_comps = relative_path.split(File::SEPARATOR)
            
            if (excludedFolders.include?(path_comps[0]))
              puts "   - ignore #{relative_path} (excluded via option)"
              FileUtils.rm gcov_file
            else
              puts "   - process: #{relative_path}"
              FileUtils.mv(gcov_file, outputDir)
            end
          else
            puts "   - ignore: #{gcov_file} (outside source folder)"
            FileUtils.rm gcov_file
          end
        end
      end
   end
end

#change back to working directory
Dir.chdir workingDir

#call the coveralls, exclude some files
system 'coveralls', '-e', 'Externals', '-e', 'Test', '-e', "Demo"

#clean up
FileUtils.rm_rf outputDir
