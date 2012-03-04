require 'logger'

require 'iptc/multiple_hash'
require 'iptc/jpeg/marker_headers'

module IPTC
  module JPEG
    class Image
      # Array of MultipleHashItem objects
      attr_reader :values

      # creates a JPEG image from a data blob and does a "quick" load (Only the metadata
      # are loaded, not the whole file).      
      def Image.from_blob blob, quick=true
        return Image.new("Data blob", blob, true)
      end
      # creates a JPEG image from a file and does a "quick" load (Only the metadata
      # are loaded, not the whole file).
      def Image.from_file filename, quick=true
        content = nil
        raise "File #{filename} not found" if !File.exists?(filename)
        File.open(filename) do |f|
          f.binmode
          content = f.read
        end
        return Image.new(filename, content, quick)        

      end
      # Real constructor. Should never be called directly
      # take a "data name" that is used for error reporting.
      def initialize data_name, content, quick=true
        @logger = Logger.new(STDOUT)
        @logger.datetime_format = "%H:%M:%S"
        @logger.level = $DEBUG?(Logger::DEBUG):(Logger::INFO)
      
        @data_name = data_name
        @content = content

        @position = 0
      
        if MARKERS[read(2)]!="SOI"
          raise  NotJPEGFileException.new("Not JPEG data: #{@data_name}")
        end
      
        @markers = Array.new()
      
        begin
      
          catch(:end_of_metadata) do
            while true
              @markers << read_marker
            end
          end
        
        rescue Exception=>e
          @logger.info "Exception in data #{@data_name}:\n"+e.to_s
          raise e
        end
        # Markers all read
        # move back
        seek(-2)
      
        # in full mode, read the rest
        if !quick
          @data = read_rest
        end
      
        @values = MultipleHash.new
      
        @markers.each do |marker|
          # puts "processing marker: #{marker.inspect}"
          marker.parse
          # puts marker.valid?
          @values.add(marker, marker.values)
        end
      end
    
      def read(count)
        @position += count
        return @content[@position-count...@position]
      end
      def seek(count)
        @position += count
      end
    
      def l message
        @logger.debug message
      end
    
      # write the image to the disk
      def write data_name
        f = File.open(data_name,"wb+")
        f.print "\xFF\xD8"
      
        @markers.each do |marker|
          f.print marker.to_binary
        end
        f.print @data.to_binary
        f.close
      
      end
    
      def read_marker
        type = read(2)
        # finished reading all the metadata
        throw :end_of_metadata if MARKERS[type]=='SOS'
        size = read(2)
        data = read(size.unpack('n')[0]-2)
      
        return Marker.NewMarker(MARKERS[type], type+size+data, @logger)
      end
      def read_rest
        rest = @content[@position..-1]
        return Marker.new("BIN",rest)
      end
			def to_s
				"Image #{@data_name}:\n" +
				@markers.map{ |m| m.to_s  }.join("\n")
			end
    
    end
  end
end
