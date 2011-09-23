require 'singleton'
require 'iptc/marker'

require 'yaml'

module IPTC
  class MarkerNomenclature
    include Singleton
    def MarkerNomenclature.markers(id)
      return MarkerNomenclature.instance.markers(id)
    end
		def markers_count
			@markers.keys.length
		end 
    def markers(id)
      if @markers.has_key?(id)
        return @markers[id]
      else
        return @markers[-1]
      end
    end
    
    def populate
      @markers = {}

      marker = Struct.new(:iid, :name, :description)
      
      m = marker.new
      m.name = "Unknown marker"
      m.iid = -1
      @markers[-1] = m
              
      NOMENCLATURE.each_line do |line|
          m = marker.new
          m[:name], m[:description], m[:iid] = line.split(/\t/)
          m[:iid] = m[:iid].to_i
          @markers[m.iid] = m
      end
    end
		def benchmark
			require 'benchmark'
			Benchmark.bm(40) do |x|
				x.report("Populate Markers") { 1000.times do populate(); end }
			end
		end
  end
end
IPTC::MarkerNomenclature.instance.populate
