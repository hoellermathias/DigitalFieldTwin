#this class extracts the annotated parts of an image (plants) and stores them as separate images
#imput: yaml file with annotation polygone, mask colored by classes, original image

require 'vips'
require 'yaml'

module Vips
  class Image
    def scale_range 
      min = self.min
      max = self.max
      (self - min)/(max-min) * 255
    end
  end
end

class Seperator
  #find extremas min_x, min_y, max_x, max_y
  # {"x"=>
  #   [810.0,
  #   841.0,
  #   846.0,
  #   926.0,
  #   956.0,
  #   1054.0,
  #   1175.0,
  #   1161.0,
  #   1010.0,
  #   971.0,
  #   948.0,
  #   937.0,
  #   909.0,
  #   837.0],
  # "y"=>
  #   [225.0,
  #   234.0,
  #   266.0,
  #   338.0,
  #   408.0,
  #   422.0,
  #   317.0,
  #   230.0,
  #   126.0,
  #   114.0,
  #   130.0,
  #   167.0,
  #   170.0,
  #   169.0]
  # } 
  def get_expremas p
    { 
      xmin: p["x"].min,
      xmax: p["x"].max, 
      ymin: p["y"].min, 
      ymax: p["y"].max
    }
  end

  #input: 
  #  - list of points (x, y)
  #  - image
  #output: 
  #  - cropped image parameters (min_x, min_y, max_x, max_y)
  #  - extraced image mask (bw image with dimension max_x - min_x, max_y - min_y)
  def extract_polygone points, im 
    extremas = get_expremas points
    w = extremas[:xmax] - extremas[:xmin]
    h = extremas[:ymax] - extremas[:ymin]
    #remove outside area
    im = im.crop(extremas[:xmin], extremas[:ymin], w, h)
    xyz = Vips::Image.xyz(w,h)

    #fit points of polygone to new image size
    points["x"].length.times do |i|
      points["y"][i] -= extremas[:ymin]
      points["x"][i] -= extremas[:xmin]
    end

    intersect_x = lambda {|p,v0,v1| (p-v0)/(v1-v0)}
    y = 1
    x = 0
    sum_im = nil
    np = points['x'].length
    np.times do |i|
      i_1 = i+1 == np ? 0 : i + 1 
      # p np
      # p i
      # p i_1
      # p [points['y'][i], points['y'][i_1]]
      # p [points['x'][i], points['x'][i_1]]
      # https://wrf.ecse.rpi.edu/Research/Short_Notes/pnpoly.html
      upward_crossing  = (xyz[y] >= points['y'][i]).boolean(xyz[y] < points['y'][i_1], :and)
      #upward_crossing.write_to_file "#{i}_upward_crossing.png"
      downward_crossing = (xyz[y] < points['y'][i]).boolean(xyz[y] >= points['y'][i_1], :and)
      #downward_crossing.write_to_file "#{i}_downward_crossing.png"
      intersect = (xyz[x] >= intersect_x.(xyz[y],points['y'][i],points['y'][i_1]) * (points['x'][i_1] - points['x'][i]) + points['x'][i]) 
      #intersect.write_to_file "#{i}_intersect.png"
      mask = (upward_crossing.boolean(downward_crossing, :or)).boolean(intersect[0], :and)#.invert()
      sum_im = sum_im && sum_im.boolean(mask, :eor) || mask
      #mask.write_to_file "#{i}_mask.png"
      #sum_im.write_to_file "#{i}_sum_im.png"
      #[mask, sum_im].each_with_index{|ri, ti| p ri; ri.write_to_file "#{(ti+1)*(i+1)}.png"}
    end
    [sum_im, [extremas[:xmin], extremas[:ymin], w, h]]
  end

  def run_on_dir dir
    a_dir = 'annotations'
    i_dir = 'images'
    n_dir = 'plants'
    idx = 0
    p dir
    p Dir.glob(File.join(dir, a_dir ,'*.png'))
    #Dir.chdir dir
    Dir.mkdir n_dir unless Dir.exists? n_dir
    Dir.glob(File.join(dir, a_dir ,'*.png')).each do |fn|
      puts "processing #{fn}"
      n = fn.split('/').last.split('_').first
      yfn = "#{n}_annotation.yaml"

      ann_data = YAML.load(File.read(File.join(dir, a_dir, yfn)))
      ifn = File.join(dir, i_dir, ann_data['filename'])
      im = Vips::Image.new_from_file ifn
      ann_im = Vips::Image.new_from_file fn
      
      #store size of plant in relation to the image 
      size = im.size

      ann_data['annotation'].each do |ann_item|
        points = ann_item['points']
        next unless points['x'].is_a? Array #some annotations only contain a single number
        plant_type = ann_item['type']

        mask, crop_params = extract_polygone(points, im)
        cim = im.crop(*crop_params)
        csize = cim.size
        width_ratio = size.first / csize.first
        cann_im = ann_im.crop(*crop_params)

        plant_mask = (((mask*cann_im != 0).bandor) == 255)/255

        (cim * plant_mask).bandjoin(plant_mask > 0).write_to_file(File.join(n_dir, "#{n.to_i}_#{idx}_#{plant_type}_#{width_ratio}.png"))
        idx += 1
      end
    end
  end
end

# im = Vips::Image.new_from_file './test/001_annotation.png'

# f_points = YAML.load(File.read('./test/001_annotation.yaml'))
# points = f_points['annotation'].map{|x| x['points']}
# p points

# points.map{|x| ts.}.each_with_index{|ri, i| p ri; ri[0].write_to_file "#{i}_m.png"; ri[1].write_to_file "#{i}_orig.png"}

#Test code:
# require_relative 'seperate_plants.rb'

if __FILE__ == $0
  require 'optparse'
  options = {}
  op = OptionParser.new do |opts|
    opts.banner = "Dataset Separator by Polygon Annotation Info"
    opts.on("-dV", "--dir=V", "Path to a directory containing 'images' and 'annotations' directory.")
  end
  op.parse!(into: options)
  options.empty? && !puts(op) && return
  s = Seperator.new
  s.run_on_dir options[:dir]
end