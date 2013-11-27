File-Reader-Xenode
==================

**File Reader Xenode** monitors specific files in a local directory, fetches the files and pass them downstream to its children file by file.

###Configuration file options:
* loop_delay: defines number of seconds the Xenode waits before running the Xenode process. Expects a float. 
* enabled: determines if this Xenode process is allowed to run. Expects true/false.
* debug: enables extra debug messages in the log file. Expects true/false.
* dir_path: defines the local path to save the file. Expects a string.
* file_mask: defines the file mask to use to identify files to fetch. Expects a string.
* path_only: if set to true, will fetch the full file path without reading the file contents into the message data.

###Example Configuration File:
* enabled: true
* loop_delay: 60
* debug: false
* dir_path: "/temp/outbound"
* file_mask: "*.txt"
* path_only: true

###Example Input:   
* The File Reader Xenode does not expect nor handle any input.

###Example Output:     
* msg.context: [{:file_path=>"/temp/hello.txt"}] 
* msg.data:  "String contains actual file content for hello.txt."
