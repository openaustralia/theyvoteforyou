<pre>GET <%= link_to api_v1_people_url(format: "json"), api_v1_people_url(format: "json") %></pre>

This returns basic information about each person who is currently a member of parliament. It
includes their name, electorate, party and whether they are in the House of Representatives or the
Senate.

To get more detailed information about a person use the `id` to do the following:
