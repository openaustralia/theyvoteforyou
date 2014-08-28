module DataLoader
  class Offices
    # ministers.xml
    def self.load!
      Rails.logger.info "Reloading offices..."
      ministers_xml = Nokogiri.parse(File.read("#{Settings.xml_data_directory}/members/ministers.xml"))
      ministers_xml.search(:moffice).each do |moffice|
        person = People.member_to_person[moffice[:matchid]]
        raise "MP #{moffice[:name]} has no person" unless person

        # FIXME: Don't truncate position https://github.com/openaustralia/publicwhip/issues/278
        position = moffice[:position]
        if position.size > 100
          Rails.logger.warn "Truncating position \"#{position}\""
          position.slice! 100..-1
        end

        responsibility = moffice[:responsibility] || ''

        o = Office.find_or_initialize_by(moffice_id: moffice[:id][/uk.org.publicwhip\/moffice\/(\d*)/, 1],
          person: person[/uk.org.publicwhip\/person\/(\d*)/, 1])
        o.update!(dept: XML.escape_html(moffice[:dept]),
          position: XML.escape_html(position),
          responsibility: XML.escape_html(responsibility),
          from_date: moffice[:fromdate],
          to_date: moffice[:todate])
      end
      Rails.logger.info "Loaded #{Office.count} offices"
    end
  end
end
