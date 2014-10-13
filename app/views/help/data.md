<% content_for :title, "API - Get the data" %>

# <%= yield :title %>

With modest developer skills you can use the modern REST API to access almost all the information available
on <%= Settings.project_name %>.

All endpoints return their results as JSON.

## All current people in parliament

<pre>GET <%= link_to api_v1_people_url(format: "json"), api_v1_people_url(format: "json") %></pre>

This returns basic information about each person who is currently a member of parliament. It
includes their name, electorate, party and whether they are in the House of Representatives or the
Senate.

To get more detailed information about a person use the `id` to do the following:

## Details for one person

<pre>GET <%= api_v1_person_url(format: "json", id: "foo").gsub("foo", "[id]") %></pre>

For example

<pre>GET <%= link_to api_v1_person_url(format: "json", id: 10001), api_v1_person_url(format: "json", id: 10001) %></pre>

This returns all sorts of useful detailed information, including

<table class="table">
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>rebellions</code></td>
      <td>The number of times they have rebelled against their party</td>
    </tr>
    <tr>
      <td><code>votes_attended</code></td>
      <td>The number of divisions in which they have voted</td>
    </tr>
    <tr>
      <td><code>votes_possible</code></td>
      <td>The number of possible divisions they could have voted in</td>
    </tr>
    <tr>
      <td><code>offices</code></td>
      <td>An array of current ministerial (or shadow ministerial) positions</td>
    </tr>
    <tr>
      <td><code>policy_comparisons</code></td>
      <td>An array of policies that this person could have voted on and their calculated <code>agreement</code>
      score in range from 0 to 100. <code>voted</code> says whether they ever vote on a division from this policy.</td>
    </tr>
  </tbody>
</table>

## Legacy API

We also maintain a legacy XML API which is used by [OpenAustralia.org](http://www.openaustralia.org) to
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

Hey, you should [help document this better](https://github.com/openaustralia/publicwhip/blob/test/app/views/help/data.md)!
