We also maintain a legacy XML API which is used by [OpenAustralia.org](https://www.openaustralia.org.au) to
access policy information. We plan to phase this API out as soon as is practical. We strongly recommend
you use the modern REST API above for anything new.

### MP Attendance and Rebelliousness Rates XML

[mp-info.xml](<%= mp_info_feed_path(format: :xml) %>) - list of division
attendance rate and rebelliousness for all Representatives. This is a live
file, correct to the latest division in the database. The field `data_date`
shows the date it applies up to. For members who have left the house it says
"complete".

[mp-info.xml?house=senate](<%= mp_info_feed_path(format: :xml, house: :senate) %>) -
likewise for the Senate.

### MP Policy Agreement XML

Each [policy](<%= policies_path %>) has an XML representation of how much
each MP agrees with it, e.g. [mpdream-info.xml?id=1](<%= mpdream_info_feed_path(id: 1, format: :xml) %>).
