require 'vips'
require 'csv'

module Vips
  class Image
    def scale_range 
      min = self.min
      max = self.max
      (self - min)/(max-min) * 255
    end
  end
end

class Histogram
  def initialize bgim 
    @bg  = bgim 
    @bg_hue = bgim
    @pv = bgim.max
    @bg = bgim.min
  end
  
  def bg_has_two_colors? 
    
  end

  def histogram im
    im.to_a
  end
end
 
class Crop_image
  @@ground = [0,0,0] 
  attr_accessor :rgb, :hsv, :name, :dir, :mask, :lab
  def initialize fn, dir='.', maskpath=nil, scale=1, blur=nil
    im = Vips::Image.new_from_file fn 
    @dir = dir 
    @name = fn.split('/').last.split('.').first
    im = im.gaussblur blur if blur
    @rgb = im.resize(scale)
    @hsv = @rgb.sRGB2HSV
    @lab = @rgb.colourspace :lab
    @lch = @rgb.colourspace :lch
    @mask = maskpath && Vips::Image.new_from_file(maskpath).resize(scale)
    @mask = @mask.flatten if @mask && @mask.bands == 4
  end

  def split_rgb
    @rgb_split ||= @rgb.bandsplit
    g =  @rgb_split[1] 
    r =  @rgb_split[0]
    b =  @rgb_split[2]
    [r,g,b]
  end
  
  def split_lab
    @lab_split ||= @lab.bandsplit
    l =  @lab_split[0] 
    a =  @lab_split[1]
    b =  @lab_split[2]
    [l,a,b]
  end
  
  def split_lch
    @lch_split ||= @lch.bandsplit
    l =  @lch_split[0] 
    c =  @lch_split[1]
    h =  @lch_split[2]
    [l,c,h]
  end

  def split_hsv
    @hsv_split ||= @hsv.bandsplit
    h =  @hsv_split[0]
    s =  @hsv_split[1] 
    v =  @hsv_split[2]
    [h,s,v]
  end

  def ndi
    r = split_rgb[0]
    g = split_rgb[1] 
    (((g-r)/(g+r))+1) * 128
  end

  def exg
    r = split_rgb[0]
    g = split_rgb[1] 
    b = split_rgb[2]
    g * 2 - r - b
  end

  def exr
    r = split_rgb[0]
    g = split_rgb[1] 
    b = split_rgb[2]
    r * 1.3 - g
  end

  def cive 
    r = split_rgb[0]
    g = split_rgb[1] 
    b = split_rgb[2]
    r * 0.441  - g * 0.811  + b * 0.385  + 19.78745
  end

  def exgr 
    exg - exr
  end

  def save_all_to_file
    Dir.exist?(@dir) || Dir.mkdir(@dir)
    fname = File.join(@dir, @name)
    i = 0
    @rgb.scale_range.write_to_file File.join(@dir, "#{i}_rgb.png") 
    split_rgb[0].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_r.png") 
    split_rgb[1].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_g.png")
    split_rgb[2].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_b.png")
    @hsv.write_to_file File.join(@dir, "#{i+=1;i}_hsv.png")
    split_hsv[0].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_h.png")
    split_hsv[1].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_s.png")
    split_hsv[2].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_v.png")
    ndi.scale_range.write_to_file File.join(@dir, "#{i+=1;i}_ndi.png")
    exg.scale_range.write_to_file File.join(@dir, "#{i+=1;i}_exg.png")
    exr.scale_range.write_to_file File.join(@dir, "#{i+=1;i}_exr.png")
    cive.scale_range.write_to_file File.join(@dir, "#{i+=1;i}_cive.png")
    exgr.scale_range.write_to_file File.join(@dir, "#{i+=1;i}_exgr.png")
    split_lab[0].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_l.png")
    split_lab[1].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_a.png")
    split_lab[2].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_b.png")
    split_lch[0].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_lch_l.png")
    split_lch[1].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_lch_c.png")
    split_lch[2].scale_range.write_to_file File.join(@dir, "#{i+=1;i}_lch_h.png")
  end
  #com1 and com2 fom paper A New Vegetation Segmentation Approach ... are not implemented, what is VEG in equation
  def get_plant_mask
    @plant_mask ||= (((mask != @@ground).bandor) == 255)/255
  end
  def get_ground_mask
    @ground_mask ||= (((mask == @@ground).Colourspace("b-w")[0]) == 255)/255
  end
  def get_plant_im
    @plant_mask ||= get_plant_mask 
    (@rgb * @plant_mask).bandjoin(@plant_mask > 0)
  end
  def plant_hist bim=nil
    puts 'Please provide an annotation mask!' unless mask
    bim = bim || @rgb
    @ground_mask ||= get_ground_mask 
    @plant_mask ||= get_plant_mask 
    {plant: (bim * @plant_mask + @ground_mask * 256).hist_find.to_a.first[0..255],
     ground: (bim * @ground_mask + @plant_mask * 256).hist_find.to_a.first[0..255]}
  end
  def plant_hist_csv bim=nil
    bim = bim || @rgb
    hist = plant_hist bim
    csv = [['band','class',*(0..255)]]
    bim.bands.times do |bi|
      csv << [bi,'plant',*hist[:plant].map{|e| e[bi]}]
      csv << [bi,'ground',*hist[:ground].map{|e| e[bi]}]
    end
    csv.reduce(''){|s,e| s+=e.to_csv;s}
  end
end

#fn = ARGV.first 
#imn = fn.split('/').last.split('.').first
#
#cim = Crop_image.new 'image',fn.split('/').last.split('.').first
#cim.save_all_to_file

#hist = im.hist_find.bandsplit.map.with_index{|imb, i| ["RGB#{i}", imb.to_a].flatten}
#hist += im.sRGB2HSV.hist_find.bandsplit.map.with_index{|imb, i| ["HSV#{i}", imb.to_a].flatten}
#puts hist[0][1..-1].reduce(&:+)
#File.write("hist.csv", hist.map(&:to_csv).join)
#
##convert image into bw image
#(((im.Colourspace("b-w")[0] > 0)/255) * plant).bandjoin((im.Colourspace("b-w")[0] > 0).write_to_file 'test_multiply.jpg'
