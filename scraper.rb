#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_page(gender, url)
  noko = noko_for(url)
  puts url.to_s

  noko.css('div.listing-summary').each do |div|
    area_field = div.css('#field_36').empty? ? 40 : 36
    wilaya_id, wilaya = div.css("#field_#{area_field} .output").text.split(/-\s+/, 2)
    area_id = if area_field == 36
                'ocd-division/country:dz/wilayah:%d' % wilaya_id
              else
                'ocd-division/country:dz/zone:%s' % wilaya_id[/-(\d+)/, 1]
              end

    data = {
      id:      div.attr('data-link-id'),
      name:    div.css('h3').text.tidy,
      type:    div.css('.category a').text,
      party:   div.css('#field_31 span:nth-child(2)').text,
      area_id: area_id,
      area:    wilaya,
      gender:  gender,
      image:   div.css('img/@src').text,
      term:    7,
      source:  URI.join(url, div.css('h3 a/@href').text).to_s,
    }
    ScraperWiki.save_sqlite(%i[id term], data)
  end
  next_page = noko.css('a[@title="Suivant"]/@href').text
  scrape_page(gender, URI.join(url, next_page)) unless next_page.to_s.empty?
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
GENDER = { 'Homme' => 'male', 'Femme' => 'female' }.freeze
GENDER.each do |fr, en|
  scrape_page(en, 'http://www.apn.dz/fr/les-membres?sort=link_name&task=listall&cf38=%s' % fr)
end
