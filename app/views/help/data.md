<% content_for :title, "API - Get the data" %>

# <%= yield :title %>

With modest developer skills you can use the modern REST API to access almost all the information available
on <%= Settings.project_name %>.

All endpoints return their results as JSON.

Jump to the section you're most interested in

* [All current people in parliament](#people)
* [Details for a person](#person)
* [All policies](#policies)
* [Details for a policy](#policy)
* [Legacy API](#legacy)

<h2 id="people">All current people in parliament</h2>
<%= render "help/data/people" %>

<h2 id="person">Details for a person</h2>
<%= render "help/data/person" %>

<h2 id="policies">All policies</h2>
<%= render "help/data/policies" %>

<h2 id="policy">Details for a policy</h2>
<%= render "help/data/policy" %>

<h2 id="legacy">Legacy API</h2>
<%= render "help/data/legacy" %>
