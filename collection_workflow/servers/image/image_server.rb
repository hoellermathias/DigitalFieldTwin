#!/usr/bin/ruby
require 'sinatra'
require 'securerandom'
require_relative '/home/mathias/Uni/2020ws/master_proposal/data/analysis/crop_im.rb'

set :port, 2345
set :bind, '0.0.0.0'
Dir.mkdir 'images' unless Dir.exists? 'images'
Dir.mkdir 'masks' unless Dir.exists? 'masks'
Dir.mkdir 'images_ground' unless Dir.exists? 'images_ground'
Dir.mkdir 'croppedplants' unless Dir.exists? 'croppedplants'


options "*" do
  response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
  response.headers["Access-Control-Allow-Origin"] = "*"
  200
end

helpers do
  def crop_plant(fn, mfn, pfn)
    #calculate plant mask 
    im = Crop_image.new fn
    w=[-0.015931472997181118, -0.3315611013490525, 0.24868342258628218]
    b=-4.992750111484608
    ((im.split_lab[2] * w[2]/w[0]+im.split_lab[1] * w[1]/w[0]+ b/w[0]) <= im.split_lab[0]).write_to_file(mfn)
  
    im = Crop_image.new(fn, '.', mfn, scale=1).get_plant_im#.gaussblur 1 #.lab.sharpen#
    crop_params = im.gaussblur(im.size.first/150).find_trim(background: 0)
    cim = im.crop(*crop_params)
    cim.write_to_file(pfn)
  end
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

post '/plant/?' do
  tempfile = params[:file][:tempfile]
  puts tempfile.path.split('.').last

  #png = Base64.decode64(request.body.read['data:image/png;base64,'.length .. -1]) 
  #File.open(File.join('images', "#{id}.png"), 'wb') { |f| f.write(png) }
  #while File.exists?(File.join('images', "#{id}.png")) do id=SecureRandom.uuid end
  id = SecureRandom.uuid
  File.open(File.join('images', "#{id}.#{tempfile.path.split('.').last}"), 'wb') {|f| f.write tempfile.read }
  [200, id]
end

get '/plant/:id' do
  id = params[:id]
  fn = Dir.glob(File.join('images', "#{id}.*")).first
  puts "filename: #{fn}"
  return 404 unless fn
  mfn = File.join('masks', "#{id}.png")
  pfn = File.join('croppedplants', mfn.split('/').last)
  crop_plant(fn, mfn, pfn) unless File.exists?(mfn)
  send_file(pfn, :disposition => 'inline', :filename => 'image')
end

post '/plant/:id' do
  id = params[:id]
  fn = Dir.glob(File.join('images', "#{id}.*")).first
  puts "filename: #{fn}"
  return [404, "can't find image with this id"] unless fn
  mfn = File.join('masks', "#{id}.png")
  pfn = File.join('croppedplants', mfn.split('/').last)
  crop_plant(fn, mfn, pfn)
  return [201, "all good, image cropped and stored"]
end

post '/ground/?' do
  tempfile = params[:file][:tempfile]
  puts tempfile.path.split('.').last

  id = SecureRandom.uuid
  File.open(File.join('images_ground', "#{id}.#{tempfile.path.split('.').last}"), 'wb') {|f| f.write tempfile.read }
  [200, id]
end

get '/ground/:id' do
  id = params[:id]
  fn = Dir.glob(File.join('images_ground', "#{id}.*")).first
  puts "filename: #{fn}"
  return 404 unless fn
  send_file(fn, :disposition => 'inline', :filename => 'image')
end