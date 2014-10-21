<% if current_user %>
<pre>GET <%= api_v1_person_url(format: "json", id: "foo", key: current_user.api_key).gsub("foo", "[id]") %></pre>
<% else %>
<pre>GET <%= api_v1_person_url(format: "json", id: "id2", key: "api_key2").gsub("id2", "[id]").gsub("api_key2", "[api_key]") %></pre>
<% end %>

<% if current_user %>
For example

<pre>GET <%= link_to api_v1_person_url(format: "json", id: 10001, key: current_user.api_key), api_v1_person_url(format: "json", id: 10001, key: current_user.api_key) %></pre>
<% end %>

This returns all sorts of useful detailed information, including

Parameter            | Description
-------------------- | -----------------------------------------------------------
`rebellions`         | The number of times they have rebelled against their party
`votes_attended`     | The number of divisions in which they have voted
`votes_possible`     | The number of possible divisions they could have voted in
`offices`            | An array of current ministerial (or shadow ministerial) positions
`policy_comparisons` | An array of policies that this person could have voted on and their calculated `agreement` score in range from 0 to 100. `voted` says whether they ever vote on a division from this policy.
