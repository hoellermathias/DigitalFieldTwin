#!/usr/bin/ruby

require 'sqlite3'

class DB 
  def initialize path
    @db = SQLite3::Database.open path
    @db.execute "PRAGMA foreign_keys = ON;"
    @db.execute "CREATE TABLE IF NOT EXISTS species(Id INTEGER PRIMARY KEY AUTOINCREMENT, 
                                                Species TEXT)"
    @db.execute "CREATE TABLE IF NOT EXISTS plants(Id INTEGER PRIMARY KEY AUTOINCREMENT, 
                                                Species INTEGER,   
                                                Diameter INTEGER,
                                                AgeDays INTEGER,
                                                Notes TEXT,
                                                ImageID TEXT,
                                                Good INTEGER,
                                                Timestamp TEXT,
                                                FOREIGN KEY(Species) REFERENCES species(Id))"

    @db.execute "CREATE TABLE IF NOT EXISTS ground(Id INTEGER PRIMARY KEY AUTOINCREMENT, 
                                                PixelPerCM INTEGER,
                                                ImageID TEXT,
                                                Notes TEXT,
                                                Timestamp TEXT)"
  end
  def add_species (species)
    @db.execute "INSERT INTO species VALUES(null, '#{species}')"
  end
  def add_plant (species, diameter, age, notes, image_url, good)
    @db.execute "INSERT INTO plants VALUES(null,'#{species}',#{diameter},#{age},'#{notes}','#{image_url}', '#{good && 1 || 0}', CURRENT_TIMESTAMP)"
  end
  def add_ground (ppc, notes, imid)
    @db.execute "INSERT INTO ground VALUES(null,#{ppc},'#{imid}','#{notes}', CURRENT_TIMESTAMP)"
  end
  def get_all_species
    @db.execute('select * from species')
  end
  def get_plants_with(species:nil, timestr:nil, age_min:0, age_max:1000, notes:nil)
    stmt = %{SELECT * from plants JOIN species AS S on plants.Species = S.Id
      WHERE #{species && 'S.Species = \''+species+'\' and ' || ''}
        Timestamp like '#{timestr || ''}%' 
        and Good = 1
        and Notes like '%#{notes || ''}%' 
        and AgeDays BETWEEN #{age_min || 0} and #{age_max|| 1000};}
    prep = @db.prepare(stmt)
    rs = prep.execute
    rs.reduce([rs.columns]) {|sum, a| sum << a}
  end
  def get_ground_with(notes:nil)
    stmt = %{SELECT * from ground WHERE  
             Notes like '%#{notes || ''}%';}
    prep = @db.prepare(stmt)
    rs = prep.execute
    rs.reduce([rs.columns]) {|sum, a| sum << a}
  end
  def get_rand_ground_with(notes:nil)
    stmt = %{SELECT * from ground WHERE  
             Notes like '%#{notes || ''}%'
             ORDER BY RANDOM() LIMIT 1;}
    prep = @db.prepare(stmt)
    rs = prep.execute
    rs.reduce([rs.columns]) {|sum, a| sum << a}
  end
  def get_random_plant_with(species:nil, timestr:nil, age_min:0, age_max:1000, notes:nil)
    stmt = %{SELECT * from plants JOIN species AS S on plants.Species = S.Id
      WHERE #{species && 'S.Species = \''+species+'\' and ' || ''}
        Timestamp like '#{timestr || ''}%' 
        and Good = 1
        and Notes like '%#{notes || ''}%' 
        and AgeDays BETWEEN #{age_min || 0} and #{age_max|| 1000}
        ORDER BY RANDOM() LIMIT 1;}
    prep = @db.prepare(stmt)
    rs = prep.execute
    rs.reduce([rs.columns]) {|sum, a| sum << a}
  end
  def close
    @db.close
  end
end
