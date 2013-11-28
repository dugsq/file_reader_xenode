# Copyright Nodally Technologies Inc. 2013
# Licensed under the Open Software License version 3.0
# http://opensource.org/licenses/OSL-3.0

# Version 0.2.0
#
# File Reader Xenode monitors specific files in a local directory, fetches the files and pass them downstream to its children file by file.
#
# Configuration file options:
#   loop_delay: defines number of seconds the Xenode waits before running the Xenode process. Expects a float. 
#   enabled: determines if this Xenode process is allowed to run. Expects true/false.
#   debug: enables extra debug messages in the log file. Expects true/false.
#   dir_path: defines the local path to save the file. Expects a string.
#   file_mask: defines the file mask to use to identify files to fetch. Expects a string.
#   path_only: if set to true, will fetch the full file path without reading the file contents into the message data.
#
# Example Configuration File:
#   enabled: true
#   loop_delay: 60
#   debug: false
#   dir_path: "/temp/outbound"
#   file_mask: "*.txt"
#   path_only: true
#
# Example Input:  The File Reader Xenode does not expect nor handle any input.
#
# Example Output:     
#   msg.context: [{:file_path=>"/temp/hello.txt"}] 
#   msg.data:  "String contains actual file content for hello.txt."
#

require 'fileutils'

class FileReaderXenode
  include XenoCore::XenodeBase
  
  def startup
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    
    # write the config out to the log
    do_debug("#{mctx} - config: #{@config.inspect}", true)
    
    # get where to look for the file
    # resolve_sys_dir() will replace any "tokens" (@this_node, @this_server)
    # @this_node will be a file local to the instance of this Xenode
    # @this_server will be a file local to all Xenodes 
    @file_dir_path = resolve_sys_dir(@config[:dir_path])

    # file_mask of the file to read i.e. '*.txt'
    @file_mask = @config[:file_mask]
    
    # just grab the full file path without reading the
    # file contents into the message data if path_only is true
    @path_only = @config[:path_only]
    
    do_debug("#{mctx} - file_dir_path: #{@file_dir_path.inspect} file_mask: #{@file_mask.inspect} path_only: #{@path_only.inspect}", true)
  end
  
  def process
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    
    do_debug("#{mctx} called.")
    
    begin
      # this method gets called every @loop_delay seconds
      if @file_dir_path && @file_mask
      
        fp = File.join(@file_dir_path, @file_mask)
      
        # check if path exists
        FileUtils.mkdir_p(@file_dir_path) unless Dir.exist?(@file_dir_path)
      
        # this will log under the Xenode's instance directory 
        # if debug is set to true in the config
        do_debug("#{mctx} - looking for files matching: #{fp}")
      
        files = Dir.glob(fp)
    
        # loop through the files
        files.each do |f|
      
          # create a new message
          msg = XenoCore::Message.new
      
          if File.exist?(f)
            # Write the file_path to the message's context so we have it 
            # down stream. Context should be shared across Xenodes.
            # i.e. A Xenode can add to the context but should not delete it
        
            # force logging of this message (write out the file_path)
            # this will always log even if debug is false in the config
            # as the true value forces the debug write
            do_debug("#{mctx} - file added to context: #{f}", true)
            msg.context ||= {}
            msg.context[:file_path] = f
        
            unless @path_only
              # read the file's data into the message data
              do_debug("#{mctx} - reading data from file: #{f}", true)
              msg.data = File.read(f)
            end
        
            # write the message to all the children of this node
            write_to_children(msg)
            
          end
      
          # rename the file so it doesn't get read again
          do_debug("#{mctx} - file #{f} exists: #{File.exist?(f)}")
          if File.exist?(f)
            do_debug("#{mctx} - backing up read file: #{f}", true)
            # yes it could have been deleted between first check and this one...
            # or another instance of this Xenode could have already processed it
            # if you have mutliple instaces of this Xenode in your xenoflow.
            FileUtils.mv(f, "#{f}.bak") if File.exist?(f) 
          end
      
        end
    
      end
      
    rescue Exception => e
      # this will be logged in the Xenode instances's log directory
      catch_error("#{mctx} - ERROR #{e.inspect}")
    end
    
  end
  
  def shutdown
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    # this wn't get logged unless debug is true in the config
    do_debug("#{mctx} - xenode was shutdown")
  end
  
end

