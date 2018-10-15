
class Sprite
  attr_accessor :name, :path, :x, :y, :w, :h, :img, :mtime
end

class Sheet
  attr_accessor :img, :sprites, :w, :h, :sprites
  def initialize(w,h)
    @w = w
    @h = h
    @img = SDL2::Video::Surface.new w,h,32,SDL2::Pixels::SDL_PIXELFORMAT_RGBA8888
    @sprites = []
  end
  def add(sprite)
    @sprites << sprite
    sprite.img.blit @img, sprite.x, sprite.y
  end
  def save(name)
    @img.save name
  end
end

def run(srcdir,dstdir)
  name = File.basename(srcdir)
  prefix = File.dirname(srcdir) + "/"

  puts "source: #{srcdir}"
  puts "output: #{dstdir}"
  puts "name: #{name} (in #{prefix})"

  unless File.directory? srcdir
    puts "#{srcdir} directory not found"
    exit 1
  end

  sprites = Dir.glob("#{srcdir}/**/*.png").map{|f|
    sprite = Sprite.new
    sprite.path = File.expand_path(f)
    sprite.name = sprite.path.split(prefix)[-1]
    sprite.mtime = File.stat(sprite.path).mtime
    sprite.img = SDL2::Video::Surface::load sprite.path
    sprite.h = sprite.img.height
    sprite.w = sprite.img.width
    puts "#{sprite.name}, #{sprite.path}, #{sprite.h}x#{sprite.w}"
    sprite
  }.sort{|a,b|
    a.h <=> b.h
  }

  sheet = Sheet.new(4096,4096)
  sheets = [sheet]
  x=0
  y=0
  line_height=0
  sprites.each{|sprite|
    if sheet.w < x+sprite.w
      y += line_height
      x = 0
      line_height = sprite.h
    end

    if sheet.h < y+sprite.h
      puts "new sheet"
      sheet = Sheet.new(4096,4096)
      sheets << sheet
      x=0
      y=0
    end

    sprite.x = x
    sprite.y = y
    sheet.add sprite
    x += sprite.w
    if line_height < sprite.h
      line_height = sprite.h
    end
  }

  #
  # output
  #
  FileUtils.mkdir_p dstdir
  mapping = {}
  sheets.each.with_index{|sheet,i|
    img_name = "#{name}-#{i}.png"
    img_path = File.join(dstdir, img_name)
    sheet.save img_path
    puts "#{img_path} saved."
    mapping[img_name] = sheet.sprites.map{|s| [s.name, s.x, s.y, s.w, s.h] }
  }
  json_path = File.join(dstdir, "#{name}.json")
  msgpack_path = File.join(dstdir, "#{name}.msgpack")
  File.open(json_path,"wb"){|f| f.write mapping.to_json }
  puts "#{json_path} saved."
  File.open(msgpack_path,"wb"){|f| f.write mapping.to_msgpack }
  puts "#{msgpack_path} saved."
end

# ----

if ARGV.size < 2
  puts "usage: sheeter path/to/images/directory path/to/output/directory"
  exit
end
srcdir = ARGV[0]
outdir = ARGV[1]
run srcdir, outdir
