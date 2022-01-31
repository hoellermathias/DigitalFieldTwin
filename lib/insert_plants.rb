require 'vips'

def test_recombine im, pl, type=nil, annotation=nil
   size = im.size.zip(pl.size).map{|a,b| (a-b)*rand} 
   #draw segmentation mask for created field
   annotation ||= Vips::Image.black(*im.size)
   if type
    c = type != 'weed' ? [0,255,0,1] : [255,0,0,1]
    annotation_plant = (pl[3]>100) * c
   end
   [im.composite(pl, 'over', x: size.first, y:size.last), annotation_plant && annotation.composite(annotation_plant, 'over', x: size.first, y:size.last)]
end

def run_the_test_for pdir, gimn
  imn = Dir.glob(File.join(pdir, '*'))
  gim = Vips::Image.new_from_file gimn
  Dir.mkdir(File.join(pdir, '..', 'test_results'))
  imn.each_with_index do |pn, idx|
    pim = Vips::Image.new_from_file pn
    test_recombine(gim, pim).write_to_file(File.join(pdir, '..', 'test_results',"#{idx}_test_composite.png"))
  end
end

#require_relative '/home/mathias/uni/master_proposal/data/analysis/split_annotation/test_insert_plants.rb'
#run_the_test_for '/home/mathias/uni/master_proposal/data/datasets/dataset/plants/', '/home/mathias/uni/master_proposal/data/datasets/dataset/images/019_image.png'


