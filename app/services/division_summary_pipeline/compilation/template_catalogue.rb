# frozen_string_literal: true

module DivisionSummaryPipeline
  # Everything the pipeline knows about each template apart from its wording, which
  # lives in templates/. The prompt's catalogue, the facts each template needs, whether it
  # quotes the mover's explanation, and the name a draft's title uses all come from here, so
  # they cannot drift apart the way four separate copies of them once did.
  #
  # - name: the catalogue name (ARCHITECTURE.md section 8)
  # - title: the procedure as a draft title names it (DraftTitle)
  # - moved: what the mover moved, for "Senator Example moved the following amendment:"
  # - explains: whether the summary quotes the mover's explanation. Closure, the gag, suspending a
  #   member and adjournment decide only procedure, so there is nothing to explain.
  # - facts: the one or two things the summary names that only the motion's words can supply,
  #   each with the description the model is given
  # - requires: which of those facts must be found for the summary to be written at all; an
  #   array of alternatives means any one of them will do
  # - prompt: the line the model sees in the catalogue
  class TemplateCatalogue
    Entry = Data.define(:id, :name, :title, :moved, :explains, :facts, :requires, :prompt)

    TARGET_FACTS = {
      target_name: "who the motion is directed at, in the words the motion uses",
      target_electorate: "the electorate of the member it is directed at (\"Dickson\" from \"the honourable " \
                         "member for Dickson\")"
    }.freeze

    ENTRIES = [
      [1, "First Reading", "First Reading", "motion", true, {}, [], "First Reading"],
      [2, "Second Reading Amendment", "Second Reading Amendment", "amendment", true, {}, [],
       "Second Reading Amendment (e.g. \"That all words after 'That' be omitted with a view to substituting...\")"],
      [3, "In Committee Amendment (Senate)", "In Committee Amendment", "amendment", true, {}, [],
       "In Committee Amendment (Senate)"],
      [4, "Consideration in Detail (House of Representatives)", "Consideration in Detail Amendment", "amendment", true,
       {}, [], "Consideration in Detail (House of Representatives)"],
      [5, "Federation Chamber Report", "Federation Chamber Report", "motion", true, {}, [],
       "Report from Federation Chamber"],
      [6, "Third Reading", "Third Reading", "motion", true, {}, [],
       "Third Reading (the question that the bill be now read a third time, its final vote in this chamber)"],
      [7, "Consideration of a Message", "Consideration of a Message", "motion", true, {}, [],
       "Agreeing to Amendments / Consideration of a Message"],
      [8, "Order for the Production of Documents", "Production of Documents", "motion", true, {}, [],
       "Order for the Production of Documents"],
      [9, "Disallowance Motion", "Disallowance Motion", "motion", true,
       { regulation_name: "the legislative instrument the motion would disallow" }, [:regulation_name],
       "Disallowance Motion"],
      [10, "Censure Motion", "Censure Motion", "motion", true, TARGET_FACTS, [:target_name],
       "Censure Motion (including no confidence and want of confidence)"],
      [11, "Budget Estimates Committees", "Budget Estimates Committees", "motion", true, {}, [],
       "Budget Estimates Committees"],
      [12, "Establishing a Select Committee", "Establishing a Select Committee", "motion", true, {}, [],
       "Establishing a Select Committee"],
      [13, "Committee Referral", "Committee Referral", "motion", true,
       { committee_name: "the committee the matter is referred to" }, [:committee_name], "Committee Referral"],
      [14, "Selection of Bills Committee Report", "Selection of Bills Committee Report", "motion", true, {}, [],
       "Selection of Bills Committee Report"],
      [15, "General Motion", "General Motion", "motion", true, {}, [], "General Motion"],
      [16, "Matter of Urgency (Senate)", "Matter of Urgency", "motion", true, {}, [], "Matter of Urgency (Senate)"],
      [17, "Suspension of Standing Orders", "Suspension of Standing Orders", "motion", true, {}, [],
       "Suspension of Standing Orders"],
      [18, "Limitation of Debate (Guillotine)", "Limitation of Debate", "motion", true, {}, [],
       "Limitation of Debate (Guillotine), including the House question \"That the bill be considered urgent\", " \
       "which brings the House's time limits for urgent bills into force"],
      [19, "Rearrangement of Business", "Rearrangement of Business", "motion", true,
       { rearrangement_description: "what the motion does to the business, in its operative words after " \
                                    "\"That\" (\"the debate be adjourned\")" },
       [:rearrangement_description],
       "Rearrangement of Business, including adjourning or postponing a debate (\"That the debate be adjourned\") " \
       "and setting when business will be considered (\"That the amendments be considered at the next sitting\")"],
      [20, "Withdrawal of Business", "Withdrawal of Business", "motion", true,
       { business_name: "the item withdrawn from the Notice Paper" }, [:business_name], "Withdrawal of Business"],
      [21, "Parliamentary Zone Capital Works", "Parliamentary Zone Works", "motion", true, {}, [],
       "Parliamentary Zone Proposed Works"],
      [22, "Closure of Debate", "Closure of Debate", "motion", false, {}, [],
       "Closure of Debate (\"That the question be now put\"), and the two related closures: \"That the business " \
       "of the day be called on\", which ends a discussion on a matter of public importance, and \"That the " \
       "ballot be taken now\" during the election of a Speaker"],
      [23, "Member Be No Longer Heard (House of Representatives)", "Member Be No Longer Heard", "motion", false,
       TARGET_FACTS, [%i[target_name target_electorate]], "Member Be No Longer Heard (House of Representatives)"],
      [24, "Suspension of a Member", "Suspension of a Member", "motion", false, TARGET_FACTS,
       [%i[target_name target_electorate]], "Suspension of a Member"],
      [25, "Dissent from Ruling of the Chair", "Dissent from Ruling", "motion", true, {}, [],
       "Dissent from Ruling of the Chair"],
      [26, "Adjournment of the Chamber", "Adjournment", "motion", false, {}, [],
       "Adjournment of the Chamber: only \"That the House (or Senate) do now adjourn\", which ends the sitting. " \
       "Adjourning a debate is Template 19, not 26."],
      [27, "Taking Note", "Taking Note", "motion", true, {}, [], "Taking Note"],
      [28, "Question That a Clause or Part Stand As Printed", "Stand As Printed", "amendment", true, {}, [],
       "Question That a Clause or Part Stand As Printed (Senate committee of the whole)"],
      # Numbered after the rest rather than beside Template 6, so no template already cited by
      # number (in KNOWN_ISSUES.md, the specs and saved model replies) had to be renumbered.
      [29, "Second Reading", "Second Reading", "motion", true, {}, [],
       "Second Reading (the question that the bill be now read a second time, on its main idea; an amendment " \
       "to that question is Template 2)"]
    ].to_h do |id, name, title, moved, explains, facts, requires, prompt|
      [id, Entry.new(id: id, name: name, title: title, moved: moved, explains: explains, facts: facts,
                     requires: requires, prompt: prompt)]
    end.freeze

    IDS = (1..ENTRIES.size)

    # The evidence a template exists for, in ExtractionPayload::MISSING_EVIDENCE's terms. When the
    # question settled one of these templates and the model then cannot find that evidence, the
    # route is the likelier fault, and reading the whole sitting day cannot fix it: at Senate
    # 18 August 2026 #4 a route settled on a select committee, both models said there was no
    # committee, and the retry found none either (KI-59).
    DEFINING_EVIDENCE = { 9 => "regulation", 10 => "target", 12 => "committee", 13 => "committee", 23 => "target",
                          24 => "target" }.freeze

    # Every fact any template names, with its description, for the schema the model is given.
    ALL_FACTS = ENTRIES.values.map(&:facts).reduce({}, :merge).freeze

    def self.fetch(id)
      ENTRIES.fetch(id.to_i)
    end

    def self.[](id)
      ENTRIES[id.to_i]
    end

    def self.valid?(id)
      ENTRIES.key?(id) && id.is_a?(Integer)
    end

    def self.entries
      ENTRIES.values
    end

    def self.defining_evidence(id)
      DEFINING_EVIDENCE[id.to_i]
    end
  end
end
