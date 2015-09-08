require 'rubygems'
require 'bundler/setup'
require 'mechanize'
require 'csv'
require 'nokogiri'
require 'pry'

class Scraper
  attr_reader :page, :results

  def initialize

    @agent = Mechanize.new

    # add rate limit of 500ms between requests
    @agent.history_added = Proc.new { sleep 0.5 }

  end

  def scrap

    # skip form, go directly to results
    @page = @agent.get("https://www.dice.com/jobs?q=web+developers&l=Roslyn%2C+NY")

    # all results contain necessary information under one class
    @results = @page.search(".//div[@class='serp-result-content']")

    # build final results
    jobs = build_jobs(@results)

    # save to CSV file
    save_results(jobs)

  end

  def build_jobs(search_results)

    jobs = []
    search_results.each do |job|

      job_title = job.at_css('h3 a').text.strip
      company_name = job.at_css('li a').text.strip
      post_link = job.at_css('h3 a').attribute('href').value
      location = job.at_css('li.location').text
      post_date = job.at_css('li.posted').text

      # capture every instance of characters in between '/' and '/'.  only returns the last value which is the company ID
      company_ID = job.at_css('h3 a').attribute('href').value.scan(/([^\/]*)\//)[-1]

      # capture all values before the first question mark
      job_ID = job.at_css('h3 a').attribute('href').value.match(/([^\/]*)\?/)[1]

      jobs << [job_title, company_name, post_link, location, post_date, company_ID, job_ID]

    end

    jobs

  end

  def save_results(jobs)

    CSV.open('dice_job_directory.csv', 'a') do |csv|
      jobs.each do |job|
        csv << job
      end
    end

  end

end

test = Scraper.new
test.scrap