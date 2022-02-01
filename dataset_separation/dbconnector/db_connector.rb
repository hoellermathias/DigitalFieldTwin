#!/usr/bin/ruby
require_relative '../../lib/db.rb'
require_relative '../../lib/crop_im.rb'
require 'fileutils'
require 'securerandom'
require 'vips'


def insert_plants_db opts
  plant_dir = opts[:dir_plants]
  dest_base_dir = opts[:dir_dest]
  Dir.mkdir dest_base_dir rescue nil
  px_per_mm = opts[:px_per_mm]
  notes = opts[:notes]
  age = opts[:age]
  crop = opts[:crop]
  db = DB.new File.join(opts[:path_db])
  species_name_id = db.get_all_species.reduce({}){|s, e| s[e[1]]=e[0]; s}
  Dir.glob(File.join(plant_dir, '*.png')).each do |fn_img|
    p fn_img
    uuid = SecureRandom.uuid
    species = fn_img.split('/').last.split('_')[-2]
    species = crop if species == 'crop'
    p species
    unless species_name_id&.dig(species)
      db.add_species(species) 
      species_name_id = db.get_all_species.reduce({}){|s, e| s[e[1]]=e[0]; s}
    end
    im = Crop_image.new(fn_img, '.', fn_img, scale=1).get_plant_im
    cm_width = im.width/px_per_mm.to_f * 0.1
    p cm_width
    dest_url = File.join(dest_base_dir, uuid)
    im.write_to_file(dest_url+'.png')
    db.add_plant(species_name_id[species], cm_width, age, notes, uuid, 1)
  end
end



if __FILE__ == $0
  require 'optparse'
  options = {}
  op = OptionParser.new do |opts|
    opts.banner = "Database Connector for Separated Dataset"
    opts.on("--dir_dest=V", "Path to the directory where the separated plant images that are linked in the database are stored.")
    opts.on("--dir_plants=V", "Path to the directory holding the separated plant images that should be inserted into the database.")
    opts.on("--path_db=V", "Path to the sqlite db file.")
    opts.on("--px_per_mm=V", "Pixel per mm in the images.")
    opts.on("--age=V", "Age of the plants in days.")
    opts.on("--notes=V", "Notes that will be stored with the plant entry in the db.")
    opts.on("--crop=V", "Name of the crop.")
  end
  op.parse!(into: options)
  pp options
  options.empty? && !puts(op) && return
  insert_plants_db options
end