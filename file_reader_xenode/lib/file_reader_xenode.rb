# Copyright Nodally Technologies Inc. 2013
# Licensed under the Open Software License version 3.0
# http://opensource.org/licenses/OSL-3.0

require 'fileutils'

class FileReaderXenode
  include XenoCore::NodeBase
  
  def startup
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    
    # write the config out to the log
    do_debug("#{mctx} - config: #{@config.inspect}", true)
    
    # get where to look for the file
    # resolve_sys_dir() will replace any "tokens" (@this_node, @this_server)
    # @this_node will be a file local to the instance of this xenode
    # @this_server will be a file local to all xenodes 
    @file_dir_path = resolve_sys_dir(@config[:dir_path])
    
    # file_mask of the file to read i.e. '*.txt'
    @file_mask = @config[:file_mask]
    
    # just grab the full file path without reding the
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
      
        # this will log under the xenode's instance directory 
        # if debug is set to true in the config
        do_debug("#{mctx} - looking for files matching: #{fp}")
      
        files = Dir.glob(fp)
    
        # loop through the files
        files.each do |f|
      
          # create a new message
          msg = XenoCore::Message.new
      
          if File.exist?(f)
            # write the file_path to the message's context
            # so we have it down stream
            # context should last across nodes
            # i.e. a node can add to the context but should not delete it
        
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
            # if you have mutliple instaces of this xenode in your xenoflow.
            FileUtils.mv(f, "#{f}.bak") if File.exist?(f) 
          end
      
        end
    
      end
      
    rescue Exception => e
      # this will be logged in the xenode instances's log directory
      catch_error("#{mctx} - ERROR #{e.inspect}")
    end
    
  end
  
  def shutdown
    mctx = "#{self.class}.#{__method__} [#{@xenode_id}]"
    # this wn't get logged unless debug is true in the config
    do_debug("#{mctx} - xenode was shutdown")
  end
  
end

