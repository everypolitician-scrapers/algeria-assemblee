#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
  # Nokogiri::HTML(open(url).read, nil, 'utf-8')
end

def scrape_page(url)
  noko = noko_for(url)
  puts url.to_s.yellow

  noko.css('div.listing-summary').each do |div|
    data = {
      # do -not- use .split("/").last on id: URL structure varies for national
      # MPs and for those representing overseas constituencies
      id: div.css('h3 a/@href').text,
      name: div.css('h3').text.tidy,
      type: div.css('.category a').text,
      party: div.css('#field_31 span:nth-child(2)').text,
      constituency: div.css('.fields .row0:nth-child(2) span:nth-child(2)').text.tidy,
      image: div.css('img/@src').text,
      term: 7,
    }
    # TODO: activate ScraperWiki call
    puts data
    # ScraperWiki.save_sqlite([:id, :term], data)
  end
  return noko
end

init = scrape_page('http://www.apn.dz/fr/les-membres?searchcondition=2&cat_id=83&cf31=&cf36=&cf38=&cf40=&Itemid=715&option=com_mtree&task=listall&sort=link_name')

# find last results page (currently 23)
last = init.css('.pagination-list a/@href').last.text
last = last.gsub(/(.*)page(\d+)(.*)/, '\\2').to_i

# paginate through (omitting page 1)
for i in (2..last).to_a
  p = "http://www.apn.dz/fr/les-membres/all/page" + i.to_s + "?searchcondition=2&sort=link_name"
  scrape_page(p)
end
