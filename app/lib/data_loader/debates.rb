# frozen_string_literal: true

require "mechanize"

module DataLoader
  class Debates
    # from_date - Date to parse from (just specify this date if you only want one )
    # to_date - A single date
    def self.load!(from_date, to_date = nil)
      (from_date..(to_date || from_date)).each do |date|
        House.australian.each do |house|
          xml_document = fetch_xml_document(house, date)
          next unless xml_document

          existing_divisions = Division.where(date: date, house: house)

          debates = DebatesXml.new(xml_document, house)
          Rails.logger.info "No debates found in XML for #{house} on #{date}" if debates.divisions.empty?

          if existing_divisions && existing_divisions.count != debates.divisions.count
            Rails.logger.warn "Division reload mismatch! #{house} #{date}: #{existing_divisions.count} divisions in the database and #{debates.divisions.count} in the XML"
            Sentry::Metrics.count("data_load.divisions.mismatch", attributes: { house: house })
          end

          debates.divisions.each do |d|
            Rails.logger.info "Saving division: #{d.house} #{d.date} #{d.number}"
            Sentry.with_child_span(op: "task", description: "Save division #{d.house} #{d.date} #{d.number}") do |span|
              span&.set_data(:votes_count, d.votes.count)
              ActiveRecord::Base.transaction do
                bills = d.bills.map do |bill_hash|
                  bill = Bill.find_or_initialize_by(official_id: bill_hash[:id])
                  bill.update!(url: bill_hash[:url], title: bill_hash[:title])
                  bill
                end

                division = Division.find_or_initialize_by(date: d.date, number: d.number, house: d.house)
                division.update!(name: d.name,
                                 source_url: d.source_url,
                                 debate_url: d.debate_url,
                                 debate_gid: d.debate_gid,
                                 motion: d.motion,
                                 clock_time: d.clock_time,
                                 bills: bills)

                division.votes.delete_all(:delete_all)
                d.votes.each do |gid, vote|
                  member = Member.find_by(gid: gid)
                  raise "Couldn't find member by gid #{gid}" if member.nil?

                  Vote.create!(division: division, member: member, vote: vote[0], teller: vote[1])
                end

                # Build the caches the division pages read from before we commit, so
                # the division is never visible without them. Whips first - the
                # rebellion counts in DivisionInfo are derived from them.
                Whip.update_divisions!(division.id)
                DivisionInfo.update_divisions!(division.id)
              end
            end
            Sentry::Metrics.count("data_load.divisions.loaded", attributes: { house: house })
          end
        end
      end
    end

    # The ParlParse-format XML URL for one house's debates on one sitting day.
    def self.xml_url(house, date)
      "#{Rails.configuration.xml_data_base_url}scrapedxml/#{house}_debates/#{date}.xml"
    end

    # Fetches and parses one house's Hansard XML for one sitting day. Returns nil (after
    # logging) when the source has no XML for that day, which is the normal outcome for
    # weekends and other non-sitting days, not a failure.
    #
    # Also used by DivisionSummaryPipeline::ContextBuilder (app/services/division_summary_
    # pipeline/context_builder.rb) to fetch wider debate context for the AI division summary
    # feature, so this stays the one place that knows the source URL and fetch mechanics -
    # see app/services/division_summary_pipeline/ARCHITECTURE.md for why that matters.
    def self.fetch_xml_document(house, date)
      agent = Mechanize.new
      url = xml_url(house, date)
      Sentry.with_child_span(op: "http.client", description: "Fetch #{house} debates XML for #{date}") do |span|
        span&.set_data("http.url", url)
        Nokogiri::XML(agent.get(url).body)
      end
    rescue Mechanize::ResponseCodeError => e
      raise e if e.response_code != "404"

      Sentry::Metrics.count("data_load.divisions.xml_missing", attributes: { house: house })
      Rails.logger.info "No XML file found for #{house} on #{date} at #{url}"
      nil
    end
  end
end
