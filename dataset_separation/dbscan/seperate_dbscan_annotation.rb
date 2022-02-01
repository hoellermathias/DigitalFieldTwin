require 'vips'
require 'yaml'


class ColorSeperator
  def run_on_dir dir
    a_dir = 'dbscan'
    i_dir = 'images'
    n_dir = 'dbscan_plants'
    i = 0
    Dir.mkdir File.join(n_dir) unless Dir.exists? File.join(n_dir)
    a_files = Dir.glob(File.join(dir ,a_dir ,'*.png')).sort
    i_files = Dir.glob(File.join(dir, i_dir ,'*.png')).sort
    puts a_files
    puts i_files
    puts "size of directories annotation files != image files" unless i_files.size == a_files.size
    a_files.each_with_index do |fn, idx|
      puts "processing #{fn}"
      n = fn.split('/').last

      ifn = i_files.find{|a| a.split('/').last.split('_').first == fn.split('/').last.split('_').first}
      next unless ifn
      puts "processing #{ifn}"
      im = Vips::Image.new_from_file ifn
      ann_im = Vips::Image.new_from_file fn
      ann_im_bw = ann_im.colourspace(:"b-w")
      
      #store size of plant in relation to the image 
      size = im.size

      max_val = ann_im_bw.max
      #ann_im_bw.write_to_file("mask.png")
      
      while max_val > 0
        max_mask = (ann_im_bw == max_val)
        crop_params = max_mask.find_trim(background: 0)
        #puts crop_params
        cim = im.crop(*crop_params)
        csize = cim.size
        width_ratio = size.first / csize.first
        plant_mask = (((max_mask*ann_im != 0).bandor) == 255)/255
        cplant_mask = plant_mask.crop(*crop_params)

        (cim * cplant_mask).bandjoin(cplant_mask > 0).write_to_file(File.join(n_dir, "#{i}_#{max_val < 128 && 'weed' || 'crop'}_#{width_ratio}.png"))
        i += 1
        ann_im_bw -= (max_mask / max_mask.max) * max_val
        max_val = ann_im_bw.max
        #puts '---max'
        #puts ann_im_bw.max
      end
    end
  end
end


if __FILE__ == $0
  require 'optparse'
  options = {}
  op = OptionParser.new do |opts|
    opts.banner = "Dataset Color Separator for B-W DBSCAN annotation masks"
    opts.on("-dV", "--dir=V", "Path to a directory containing 'dbscan', 'images' and 'annotations' directory.")
  end
  op.parse!(into: options)
  options.empty? && !puts(op) && return
  s = ColorSeperator.new
  s.run_on_dir options[:dir]
end