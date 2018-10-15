#!/usr/bin/env ruby
require "fileutils"

if $0 == __FILE__
  REPOSITORY = "https://github.com/mruby/mruby.git"
  DIR = "build/macos"
  MRUBY_CONFIG = File.expand_path(__FILE__)
  FRAMEWORKS_PATH = "#{ENV['HOME']}/Library/Frameworks"

  FileUtils.mkdir_p "build"
  system "git clone -b 1.4.1 #{REPOSITORY} #{DIR}"

  system "cd #{DIR}; env FRAMEWORKS_PATH=#{FRAMEWORKS_PATH} MRUBY_CONFIG=#{MRUBY_CONFIG} ruby minirake -v all"

  FileUtils.mkdir_p "build/bin"
  `cp build/macos/build/host/bin/* build/bin`

  system "./build/bin/mrbc -B SHEETER -o src/sheeter.h src/main.rb"

  system "/usr/bin/gcc -Wall -Os -o build/bin/sheeter src/main.c -lmruby \
    -L #{DIR}/build/host/lib -I #{DIR}/include \
    -F #{FRAMEWORKS_PATH} -framework SDL2 -framework SDL2_image"

  system "otool -L build/bin/sheeter"

  exit
end

#
# for x86_64-apple-darwin
#
MRuby::Build.new do |conf|
  toolchain :gcc

  conf.gem github:'mruby-sdl2/mruby-sdl2' do |g|
    if ENV['FRAMEWORKS_PATH']
      g.cc.flags << "-F#{ENV['FRAMEWORKS_PATH']}"
      g.cc.include_paths << "#{ENV['FRAMEWORKS_PATH']}/SDL2.framework/Headers/"
    end
  end

  conf.gem github:'mruby-sdl2/mruby-sdl2-image' do |g|
    g.cc.flags << "-F#{ENV['FRAMEWORKS_PATH']}"
    g.cc.include_paths << "#{ENV['FRAMEWORKS_PATH']}/SDL2.framework/Headers/"
    g.cc.include_paths << "#{ENV['FRAMEWORKS_PATH']}/SDL2_image.framework/Headers/"
  end

  conf.gem github: 'iij/mruby-iijson'
  conf.gem github: 'iij/mruby-dir'
  conf.gem github: 'iij/mruby-regexp-pcre'
  conf.gem github: 'gromnitsky/mruby-dir-glob'
  conf.gem github: 'hfm/mruby-fileutils'
  conf.gem github: 'suzukaze/mruby-msgpack'
  conf.gem core: 'mruby-io'
  conf.gem core: 'mruby-exit'
  conf.gembox 'default'

  conf.cc do |cc|
    cc.command = ENV['CC'] || "gcc"
    cc.defines << 'MRB_UTF8_STRING'
    cc.defines << 'MRB_32BIT'
  end

  conf.linker do |linker|
    linker.command = ENV['CC'] || "gcc"
    if ENV['FRAMEWORKS_PATH']
      linker.flags << "-F#{ENV['FRAMEWORKS_PATH']}"
      linker.flags << "-framework SDL2"
      linker.flags << "-framework SDL2_image"
    end
  end
end
