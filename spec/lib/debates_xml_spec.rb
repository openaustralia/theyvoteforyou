require 'spec_helper'

describe DebatesXML do
  describe Division do
    subject(:division) do
      file_path = File.expand_path('../../fixtures/2009-11-25.xml', __FILE__)
      DebatesXML::Parser.new(file_path, 'commons').divisions.first
    end

    it { expect(division.date).to eq('2009-11-25') }
    it { expect(division.number).to eq('1') }
    it { expect(division.house).to eq('commons') }
    it { expect(division.name).to eq('Social Security and Other Legislation Amendment (Income Support for Students) Bill 2009 [No. 2] &#8212; Second Reading') }
    it { expect(division.source_url).to eq('http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2009-11-25/0000') }
    it { expect(division.debate_url).to eq('http://parlinfo.aph.gov.au/parlInfo/search/display/display.w3p;query=Id:chamber/hansardr/2009-11-25/0000') }
    it { expect(division.source_gid).to eq('uk.org.publicwhip/debate/2009-11-25.110.1') }
    it { expect(division.debate_gid).to eq('uk.org.publicwhip/debate/2009-11-25.101.1') }
    it { expect(division.motion).to eq('<p pwmotiontext=\"moved\">That this bill be now read a second time.</p>\n\n<p pwmotiontext=\"moved\">That all words after “That” be omitted with a view to substituting the following words:“the House:<dl><dt>(1)</dt><dd>registers its dismay that this legislation cuts out the ‘gap year’ pathway to Independent Youth Allowance for students who must leave home to attend University, requiring that students instead find 30 hours employment per week for 18 months in order to gain Independent Youth Allowance;</dd><dt>(2)</dt><dd>registers its concern that this legislation will lead to the retrospective removal of access to Youth Allowance for a number of students who undertook a ‘gap year’ in 2009 on the basis of advice from Government officials, including teachers, careers advisers and Centrelink officials; and</dd><dt>(3)</dt><dd>urges the Government to:<dl><dt>(a)</dt><dd>offer further amendments that will remove all of the negative retrospective effects of this legislation; and</dd><dt>(b)</dt><dd>provide a reasonable pathway to gaining Independent Youth Allowance for those students who must leave home in order to participate in Higher Education.</dd></dl></dd></dl></p>\n\n<p pwmotiontext=\"moved\">That the words proposed to be omitted (<b>Mr Pyne’s</b> amendment) stand part of the question.</p>\n\n') }
    it { expect(division.clock_time).to eq('019:26:00') }
  end
end
