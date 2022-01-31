#!/usr/bin/ruby
require 'vips'
require 'set'

require_relative '../lib/insert_plants.rb'
require_relative '../lib/db.rb'

def weed_crop_ground_ratio(im)
  im_stat = im.stats.to_a.map{|x| x[2].first/65025} 
  px_crop = im_stat[2]
  px_weed = im_stat[1]
  px_all = im.size.reduce(:*)
  px_ground = px_all - px_crop - px_weed
  perc_crop = 100*px_crop/px_all
  perc_weed = 100*px_weed/px_all
  perc_ground = 100*px_ground/px_all
  [perc_weed, perc_crop, perc_ground]
end

def mean_without_alpha(im)
  imstats = im.stats.to_a
  count_px_plant = imstats.last[2].first/255
  imstats[1][2].first/count_px_plant
end

Dir.mkdir 'annotations' rescue nil
Dir.mkdir 'images' rescue nil

db = DB.new('/home/mathias/uni/master_proposal/code/db/test.db')
ground_dir = '/home/mathias/uni/master_proposal/code/images_ground'
plant_dir = '/home/mathias/uni/master_proposal/code/croppedplants'

color_change_factor = 0.3
uuids_crops = Set.new
uuids_weeds = Set.new
uuids_ground = Set.new
resize_end = 1.0 
cropped_size = (1/resize_end)*513
wcg_ratio = nil

#75
150.times do |ig|
  gid = db.get_rand_ground_with#(notes: 'boku sugar')
  pp gid
  im_fn = Dir.glob(File.join(ground_dir, gid.last[gid.first.index("ImageID")]+'.*')).first
  uuids_ground << gid.last[gid.first.index("ImageID")]
  name = ig.to_s
  gim = Vips::Image.new_from_file im_fn
  gim = gim.colourspace(:lab)
  gim = gim.flatten if gim.bands == 4
  #glavg = gim[0].avg
  #glstd = gim[0].deviate

  15.times do |ip|
    name = (ig*15+ip).to_s
    gf = rand + 0.5
    print "##{name}"
    annotation = nil
    l = rand * (gim.size.first - cropped_size)
    r = rand * (gim.size.last - cropped_size)
    cropped_gim = gim.extract_area(l,r,cropped_size,cropped_size)
                    .resize(resize_end, :interpolate => Vips::Interpolate.new('nearest')) 
    cropped_gim *= [gf,1,1]
    cropped_gim = cropped_gim.flip(:horizontal) if rand < 0.3
    cropped_gim = cropped_gim.flip(:vertical) if rand < 0.3
    glavg = cropped_gim[0].avg
    #glstd = cropped_gim[0].deviate
    #ropped_gim = cropped_gim.colourspace(:srgb)
    loop do
        print '.'
        cw_toggle = wcg_ratio && wcg_ratio[0] > wcg_ratio[1]
        sp_cat = (cw_toggle ? 'crop' : 'weed')
        sp = (cw_toggle ? 'sugar beet' : %w(unbekannt kornrade storchenschnabel wegrauke kornblume).sample)#["unbekannt", "hilfe", "klatschmohn", "kornrade", "storchenschnabel", "wegrauke", "kornblume", "Black-grass", "Charlock", "Cleavers", "Common Chickweed", "Fat Hen", "Loose Silky-bent", "Scentless Mayweed", "Shepherd’s Purse", "Small-flowered Cranesbill", "weed"].sample)#["weed", "Black-grass", "Charlock", "Cleavers", "Common Chickweed", "Fat Hen", "Loose Silky-bent", "Scentless Mayweed", "Shepherd’s Purse", "Small-flowered Cranesbill"].sample)
        
        pid = nil
        #loop do
          pid = db.get_random_plant_with(species: sp, notes: 'boku sugar', age_max: 35, age_min: 25)#sp == 'soy' ? ["boku ", 'Kallham'].sample :  nil)#, notes: sp == 'weed' || sp == 'soy' ? 'kallham' : nil)#timestr: sp_cat == 'crop' ? '2021-05-31' : nil,age_max: 20 ,notes: 'carrot field dbscan 0-50')##'bonn_160517')#, notes: 'segmentation dataset')#age_min: sp == 'weed' ? 998 : nil)#, notes: ['', '', 'kallham'].sample 
          #pp pid
          #p pid.last[pid.first.index("ImageID")]
        #  break if sp_cat == 'weed' || uuids_crops.size < 25 || uuids_crops.include?(pid.last[pid.first.index("ImageID")])
        #end
        unless sp_cat == 'weed'
          uuids_crops << pid.last[pid.first.index("ImageID")] 
        else
          uuids_weeds << pid.last[pid.first.index("ImageID")]
        end
        #pp uuids_crops
        p_fn = File.join(plant_dir, pid.last[pid.first.index("ImageID")]+'.png')
        f = 1#rand * 0.7 + 0.5
        pim = Vips::Image.new_from_file(p_fn)

        resize_factor = 1.0 * pim.size.first * gid.last[gid.first.index("PixelPerCM")]/((pid.last[pid.first.index("Diameter")] == 0 ? 10 : pid.last[pid.first.index("Diameter")]) * gim.size.first)
        resize_fend = resize_end*(rand* 0.4 + 0.8)/resize_factor 
        pim = pim.resize(resize_fend >= 0.05 && resize_fend || 0.05, :interpolate => Vips::Interpolate.new('nearest'))   
                .rotate(rand*360, :interpolate => Vips::Interpolate.new('nearest'))
        pim = pim.colourspace(:lab)
        pim_avg = mean_without_alpha(pim)
        #p pim_avg*1.0 /glavg *(rand*0.85+0.5)
        plim = pim[0] * glavg*1.0 /pim_avg *(rand*0.85+0.5)
        #pim.write_to_file("test_orig.jpg")
        #(plim > 100).ifthenelse(100, plim).bandjoin(pim[1..3]).write_to_file("test.jpg")
        cpim = (plim > 100).ifthenelse(100, plim).bandjoin(pim[1..3])
        cpim *= [1,f*(color_change_factor*rand+0.85),f*(color_change_factor*rand+0.85),1]
        cpim = cpim.flip(:horizontal) if rand < 0.3
        cpim = cpim.flip(:vertical) if rand < 0.3
        cropped_gim, annotation = test_recombine(cropped_gim, cpim.colourspace(:srgb), sp_cat == 'weed' ? 'weed' : 'crop', annotation)
        #cropped_gim.write_to_file("test_out.jpg")
        wcg_ratio = weed_crop_ground_ratio(annotation)
        #sleep 3
        begin
          #gaussbn = lambda {|image| image.gaussblur(0.2+rand*2) + Vips::Image.gaussnoise(image.size.first ,image.size.first, mean: 0, sigma: rand*4)}
          #gaussbn.call
          (cropped_gim).write_to_file("images/#{name}.jpg")
          annotation.write_to_file("annotations/#{name}.png")
          break
        end if wcg_ratio.last < 95
      end
  end
end
  
p 'finished first part: generated large images'
puts "crops: #{uuids_crops.size}, weeds: #{uuids_weeds.size}, grounds: #{uuids_ground.size}"
File.write('plants_crops_uuids.csv', "crops, #{uuids_crops.to_a.join(',')}\nweeds,#{uuids_weeds.to_a.join(',')}\nground,#{uuids_ground.to_a.join(',')}")
