namespace :update do
  desc "controls the running of parsing scripts that are intended to be run daily"

  task :rsync => :environment do
    begin
      wd = getwd
      cd "/data/govtrack/"
      system "sh update.sh"
      cd wd
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error rsyncing govtrack data!")
      throw e
    end
  end

  task :bios => :environment do
    begin
      load 'bin/daily/daily_parse_bioguide.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error updating from bioguide!")
      throw e
    end
  end
  
  task :video => :environment do
    begin
      load 'bin/daily/daily_parse_video.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error getting video data!")
      throw e
    end
  end

  task :people => :environment do
    begin
      data = IO.popen("sha1sum -c /tmp/people.sha1").read
      unless data.match(/OK\n$/)
        system "sha1sum /data/govtrack/#{DEFAULT_CONGRESS}/repstats/people.xml >/tmp/people.sha1"
        Person.transaction {
          load 'bin/daily/daily_parse_people.rb'
        }
      end
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing people!")
    end    
  end

  task :bills => :environment do
    begin
      Bill.transaction {
        load 'bin/daily/daily_parse_bills.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing bills!")
      throw e
    end
  end
  
  task :bill_text => :environment do
    begin
      load 'bin/daily/daily_parse_bill_text.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing bill text!")
      throw e
    end
  end
  
  task :get_watchdog_ids => :environment do
    load 'bin/get_watchdog_ids.rb'
  end
  
  task :sunlightlabs => :environment do
    load 'bin/get_sunlightlabs_data.rb'
  end
  
  task :gpo_billtext_timestamps => :environment do
    begin
      load 'bin/daily/daily_gpo_billtext_timestamps.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing GPO timestamps!")
      throw e
    end
  end

  task :amendments => :environment do
    begin
      Amendment.transaction {
        load 'bin/daily/daily_parse_amendments.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing amendments!")
      throw e
    end
  end

  task :committee_reports_parse => :environment do
    begin
      CommitteeReport.transaction {
        load 'bin/thomas_parse_committee_reports.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing committee reports!")
      throw e
    end
  end
  
  task :committee_reports => :environment do
    begin
      CommitteeReport.transaction {
        load 'bin/thomas_fetch_committee_reports.rb'
        load 'bin/thomas_parse_committee_reports.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing committee reports!")
      throw e
    end
  end

  task :open_secrets => :environment do
    begin
      Person.transaction {
        load 'bin/daily/daily_parse_opensecrets.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing open secrets!")
      throw e
    end
  end

  task :committee_schedule => :environment do
    begin
      CommitteeMeeting.transaction {
        load 'bin/govtrack_parse_committee_schedules.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing committee schedule!")
      throw e
    end    
  end

  task :today_in_congress => :environment do
    begin
      CongressSession.transaction {
        load 'bin/parse_today_in_congress.rb'
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing today in Congress!")
      throw e
    end
  end

  task :roll_calls => :environment do
    begin
      load 'bin/daily/daily_parse_rolls.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error parsing roll calls!")
      throw e
    end
  end

  task :person_voting_similarities => :environment do
    begin
      load 'bin/daily/person_voting_similarities.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error compiling voting similarities!")
      throw e
    end
  end
  
  task :sponsored_bill_stats => :environment do
    begin
      load 'bin/daily/sponsored_bill_stats.rb'
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error compiling sponsored bill stats!")
      throw e
    end
  end
    
  task :gossip => :environment do
    begin
      system "wget http://www.opencongress.org/news/?feed=atom -O /tmp/dev.atom"
      rss = SimpleRSS.new open("/tmp/dev.atom")
      Gossip.transaction {
        rss.entries.each do |e|
          g = Gossip.find_or_create_by_link(e[:link])
          attrs = g.attributes
          g.name = e[:author]
          g.email = "dev@opencongress.org"
          g.link = e[:link]
          g.tip = e[:content]
          g.title = e[:title]
          g.approved = true
          g.save unless g.attributes == attrs
        end
      }
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error running gossip!")
      throw e
    end
  end
  
  task :expire_cached_bill_fragments => :environment do
    begin
      require File.dirname(__FILE__) + '/../../app/models/bill.rb'
      require File.dirname(__FILE__) + '/../../app/models/fragment_cache_sweeper.rb'
    
      Bill.expire_meta_govtrack_fragments
    
      # TO DO: only invalidate updated bills
      bills = Bill.find(:all, :conditions => ["session = ?", DEFAULT_CONGRESS])
      bills.each do |b|
        b.send :expire_govtrack_fragments
      end
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error expiring cached bill fragments!")
      throw e
    end
  end
  
  task :expire_cached_person_fragments => :environment do
    begin
      require File.dirname(__FILE__) + '/../../app/models/person.rb'
      require File.dirname(__FILE__) + '/../../app/models/fragment_cache_sweeper.rb'
    
      # TO DO: only invalidate updated people
      people = Person.all_sitting
      people.each do |p|
        p.send :expire_govtrack_fragments
      end
    rescue Exception => e
      Emailer.deliver_rake_error(e, "Error expiring cached person fragments!")
      throw e
    end
  end
  
  # CRP data tasks 
  task :crp_interest_groups => :environment do
    begin
      load 'bin/crp/parse_interest_groups.rb'
    rescue Exception => e
      #Emailer.deliver_rake_error(e, "Error compiling voting similarities!")
      throw e
    end
  end
  
  task :maplight_bill_positions => :environment do
    begin
      load 'bin/crp/maplight_bill_positions.rb'
    rescue Exception => e
      #Emailer.deliver_rake_error(e, "Error compiling voting similarities!")
      throw e
    end
  end
  
  task :all => [:rsync, :people, :bills, :amendments, :roll_calls, :committee_reports, :committee_schedule, :open_secrets, :person_voting_similarities, :sponsored_bill_stats, :expire_cached_bill_fragments, :expire_cached_person_fragments]
  task :parse_all => [ :people, :bills, :amendments, :roll_calls, :committee_reports, :committee_schedule, :open_secrets]
  task :govtrack => [ :rsync, :people, :bills, :amendments, :roll_calls, :expire_cached_bill_fragments, :expire_cached_person_fragments]
  task :committee_info => [:committee_reports, :committee_schedule]
  task :people_meta_data => [:person_voting_similarities, :sponsored_bill_stats, :expire_cached_person_fragments]
end
