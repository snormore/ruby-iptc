# :vi:ts=2:sts=2:et:
require 'stringio'

require 'iptc/marker'
require 'iptc/marker_nomenclature'
require 'iptc/jpeg/marker'

module IPTC
  module JPEG
    # == Markers
    # All the known JPEG markers
    module Markers
      # == SOIMarker
      # The Start Of Image Marker
      class SOIMarker < Marker
        def valid?
          return read(5)=="JFIF\0"
        end
      end
      # == COMMarker
      # The COM Marker, contains comments
      class COMMarker < Marker
        attr_reader :content
        def parse
          l "COM Marker Parsed"
          @content = read(@size)
          @dirty = false

          @values['COM/COM']=@content
        end
        #            def []=(key,value)
        #                if @content != value
        #                    @content = value
        #                    @dirty = true
        #                end
        #            end
        def [](item)
          return @content
        end
      end
      # == The APP13Marker
      # The APP13 marker, know as the IPTC Marker
      # See also the IPTC::MarkerNomenclature.
      class APP13Marker < Marker
        def initialize(type, data)
          @header = "Photoshop 3.0\000"

          super(type, data)
          @prefix = "iptc"

        end
        def valid?
          return read(@header.length)==@header
        end

        SHORT = 1
        WORD = 2
        LONG = 4

        def word
          read(WORD).unpack("n")[0]
        end
        def long
          read(LONG).unpack("N")[0]
        end

        def parse
          l "APP13 marker parsed"
          @markers = Array.new

          # http://www.fileformat.info/format/psd/egff.htm
          # this one is much up to date.

          while @content.pos < @content.length - 1

            eight_bim = read(LONG)
            # Not a 8BIM packet. Go away !

            if eight_bim != "8BIM"
              l "At #{@content.pos}/#{@content.length} we were unable to find an 8BIM marker (#{eight_bim})."
              return
            end

            @bim_type = word()

            # Read name length and normalize to even number of bytes
            # Weird, always read 4 bytes
            padding = read(4)
            bim_size = word()

            # http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/Photoshop.html
            case @bim_type 

            when 0x0404 # IPTC
              content = StringIO.new(read(bim_size))

              while !content.eof?

                header = content.read(2).unpack("n")[0]

                # http://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/IPTC.html
                case header
                when 0x1C01
                  # skip the envelope
                  while !content.eof?
                    if content.read(1) == "\x1c"
                      content.pos = content.pos - 1
                      break
                    end
                  end
                when 0x1C02

                  type = content.read(1).unpack('c')[0]
                  size = content.read(2)
                  value = content.read(size.unpack('n')[0])

                  l "Found marker 0x#{type.to_s(16)}"
                  marker = IPTC::Marker.new(type, value)
                  k = @prefix+"/"+IPTC::MarkerNomenclature.markers(type.to_i).name
                  if @values.has_key?(k)
                    if @values[k].is_a?(Array)
                      @values[k] << value
                    else
                      @values[k] = [@values[k], value]
                    end
                  else
                      @values[k] = value
                  end
                  @markers << marker

                else
                  # raise InvalidBlockException.new("Invalid BIM segment #{header.inspect} in marker\n#{@original_content.inspect}")
                end
              end
            when 0x03ED
              hRes = long()
              hResUnit = word()
              widthUnit = word()
              vRes = long()
              vResUnit = word()
              heightUnit = word()
            else
              read(bim_size)
            end
            read(1) if bim_size%2 == 1
          end
          return @values
        end

        def [](item)
          return @values[item]
        end
        def to_binary
          marker = ""
          @markers.each do |value|
            marker += value.to_binary
          end

          marker =  @header+@bim_type+@bim_dummy+[marker.length].pack('n')+marker

          # build the complete marker
          marker = super(marker)

          return marker
        end
        def properties
          return IPTC::TAGS.values.sort
        end
        def set(property, value)
          numerical_tag = IPTC::TAGS.index(property)
          if numerical_tag!=nil
          else
            throw InvalidPropertyException.new("Invalid property #{property} for IPTC marker")
          end
          marker = IPTC::Marker.new(numerical_tag, value)
          @markers << marker
        end
      end
      class InvalidPropertyException < Exception
      end
      # == The APP0Marker
      # Contains some useful JFIF informations about the current
      # image.
      class APP0Marker < Marker
        def initialize type, data 
          super type, data
        end
        def valid?
          if read(5)!="JFIF\0"
            return false
          end
          return true
        end
        def parse

          @values = {
            'APP0/revision'=>read(2).unpack('n')[0],
            'APP0/unit' => read(1),
            'APP0/xdensity' => read(2).unpack('n')[0],
            'APP0/ydensity' => read(2).unpack('n')[0],
            'APP0/xthumbnail' => read(1).unpack('c')[0],
            'APP0/ythumbnail' => read(1).unpack('c')[0]
          }
        end
        def [](item)
          return @values[item]
        end
      end
    end
  end
end

if $0 == __FILE__
  if ARGV[0]==nil
    puts "No file given. Aborting."
    exit
  end

  require 'iptc/jpeg/image'


  # read the image
  im = IPTC::JPEG::Image.new(ARGV[0])

  puts "Done reading #{ARGV[0]}"

  im.values.each do |item|
    puts "#{item.key}\t#{item.value}"
  end
  
end
