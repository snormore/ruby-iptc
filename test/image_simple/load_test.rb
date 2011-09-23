require 'test/unit'
$: << "../../lib"
require 'iptc'

class Image_Test < Test::Unit::TestCase
	def test_markers
		assert_equal(58, IPTC::MarkerNomenclature.instance.markers_count)
	end
	def test_loading
		folder_name = File.dirname(__FILE__)
		i = IPTC::JPEG::Image.new( File.join(folder_name, 'flickr-2662825452-original.jpg' ) )
	end
end


