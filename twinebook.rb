#!/usr/bin/env ruby
require 'bundler'
Bundler.require
require 'erb'
require 'open3'
require 'sinatra'
require './lib/compiler'

post '/' do
  return 'No file selected' unless params[:story_file] &&
                        (tmpfile = params[:story_file][:tempfile]) &&
                        (filename = params[:story_file][:filename])
  story = Story.new(File.read(tmpfile), link_text: params[:link_text])
  ext = case params[:format]
    when 'pdf'
      content_type 'application/pdf'
      'pdf'
    else
      'html'
  end

  attachment "#{filename.gsub(/\.html?$/,'')}.#{ext}"
  story.output(format: ext, style: params[:style])
end
