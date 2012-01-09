require 'test/unit'
$: << "../../lib"
require 'iptc'

class Image_Test < Test::Unit::TestCase
  def test_file_loading
    folder_name = File.dirname(__FILE__)
    i = IPTC::JPEG::Image.from_file( File.join(folder_name, 'flickr-2662825452-original.jpg' ) )
    assert_equal(58, IPTC::MarkerNomenclature.instance.markers_count)
  end
  def test_blob_loading
    folder_name = File.dirname(__FILE__)
    data = File.open( File.join(folder_name, 'flickr-2662825452-original.jpg' )).binmode.read
    i = IPTC::JPEG::Image.from_blob( data )
    assert_equal(58, IPTC::MarkerNomenclature.instance.markers_count)
  end
end

class Image2_Test < Test::Unit::TestCase
  def test_file_loading
    folder_name = File.dirname(__FILE__)
    i = IPTC::JPEG::Image.from_file( File.join(folder_name, 'from-Ludovic-Peron.jpg' ) )
  end
end


