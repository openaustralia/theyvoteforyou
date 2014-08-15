require 'happymapper'

module XMLMappings
  class Divisions
    include HappyMapper

    tag 'division'
    attribute :id, String
    attribute :fromdate, Date
    attribute :todate, Date

    def cons_id
      id[/uk.org.publicwhip\/cons\/(\d*)/, 1]
    end

    # TODO: Support multiple electorate names
    has_one :name, String, xpath: 'name/@text'
    def main_name
      true
    end

    # TODO: Support Scottish parliament
    def house
      'commons'
    end

    def to_h
      {cons_id: cons_id,
       name: name,
       main_name: main_name,
       from_date: fromdate,
       to_date: todate,
       house: house}
    end
  end
end
